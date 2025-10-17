#include <linux/bpf.h>
#include <linux/types.h>
#include <bpf/bpf_helpers.h>

// Array map for lookup benchmarking
struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 100);
    __type(key, __u32);
    __type(value, int);
} shared_data_map SEC(".maps");

SEC("fentry/__do_sys_bpfprof")
int trigger_syscall_prog(void *ctx) {
    // Lookup from the shared array map filled by array_filler.kern.c
    __u32 key = 5;  // Look up index 5 (should contain value 1005)
    int *value;
    
    // Lookup value in the shared array
    value = bpf_map_lookup_elem(&shared_data_map, &key);
    if (value) {
        // Found a value - access it to ensure the lookup completes
        volatile int temp = *value;
        (void)temp;  // Prevent compiler optimization
    }
    
    return 0;
}

char LISENSE[] SEC("license") = "Dual BSD/GPL";
