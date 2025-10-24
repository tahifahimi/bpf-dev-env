#!/bin/bash
# SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
# Experiment 2 - Test runner for null_fentry_array.kern.c functions
# Tests all three functions in the null_fentry_array.kern.c file:
# - array_map_lookup_fentry: Basic array lookup operation
# - array_map_update_fentry: Array update operation  
# - array_map_stress_lookup: Stress test with 64 lookups

set -e

# Configuration
DURATION=3
INTERVAL=0.5
RESULTS_DIR="results_$(date +%Y%m%d_%H%M%S)"

# Map test variants (BPF programs to test)
# Note: null_fentry_array.kern.c contains multiple functions but only one can be attached at a time
# Each test loads the same .o file but different functions will be attached based on program name
TESTS=(
    "null_fentry_array.kern.o:array_map_update_fentry:Array-Update-Fentry" 
    "null_fentry_array.kern.o:array_map_lookup_fentry:Array-Lookup-Fentry"
    "null_fentry_array.kern.o:array_map_stress_lookup:Array-Stress-Lookup-Fentry"
)

# Create results directory
mkdir -p "$RESULTS_DIR"

echo "============================================"
echo "  Testing null_fentry_array.kern.c Functions"
echo "============================================"
echo "Note: The BPF program contains multiple functions with the same"
echo "      attachment point. Only one can be active at a time."
echo "      This test attempts to load each function individually."
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
