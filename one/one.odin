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
    
    left, right := parse_input(string(data))
    slice.sort(left)
    slice.sort(right)

    total_distance := 0
    for idx in 0..<len(left) {
        total_distance += abs(left[idx] - right[idx])
    }

    fmt.printf("Part 1: %d\n", total_distance)

    similarity_score := 0
    for left_idx in 0..<len(left) {
        multiplier := 0
        for right_idx in 0..<len(right) {
            if left[left_idx] == right[right_idx] {
                multiplier += 1
            }
        }
        similarity_score += left[left_idx]*multiplier
    }

    fmt.printf("Part 2: %d\n", similarity_score)
}

parse_input :: proc(input: string) -> ([]int, []int) {
    lines := strings.split_lines(input) 

    left := make([]int, len(lines)-1)
    right := make([]int, len(lines)-1)
    arr_idx := 0

    for idx in 0..<len(lines) {
        numbers := strings.split(lines[idx], "   ")
        if (len(numbers) != 2) {
            continue
        }
        left[arr_idx], _ = strconv.parse_int(numbers[0])
        right[arr_idx], _ = strconv.parse_int(numbers[1])
        arr_idx += 1
    }
    
    return left, right
}
