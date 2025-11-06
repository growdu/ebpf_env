# eBPF Development Environment (CentOS 8) + Prometheus + Grafana (Full Pack)

This repository provides a self-contained development environment for eBPF:
- CentOS 8 based Docker image with clang/libbpf/Go/Python toolchain
- Docker Compose to run the dev container + Prometheus + Grafana
- Sample eBPF program (per-PID exec counter with pinning)
- Go loader (reads BPF map, exports Prometheus metrics as `ebpf_exec_total{pid,comm}`)
- Grafana dashboard (Top-N table + timeseries)
- GitHub Actions CI to test builds

## Quick start

1. Build and run:
```bash
docker compose up --build -d
```

2. Enter the dev container:
```bash
docker exec -it ebpf-dev /bin/bash
```

3. Compile the BPF program:
```bash
cd workdir/bpf
clang -O2 -g -target bpf -c execsnoop_pid.bpf.c -o execsnoop_pid.bpf.o
```

4. Run the Go loader:
```bash
cd /home/dev/workdir/loader/cmd/ebpf_exporter
go build -o /home/dev/bin/ebpf_exporter
/home/dev/bin/ebpf_exporter --bpf-object ../../bpf/execsnoop_pid.bpf.o --listen :9100 --topn 10
```

5. Open:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

## Notes / Requirements

- Host kernel must support eBPF. Kernel 5.x+ recommended.
- Mounting `/lib/modules` and `/sys/fs/bpf` is recommended for CO-RE and pinning.
- The compose uses capability-based approach (recommended). If you face permission issues, temporarily set `privileged: true` for the ebpf-dev service to debug.

## Files

- Dockerfile
- docker-compose.yml
- prometheus.yml
- grafana/dashboard.json
- bpf/execsnoop_pid.bpf.c
- loader/cmd/ebpf_exporter/* (Go loader)
- .github/workflows/ci.yml
