package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:strconv"

main :: proc() {
    data, err := os.read_entire_file_from_filename_or_err("input.txt")
    if err != 0 {
        os.print_error(os.stdin, err, "Error")
    }
   
    reports := parse_input(string(data))

    safe_count := 0
    almost_safe_count := 0
    for idx in 0..<len(reports) {
        report := slice.clone_to_dynamic(reports[idx])
        if is_safe(report) {
            safe_count += 1
            almost_safe_count += 1
        } else if is_almost_safe(report) {
            almost_safe_count += 1
        }
    }

    fmt.printf("Part 1: %d\n", safe_count)
    fmt.printf("Part 2: %d\n", almost_safe_count)
}

is_almost_safe :: proc(input: [dynamic]int) -> bool {
    for idx in 0..<len(input) {
        if is_safe_without(input, idx) {
            return true
        }
    }
    return false
}

is_safe_without :: proc(input: [dynamic]int, idx: int) -> bool {
    copy := slice.clone_to_dynamic(input[:])
    ordered_remove(&copy, idx)
    result := is_safe(copy)
    delete(copy)
    return result
}

is_safe :: proc(input: [dynamic]int) -> bool {
    last_change := input[1] - input[0]
    for idx in 1..<len(input) {
        current_change := input[idx] - input[idx-1]
        abs_change := abs(current_change)
        if abs_change < 1 || abs_change > 3 {
            return false
        }
        if (last_change < 0) != (current_change < 0) {
            return false
        }
        last_change = current_change
    }
    return true
}

parse_input :: proc(input: string) -> ([][]int) {
    lines := strings.split_lines(input) 

    reports := make([][]int, len(lines)-1)
    arr_idx := 0
    for idx in 0..<len(lines)-1 {
        levels := strings.split(lines[idx], " ")
        parsed := slice.mapper(levels, proc(x: string) -> int {
            result, ok := strconv.parse_int(x)
            return result
        })
        reports[arr_idx] = parsed
        arr_idx += 1
    }
    
    return reports
}
