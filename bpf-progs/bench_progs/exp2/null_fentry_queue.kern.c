// SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
/* Experiment 2: Queue Map - Push and Pop Operations
 * 
 * Tests BPF_MAP_TYPE_QUEUE 
 */

#include <linux/bpf.h>
#include <linux/types.h>
#include <bpf/bpf_helpers.h>

#define MAX_ENTRIES 1000

struct {
	__uint(type, BPF_MAP_TYPE_QUEUE);
	__type(value, __u64);
	__uint(max_entries, MAX_ENTRIES);
} queue_map SEC(".maps");

SEC("fentry/__do_sys_bpfprof")
int queue_map_push_fentry(void *ctx) {
    __u64 value = 42;  // Push a test value

    // Push (enqueue) operation - adds element to the back of queue
    bpf_map_push_elem(&queue_map, &value, BPF_EXIST);

    return 0;
}

SEC("fentry/__do_sys_bpfprof")
int queue_map_peek_fentry(void *ctx) {
    __u64 value;

    // Peek operation - reads front element without removing it
    bpf_map_peek_elem(&queue_map, &value);

    return 0;
}

SEC("fentry/__do_sys_bpfprof")
int queue_map_pop_fentry(void *ctx) {
    __u64 value;

    // Pop (dequeue) operation - removes element from the front of queue
    bpf_map_pop_elem(&queue_map, &value);

    return 0;
}

char LICENSE[] SEC("license") = "Dual BSD/GPL";