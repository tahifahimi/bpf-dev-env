#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <sys/syscall.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <arpa/inet.h>
#include <assert.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <spawn.h>

#include <bpf/bpf.h>
#include <bpf/libbpf.h>

extern char **environ;

int main(int argc, char *argv[])
{
    if (argc != 3) {
        printf("Usage: %s <bpf_file> <program_name>\n", argv[0]);
        printf("  bpf_file: BPF object file to load\n");
        printf("  program_name: Name of the specific program to attach\n");
        return -1;
    }

    char *bpf_path = argv[1];
    char *prog_name = argv[2];
    
    pid_t pid;
    char * const argv_new[] = { "taskset", "-c", "1", "./bench.user", "30", NULL};

    struct bpf_object *prog = bpf_object__open(bpf_path);
    
    if (bpf_object__load(prog)) {
        printf("Failed to load BPF object\n");
        return 0;
    }

    struct bpf_program *program = bpf_object__find_program_by_name(prog, prog_name);

    if (program == NULL) {
        printf("Failed to find program '%s'\n", prog_name);
        bpf_object__close(prog);
        return 0;
    }

    printf("Found program: %s\n", prog_name);

    struct bpf_link *link = bpf_program__attach(program);
    if (libbpf_get_error(link)) {
        printf("Attachment failed for program '%s'\n", prog_name);
        goto cleanup;
    }

    printf("Program '%s' attached successfully\n", prog_name);

    int rc = posix_spawnp(&pid, "taskset", NULL, NULL, argv_new, environ);
    if (rc != 0) {
        fprintf(stderr, "posix_spawnp(taskset) failed: %s\n", strerror(rc));
        return -1;
    }
    waitpid(pid, NULL, 0);

cleanup:
    bpf_link__destroy(link);
    bpf_object__close(prog);
    return 0;
}