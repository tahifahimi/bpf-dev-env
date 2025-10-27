// SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
/* Experiment 2: Ring Buffer
 * 
 * We test bpf_ringbuf_output, bpf_ringbuf_reserve, and bpf_ringbuf_submit functions.
 */
#include <linux/bpf.h>
#include <linux/types.h>
#include <bpf/bpf_helpers.h>

struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF);
    __uint(max_entries, 256 * 1024); // 256 KB ring buffer
} test_ringbuf SEC(".maps");

const char test_message[] = "hello!";


SEC("fentry/__do_sys_bpfprof")
int ringbuf_map_reserve_fentry(void *ctx) {
    char *data;
    
    data = bpf_ringbuf_reserve(&test_ringbuf, sizeof(test_message), 0);
    if (!data) {
        return 0;
    }
    
    bpf_ringbuf_discard(data, 0);
    
    return 0;
}

SEC("fentry/__do_sys_bpfprof")
int ringbuf_map_submit_fentry(void *ctx) {
    char *data;

    data = bpf_ringbuf_reserve(&test_ringbuf, sizeof(test_message), 0);
    if (!data) {
        return 0;
    }

    __builtin_memcpy(data, test_message, sizeof(test_message));
    bpf_ringbuf_submit(data, 0);

    return 0;
}

SEC("fentry/__do_sys_bpfprof")
int ringbuf_output_fentry(void *ctx) {

    bpf_ringbuf_output(&test_ringbuf, test_message, sizeof(test_message), 0);

    return 0;
}

/* reserve, write and submit data */
SEC("fentry/__do_sys_bpfprof")
int ringbuf_dynptr_submit_fentry(void *ctx) {
    struct bpf_dynptr ptr;
    
    if (bpf_ringbuf_reserve_dynptr(&test_ringbuf, sizeof(test_message), 0, &ptr) < 0)
        goto discard;

    if (bpf_dynptr_write(&ptr, 0, test_message, sizeof(test_message), 0))
        goto discard;
    

    bpf_ringbuf_submit_dynptr(&ptr, 0);
    return 0;

discard:
    bpf_printk("dynptr failed\n");
    bpf_ringbuf_discard_dynptr(&ptr, 0);
    return 0;
}

SEC("fentry/__do_sys_bpfprof")
int ringbuf_dynptr_read_fentry(void *ctx) {
    char sample_data[64] = {};
    struct bpf_dynptr ptr;
    
    if (bpf_ringbuf_reserve_dynptr(&test_ringbuf, sizeof(test_message), 0, &ptr) < 0)
        goto discard;

    if (bpf_dynptr_read(sample_data, sizeof(test_message), &ptr, 0, 0) == 0)
        if (bpf_strncmp(sample_data, sizeof(test_message), test_message) != 0)
            bpf_printk("dynptr read failed\n");
            

discard:
    bpf_ringbuf_discard_dynptr(&ptr, 0);
    return 0;
}

char LICENSE[] SEC("license") = "Dual BSD/GPL";