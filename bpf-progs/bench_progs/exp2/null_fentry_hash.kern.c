// SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
/* Experiment 2: Hash Map - Lookup + Update 
 * 
 */

#include <linux/bpf.h>
#include <linux/types.h>
#include <bpf/bpf_helpers.h>

#define MAX_ENTRIES 1000

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__type(key, __u32);
	__type(value, __u64);
	__uint(max_entries, MAX_ENTRIES);
} hash_map SEC(".maps");



SEC("fentry/__do_sys_bpfprof")
int hash_map_lookup_fentry(void *ctx) {
    __u32 key = 0;

    bpf_map_lookup_elem(&hash_map, &key);

    return 0;
}

SEC("fentry/__do_sys_bpfprof")
int hash_map_update_fentry(void *ctx) {
    __u32 key = 0;
    __u64 new_value = 1;

    bpf_map_update_elem(&hash_map, &key, &new_value, BPF_ANY);

    return 0;
}

SEC("fentry/__do_sys_bpfprof")
int hash_map_stress_lookup(void *ctx)
{
    __u32 key = 0, i;

	for (i = 0; i < 64; ++i)
		bpf_map_lookup_elem(&hash_map, &key);

	return 0;
}

/* This test must be executed after other tests */
SEC("fentry/__do_sys_bpfprof")
int hash_map_delete(void *ctx)
{
    __u32 key = 0;
    __u64 *value;

    value = bpf_map_lookup_elem(&hash_map, &key);
    if (value)
        bpf_map_delete_elem(&hash_map, &key);

    return 0;
}


char LICENSE[] SEC("license") = "Dual BSD/GPL";