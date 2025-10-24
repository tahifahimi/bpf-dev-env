// SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
/* Experiment 2: Array Map - Lookup + Update 
 * 
 */

#include <linux/bpf.h>
#include <linux/types.h>
#include <bpf/bpf_helpers.h>

#define MAX_ENTRIES 1000
#define MAX_NR_CPUS 1024

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__type(key, __u32);
	__type(value, __u64);
	__uint(max_entries, MAX_ENTRIES);
} array_map SEC(".maps");


SEC("fentry/__do_sys_bpfprof")
int array_map_lookup_fentry(void *ctx) {
    __u32 key = 0;
    long *value;
    
    value = bpf_map_lookup_elem(&array_map, &key);
    
    return 0;
}

SEC("fentry/__do_sys_bpfprof")
int array_map_update_fentry(void *ctx) {
    __u32 key = 0;
    long new_value = 1;

    bpf_map_update_elem(&array_map, &key, &new_value, BPF_ANY);

    return 0;
}

SEC("fentry/__do_sys_bpfprof")
int array_map_stress_lookup(void *ctx)
{
    __u32 key = 1, i;
    long *value;

#pragma clang loop unroll(full)
	for (i = 0; i < 64; ++i)
		value = bpf_map_lookup_elem(&array_map, &key);

	return 0;
}

char LICENSE[] SEC("license") = "Dual BSD/GPL";