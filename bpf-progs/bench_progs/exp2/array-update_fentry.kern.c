#include <linux/bpf.h>
#include <linux/types.h>
#include <bpf/bpf_helpers.h>

// Reference to the shared array map (will be shared via userspace)
struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 100);
    __type(key, __u32);
    __type(value, int);
} shared_data_map SEC(".maps");

SEC("fentry/__do_sys_bpfprof")
int trigger_syscall_prog(void *ctx) {
    // Update array elements to benchmark update performance
    __u32 key = 5;  // Update index 5
    int new_value = 2000 + key;  // New value to store
    
    bpf_map_update_elem(&shared_data_map, &key, &new_value, BPF_ANY);
    
    return 0;
}

char LISENSE[] SEC("license") = "Dual BSD/GPL";
