#!/bin/bash
# SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
# Experiment 2 - Test runner for fentry array, hash, and queue map functions
# Tests all functions in null_fentry_array.kern.c, null_fentry_hash.kern.c, and null_fentry_queue.kern.c:
#
# Array Map Functions:
# - array_map_lookup_fentry: Basic array lookup operation
# - array_map_update_fentry: Array update operation  
# - array_map_stress_lookup: Stress test with 64 array lookups
#
# Hash Map Functions:
# - hash_map_lookup_fentry: Basic hash lookup operation
# - hash_map_update_fentry: Hash update operation
# - hash_map_stress_lookup: Stress test with 64 hash lookups
#
# Queue Map Functions:
# - queue_map_push_fentry: Push (enqueue) operation
# - queue_map_pop_fentry: Pop (dequeue) operation
# - queue_map_peek_fentry: Peek operation (read without removing)
#
# Ring Buffer Functions:
# - ringbuf_map_reserve_fentry: Ring buffer reserve operation
# - ringbuf_map_submit_fentry: Ring buffer reserve and submit operation
# - ringbuf_output_fentry: Ring buffer direct output operation
# - ringbuf_dynptr_submit_fentry: Ring buffer dynptr reserve, write and submit
# - ringbuf_dynptr_read_fentry: Ring buffer dynptr reserve and read

set -e

# Configuration
DURATION=3
INTERVAL=0.5
RESULTS_DIR="results_$(date +%Y%m%d_%H%M%S)"

# Map test variants (BPF programs to test)
# Note: All .kern.c files contain multiple functions but only one can be attached at a time
# Each test loads the same .o file but different functions will be attached based on program name
TESTS=(
    # Array Map Tests - null_fentry_array.kern.c
    "null_fentry_array.kern.o:array_map_update_fentry:Array-Update-Fentry"
    "null_fentry_array.kern.o:array_map_lookup_fentry:Array-Lookup-Fentry"
    "null_fentry_array.kern.o:array_map_stress_lookup:Array-Stress-Lookup-Fentry"
    
    # Hash Map Tests - null_fentry_hash.kern.c
    "null_fentry_hash.kern.o:hash_map_lookup_fentry:Hash-Lookup-Fentry"
    "null_fentry_hash.kern.o:hash_map_update_fentry:Hash-Update-Fentry"
    "null_fentry_hash.kern.o:hash_map_stress_lookup:Hash-Stress-Lookup-Fentry"
    "null_fentry_hash.kern.o:hash_map_delete:Hash-Delete-Fentry"
    
    # Queue Map Tests - null_fentry_queue.kern.c
    "null_fentry_queue.kern.o:queue_map_push_fentry:Queue-Push-Fentry"
    "null_fentry_queue.kern.o:queue_map_pop_fentry:Queue-Pop-Fentry"
    "null_fentry_queue.kern.o:queue_map_peek_fentry:Queue-Peek-Fentry"
    
    # Ring Buffer Tests - null_fentry_ringbuf.kern.c
    "null_fentry_ringbuf.kern.o:ringbuf_map_reserve_fentry:Ringbuf-Reserve-Fentry"
    "null_fentry_ringbuf.kern.o:ringbuf_map_submit_fentry:Ringbuf-Submit-Fentry"
    "null_fentry_ringbuf.kern.o:ringbuf_output_fentry:Ringbuf-Output-Fentry"
    "null_fentry_ringbuf.kern.o:ringbuf_dynptr_submit_fentry:Ringbuf-Dynptr-Submit-Fentry"
    "null_fentry_ringbuf.kern.o:ringbuf_dynptr_read_fentry:Ringbuf-Dynptr-Read-Fentry"
)

# Create results directory
mkdir -p "$RESULTS_DIR"

echo "============================================"
echo "  Testing Fentry Array, Hash, Queue & Ringbuf Functions"
echo "============================================"
echo "Testing functions from:"
echo "  - null_fentry_array.kern.c (3 array functions)"
echo "  - null_fentry_hash.kern.c (4 hash functions)"
echo "  - null_fentry_queue.kern.c (3 queue functions)"
echo "  - null_fentry_ringbuf.kern.c (5 ringbuf functions)"
echo ""
echo "Note: Each BPF program contains multiple functions with the same"
echo "      attachment point. Only one can be active at a time."
echo "      This test loads each function individually."
echo "Duration: ${DURATION}s per test"
echo "Interval: ${INTERVAL}s"
echo "Results: $RESULTS_DIR"
echo "Total tests: ${#TESTS[@]}"
echo ""

# Function to run a single test
run_test() {
    local bpf_prog=$1
    local prog_name=$2
    local test_name=$3
    local output_file="${RESULTS_DIR}/${test_name}.txt"
    
    echo "Testing: $test_name"
    echo "  BPF Program: $bpf_prog"
    echo "  Function: $prog_name"
    echo "  Output: $output_file"
    
    # Check if BPF program exists
    if [ ! -f "$bpf_prog" ]; then
        echo "  ERROR: BPF program not found!"
        echo "ERROR: $bpf_prog not found" > "$output_file"
        return 1
    fi
    
    # Run the test and capture output
    echo "=== $test_name ===" > "$output_file"
    echo "BPF Program: $bpf_prog" >> "$output_file"
    echo "Function: $prog_name" >> "$output_file"
    echo "Duration: ${DURATION}s" >> "$output_file"
    echo "Date: $(date)" >> "$output_file"
    echo "" >> "$output_file"
    
    # Use custom loader that can specify program name, or fall back to default
    if [ -f "./load_prog.user" ]; then
        ./load_prog.user "$bpf_prog" "$prog_name" 2>&1 | tee -a "$output_file"
    else
        echo "Warning: load_prog.user not found, using default loader" | tee -a "$output_file"
        echo "Note: Only the first program in the object will be loaded" | tee -a "$output_file"
        ./load.user "$bpf_prog" 2>&1 | tee -a "$output_file"
    fi
    
    echo "  ✓ Complete"
    echo ""
}

# Check if programs are built
if [ ! -f "load.user" ]; then
    echo "ERROR: load.user not found. Please run 'make' first."
    exit 1
fi

# Run all tests
test_num=0
for test_spec in "${TESTS[@]}"; do
    test_num=$((test_num + 1))
    IFS=':' read -r bpf_prog prog_name test_name <<< "$test_spec"
    
    echo "[$test_num/${#TESTS[@]}] ----------------------------------------"
    run_test "$bpf_prog" "$prog_name" "$test_name"
    
    # Short pause between tests
    sleep 2
done

# Generate summary report
SUMMARY_FILE="${RESULTS_DIR}/SUMMARY.md"
echo "# Array, Hash, Queue & Ringbuf Fentry Functions Test Results Summary" > "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "Generated: $(date)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "## Test Configuration" >> "$SUMMARY_FILE"
echo "- Duration: ${DURATION}s per test" >> "$SUMMARY_FILE"
echo "- Interval: ${INTERVAL}s" >> "$SUMMARY_FILE"
echo "- Total tests: ${#TESTS[@]}" >> "$SUMMARY_FILE"
echo "- Array functions: 3 (lookup, update, stress)" >> "$SUMMARY_FILE"
echo "- Hash functions: 4 (lookup, update, stress, delete)" >> "$SUMMARY_FILE"
echo "- Queue functions: 3 (push, pop, peek)" >> "$SUMMARY_FILE"
echo "- Ringbuf functions: 5 (reserve, submit, output, dynptr-submit, dynptr-read)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "## Results" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "| Test Name | BPF Program | Function | Avg Calls/Interval | Result File |" >> "$SUMMARY_FILE"
echo "|-----------|-------------|----------|-------------------|-------------|" >> "$SUMMARY_FILE"

# Extract average calls per interval from each result file
for test_spec in "${TESTS[@]}"; do
    IFS=':' read -r bpf_prog prog_name test_name <<< "$test_spec"
    result_file="${RESULTS_DIR}/${test_name}.txt"
    
    if [ -f "$result_file" ]; then
        # Calculate average from all intervals (format: timestamp:calls)
        avg_calls=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "$result_file" | \
                    awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
        echo "| $test_name | $bpf_prog | $prog_name | $avg_calls | $test_name.txt |" >> "$SUMMARY_FILE"
    else
        echo "| $test_name | $bpf_prog | $prog_name | ERROR | $test_name.txt |" >> "$SUMMARY_FILE"
    fi
done

echo "" >> "$SUMMARY_FILE"
echo "## Performance Analysis" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "### Array vs Hash vs Queue vs Ringbuf Comparison" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "**Expected Performance Ranking (Fastest → Slowest):**" >> "$SUMMARY_FILE"
echo "1. Array operations (direct index access)" >> "$SUMMARY_FILE"
echo "2. Ring buffer operations (high-performance circular buffer)" >> "$SUMMARY_FILE"
echo "3. Queue operations (FIFO ordering, no key hashing)" >> "$SUMMARY_FILE"
echo "4. Hash operations (hash computation + bucket lookup)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "**Operation Types:**" >> "$SUMMARY_FILE"
echo "- **Array**: Lookup, Update, Stress (64 lookups)" >> "$SUMMARY_FILE"
echo "- **Hash**: Lookup, Update, Stress (64 lookups), Delete" >> "$SUMMARY_FILE"
echo "- **Queue**: Push (enqueue), Pop (dequeue), Peek (read front)" >> "$SUMMARY_FILE"
echo "- **Ringbuf**: Reserve, Submit (reserve+write+submit), Output (direct), Dynptr-Submit (dynptr API), Dynptr-Read (dynptr read)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

# Generate performance comparison
echo "### Detailed Comparison" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

# Extract specific metrics for comparison
array_lookup=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Array-Lookup-Fentry.txt" 2>/dev/null | \
               awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
hash_lookup=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Hash-Lookup-Fentry.txt" 2>/dev/null | \
              awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
array_update=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Array-Update-Fentry.txt" 2>/dev/null | \
               awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
hash_update=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Hash-Update-Fentry.txt" 2>/dev/null | \
              awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
array_stress=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Array-Stress-Lookup-Fentry.txt" 2>/dev/null | \
               awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
hash_stress=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Hash-Stress-Lookup-Fentry.txt" 2>/dev/null | \
              awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
queue_push=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Queue-Push-Fentry.txt" 2>/dev/null | \
             awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
queue_pop=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Queue-Pop-Fentry.txt" 2>/dev/null | \
            awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
queue_peek=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Queue-Peek-Fentry.txt" 2>/dev/null | \
             awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
ringbuf_reserve=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Ringbuf-Reserve-Fentry.txt" 2>/dev/null | \
                  awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
ringbuf_submit=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Ringbuf-Submit-Fentry.txt" 2>/dev/null | \
                 awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
ringbuf_output=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Ringbuf-Output-Fentry.txt" 2>/dev/null | \
                 awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
ringbuf_dynptr_submit=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Ringbuf-Dynptr-Submit-Fentry.txt" 2>/dev/null | \
                       awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')
ringbuf_dynptr_read=$(grep -E "^[0-9]+\.[0-9]+:[0-9]+" "${RESULTS_DIR}/Ringbuf-Dynptr-Read-Fentry.txt" 2>/dev/null | \
                     awk -F: '{sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')

echo "| Operation | Array Calls/Interval | Hash Calls/Interval | Queue Calls/Interval | Ringbuf Calls/Interval | Hash vs Array | Queue vs Array | Ringbuf vs Array |" >> "$SUMMARY_FILE"
echo "|-----------|---------------------|-------------------|---------------------|----------------------|--------------|---------------|-----------------|" >> "$SUMMARY_FILE"
echo "| Lookup | $array_lookup | $hash_lookup | N/A | N/A | $(if [[ "$array_lookup" != "N/A" && "$hash_lookup" != "N/A" && "$array_lookup" -gt 0 ]]; then echo "scale=1; ($array_lookup - $hash_lookup) * 100 / $array_lookup" | bc -l | sed 's/^\./0./'%; else echo "N/A"; fi) | N/A | N/A |" >> "$SUMMARY_FILE"
echo "| Update | $array_update | $hash_update | N/A | N/A | $(if [[ "$array_update" != "N/A" && "$hash_update" != "N/A" && "$array_update" -gt 0 ]]; then echo "scale=1; ($array_update - $hash_update) * 100 / $array_update" | bc -l | sed 's/^\./0./'%; else echo "N/A"; fi) | N/A | N/A |" >> "$SUMMARY_FILE"
echo "| Stress | $array_stress | $hash_stress | N/A | N/A | $(if [[ "$array_stress" != "N/A" && "$hash_stress" != "N/A" && "$array_stress" -gt 0 ]]; then echo "scale=1; ($array_stress - $hash_stress) * 100 / $array_stress" | bc -l | sed 's/^\./0./'%; else echo "N/A"; fi) | N/A | N/A |" >> "$SUMMARY_FILE"
echo "| Push | N/A | N/A | $queue_push | N/A | N/A | N/A | N/A |" >> "$SUMMARY_FILE"
echo "| Pop | N/A | N/A | $queue_pop | N/A | N/A | N/A | N/A |" >> "$SUMMARY_FILE"
echo "| Peek | N/A | N/A | $queue_peek | N/A | N/A | N/A | N/A |" >> "$SUMMARY_FILE"
echo "| Reserve | N/A | N/A | N/A | $ringbuf_reserve | N/A | N/A | N/A |" >> "$SUMMARY_FILE"
echo "| Submit | N/A | N/A | N/A | $ringbuf_submit | N/A | N/A | N/A |" >> "$SUMMARY_FILE"
echo "| Output | N/A | N/A | N/A | $ringbuf_output | N/A | N/A | N/A |" >> "$SUMMARY_FILE"
echo "| Dynptr-Submit | N/A | N/A | N/A | $ringbuf_dynptr_submit | N/A | N/A | N/A |" >> "$SUMMARY_FILE"
echo "| Dynptr-Read | N/A | N/A | N/A | $ringbuf_dynptr_read | N/A | N/A | N/A |" >> "$SUMMARY_FILE"

echo "" >> "$SUMMARY_FILE"
echo "## Analysis Commands" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "To analyze results:" >> "$SUMMARY_FILE"
echo '```bash' >> "$SUMMARY_FILE"
echo "# View individual test results" >> "$SUMMARY_FILE"
echo "cat $RESULTS_DIR/<test-name>.txt" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "# Compare throughput across all tests" >> "$SUMMARY_FILE"
echo "grep -h \"Avg Calls\" $RESULTS_DIR/*.txt" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "# View this summary" >> "$SUMMARY_FILE"
echo "cat $SUMMARY_FILE" >> "$SUMMARY_FILE"
echo '```' >> "$SUMMARY_FILE"

echo "" >> "$SUMMARY_FILE"
echo "## Key Insights" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "- **Array maps** provide baseline performance (direct index access)" >> "$SUMMARY_FILE"
echo "- **Ring buffers** offer high-performance kernel-to-userspace data transfer" >> "$SUMMARY_FILE"
echo "- **Queue maps** provide FIFO semantics with moderate overhead" >> "$SUMMARY_FILE"
echo "- **Hash maps** show additional overhead from hash computation" >> "$SUMMARY_FILE"
echo "- **Stress tests** amplify the differences (64x the overhead)" >> "$SUMMARY_FILE"
echo "- **Fentry attachment** provides low-overhead benchmarking" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "### Ring Buffer Operation Comparison:" >> "$SUMMARY_FILE"
echo "- **Reserve**: Only reserves space (fastest)" >> "$SUMMARY_FILE"
echo "- **Submit**: Reserve + write + submit (moderate)" >> "$SUMMARY_FILE"
echo "- **Output**: Direct output with internal reserve/submit (varies)" >> "$SUMMARY_FILE"
echo "- **Dynptr-Submit**: Reserve + dynptr write + submit (dynptr API overhead)" >> "$SUMMARY_FILE"
echo "- **Dynptr-Read**: Reserve + dynptr read (read-only operation)" >> "$SUMMARY_FILE"

echo ""
echo "============================================"
echo "  All tests complete!"
echo "============================================"
echo "Results directory: $RESULTS_DIR"
echo "Summary: $SUMMARY_FILE"
echo ""
echo "To view summary:"
echo "  cat $SUMMARY_FILE"
echo ""
