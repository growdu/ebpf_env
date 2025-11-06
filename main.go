package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "net/http"
    "os"
    "os/signal"
    "sort"
    "syscall"
    "time"

    "github.com/cilium/ebpf"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    bpfObjPath = flag.String("bpf-object", "../../bpf/execsnoop_pid.bpf.o", "path to BPF object (.o)")
    listenAddr = flag.String("listen", ":9100", "listen address")
    interval   = flag.Duration("interval", 3*time.Second, "read interval")
    topn       = flag.Int("topn", 10, "top N processes to export")
)

type pidCount struct {
    PID  uint32
    Comm string
    Cnt  uint64
}

func main() {
    flag.Parse()

    spec, err := ebpf.LoadCollectionSpec(*bpfObjPath)
    if err != nil {
        log.Fatalf("LoadCollectionSpec: %v", err)
    }

    coll, err := ebpf.NewCollection(spec)
    if err != nil {
        log.Fatalf("NewCollection: %v", err)
    }
    defer coll.Close()

    m, ok := coll.Maps["exec_count_map"]
    if !ok {
        log.Fatalf("map exec_count_map not found")
    }

    // Prometheus gauge vector
    gauge := prometheus.NewGaugeVec(prometheus.GaugeOpts{
        Name: "ebpf_exec_total",
        Help: "Number of exec syscalls per pid",
    }, []string{"pid", "comm"})
    prometheus.MustRegister(gauge)

    ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer stop()

    go func() {
        ticker := time.NewTicker(*interval)
        defer ticker.Stop()
        for {
            select {
            case <-ticker.C:
                // iterate map
                it := m.Iterate()
                var k uint32
                var v struct {
                    Cnt  uint64
                    Comm [16]byte
                }
                var arr []pidCount
                for it.Next(&k, &v) {
                    // convert comm
                    comm := string(v.Comm[:])
                    // trim at first zero
                    if i := indexByte(v.Comm[:], 0); i >= 0 {
                        comm = string(v.Comm[:i])
                    }
                    arr = append(arr, pidCount{PID: k, Comm: comm, Cnt: v.Cnt})
                }
                if it.Err() != nil {
                    log.Printf("map iterate err: %v", it.Err())
                    continue
                }

                // sort by count desc
                sort.Slice(arr, func(i, j int) bool { return arr[i].Cnt > arr[j].Cnt })
                // reset gauges by clearing others (Prometheus client doesn't provide delete for GaugeVec easily)
                gauge.Reset()
                n := *topn
                if n > len(arr) {
                    n = len(arr)
                }
                for i := 0; i < n; i++ {
                    g := arr[i]
                    gauge.WithLabelValues(fmt.Sprintf("%d", g.PID), g.Comm).Set(float64(g.Cnt))
                }
            case <-ctx.Done():
                return
            }
        }
    }()

    http.Handle("/metrics", promhttp.Handler())
    srv := &http.Server{Addr: *listenAddr}
    go func() {
        log.Printf("metrics server listen %s", *listenAddr)
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("ListenAndServe: %v", err)
        }
    }()

    <-ctx.Done()
    log.Println("shutting down")
    _ = srv.Shutdown(context.Background())
}

// helper: find first zero byte index
func indexByte(b []byte, c byte) int {
    for i, v := range b {
        if v == c {
            return i
        }
    }
    return -1
}
