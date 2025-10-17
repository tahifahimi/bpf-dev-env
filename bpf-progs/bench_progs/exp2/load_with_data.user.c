#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <spawn.h>
#include <sys/wait.h>
#include <errno.h>
#include <string.h>

extern char **environ;

int main(int argc, char *argv[]) {
    if (argc < 2 || argc > 3) {
        printf("Usage: %s <bpf_object_file> [num_elements]\n", argv[0]);
        printf("  bpf_object_file: BPF program to load (e.g., array-lookup_fentry.kern.o)\n");
        printf("  num_elements: Number of elements to fill in array (default: 20, max: 100)\n");
        printf("This program will load the BPF program and pre-fill its map with data\n");
        return 1;
    }
    
    const char *bpf_file = argv[1];
    
    // Parse number of elements (default to 20)
    __u32 num_elements = 20;
    if (argc == 3) {
        int parsed = atoi(argv[2]);
        if (parsed <= 0 || parsed > 100) {
            printf("Error: num_elements must be between 1 and 100\n");
            return 1;
        }
        num_elements = (__u32)parsed;
    }
    
    // Open and load the lookup BPF program
    struct bpf_object *obj = bpf_object__open(bpf_file);
    if (!obj) {
        printf("Failed to open BPF object file\n");
        return 1;
    }
    
    if (bpf_object__load(obj)) {
        printf("Failed to load BPF program\n");
        bpf_object__close(obj);
        return 1;
    }
    
    printf("BPF program loaded successfully\n");
    
    // Find the map and fill it with test data
    struct bpf_map *map = bpf_object__find_map_by_name(obj, "shared_data_map");
    if (!map) {
        printf("Failed to find shared_data_map\n");
        bpf_object__close(obj);
        return 1;
    }
    
    int map_fd = bpf_map__fd(map);
    
    // Get the actual map size to validate our input
    __u32 max_entries = bpf_map__max_entries(map);
    if (num_elements > max_entries) {
        printf("Warning: Requested %u elements, but map only has %u max entries. Using %u.\n", 
               num_elements, max_entries, max_entries);
        num_elements = max_entries;
    }
    
    // Pre-fill the map with test data
    printf("Filling map with %u elements of test data...\n", num_elements);
    for (__u32 i = 0; i < num_elements; i++) {
        int value = 1000 + i;  // Test data: 1000, 1001, 1002, ...
        if (bpf_map_update_elem(map_fd, &i, &value, BPF_ANY) != 0) {
            printf("Failed to update map at index %u\n", i);
        }
    }
    printf("Map filled with values %d-%d at indices 0-%u\n", 
           1000, 1000 + num_elements - 1, num_elements - 1);
    

    // Find and attach the program
    struct bpf_program *prog = bpf_object__find_program_by_name(obj, "trigger_syscall_prog");
    if (!prog) {
        printf("Failed to find BPF program\n");
        bpf_object__close(obj);
        return 1;
    }
    
    struct bpf_link *link = bpf_program__attach(prog);
    if (!link) {
        printf("Failed to attach BPF program\n");
        bpf_object__close(obj);
        return 1;
    }
    
    printf("BPF program attached successfully\n");
    printf("Starting benchmark...\n");
    
    // Launch the benchmark
    pid_t pid;
    char * const argv_new[] = { "taskset", "-c", "1", "./bench.user", "30", NULL};
    
    int rc = posix_spawnp(&pid, "taskset", NULL, NULL, argv_new, environ);
    if (rc != 0) {
        fprintf(stderr, "posix_spawnp(taskset) failed: %s\n", strerror(rc));
        goto cleanup;
    }
    
    waitpid(pid, NULL, 0);
    printf("Benchmark completed\n");
    
cleanup:
    bpf_link__destroy(link);
    bpf_object__close(obj);
    
    return 0;
}