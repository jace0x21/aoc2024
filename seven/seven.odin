package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

main :: proc() {
    data, err := os.read_entire_file_from_filename_or_err("input.txt")
    if err != 0 {
        os.print_error(os.stdin, err, "Error")
    }
    
    equations := parse_input(string(data))

    solution := 0
    combine_enabled_solution := 0
    for equation in equations {
        if is_solvable(equation) {
            solution += equation.result
        } 
        if is_solvable(equation, true) {
            combine_enabled_solution += equation.result
        }
    }

    fmt.printf("Part 1: %d\n", solution)
    fmt.printf("Part 2: %d\n", combine_enabled_solution)
}

Equation :: struct {
    result: int,
    operands: []int,
}

Operator :: enum {Multiply, Add, Combine}

combine :: proc(left: int, right: int) -> int {
    ls, rs: [64]u8
    left := strconv.itoa(ls[:], left)
    right := strconv.itoa(rs[:], right)
    combined_string := strings.concatenate({left, right})
    result, ok := strconv.parse_int(combined_string)
    return result
}

is_solvable :: proc(equation: Equation, combine_enabled: bool = false, idx: int = 0, total: int = 0) -> bool {
    if len(equation.operands) < 2 {
        return false
    }
    if idx == 0 {
        return is_solvable(equation, combine_enabled, 1, equation.operands[0])
    }
    for operator in Operator {
        new_total: int
        switch operator {
        case .Multiply:
            new_total = total * equation.operands[idx]
        case .Add:
            new_total = total + equation.operands[idx]
        case .Combine:
            if combine_enabled {
                new_total = combine(total, equation.operands[idx])
            }
        }
        if (idx == (len(equation.operands)-1)) {
            if new_total == equation.result {
                return true
            } else {
                continue
            }
        }
        //if new_total >= equation.result {
        //    continue
        //}
        if is_solvable(equation, combine_enabled, idx+1, new_total) {
            return true
        }
    }
    return false
}

parse_input :: proc(input: string) -> []Equation {
    lines := strings.split_lines(input) 
    equations := make([]Equation, len(lines))
    e_idx := 0
    for line in lines {
        if line == "" {
            continue
        }
        elements := strings.split(line, " ")

        result := elements[0][:len(elements[0])-1]
        parsed_result, ok := strconv.parse_int(result)

        operands := make([]int, len(elements)-1)
        for idx in 1..<len(elements) {
            operand, ok := strconv.parse_int(elements[idx])
            operands[idx-1] = operand
        }

        equations[e_idx] = Equation{parsed_result, operands}
        e_idx += 1
    }
    return equations
}
