/*
 * execsnoop_pid.bpf.c
 *
 * Count exec events per PID and pin the map at /sys/fs/bpf/exec_count_map
 *
 * Compile:
 * clang -O2 -g -target bpf -c execsnoop_pid.bpf.c -o execsnoop_pid.bpf.o
 *
 * The map is a BPF_HASH with key pid (u32) and value struct { u64 cnt; char comm[16]; }.
 */
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <linux/sched.h>

struct pid_count {
    __u64 cnt;
    char comm[16];
};

struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 65536);
    __type(key, __u32);
    __type(value, struct pid_count);
} exec_count_map SEC(".maps");

SEC("tracepoint/sched/sched_process_exec")
int handle_exec(struct trace_event_raw_sched_process_exec *ctx)
{
    __u32 pid = bpf_get_current_pid_tgid() >> 32;
    struct pid_count zero = {};
    struct pid_count *entry;

    entry = bpf_map_lookup_elem(&exec_count_map, &pid);
    if (!entry) {
        zero.cnt = 1;
        bpf_get_current_comm(&zero.comm, sizeof(zero.comm));
        bpf_map_update_elem(&exec_count_map, &pid, &zero, BPF_ANY);
    } else {
        __sync_fetch_and_add(&entry->cnt, 1);
    }
    return 0;
}

char LICENSE[] SEC("license") = "GPL";
