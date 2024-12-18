package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:unicode"

main :: proc() {
    data, err := os.read_entire_file_from_filename_or_err("input.txt")
    if err != 0 {
        os.print_error(os.stdin, err, "Error")
    }
   
    text := string(data)

    enabled := true
    total := 0
    cond_total := 0
    idx := 0
    for idx < len(text) {
        if text[idx] == 'd' {
            result, success := consume_cond(text, &idx)
            if success {
                enabled = result
                continue
            }
        }
        else if text[idx] == 'm' {
            result, success := consume_mul(text, &idx)
            if success {
                if enabled {
                    cond_total += result
                }
                total += result
                continue
            }
        }
        idx += 1
    }

    fmt.printf("Part 1: %d\n", total)
    fmt.printf("Part 2: %d\n", cond_total)
}

consume_cond :: proc(text: string, idx_ptr: ^int) -> (bool, bool) {
    if text[idx_ptr^:idx_ptr^+4] == "do()" {
        idx_ptr^ += 4
        return true, true
    } else if text[idx_ptr^:idx_ptr^+7] == "don't()" {
        idx_ptr^ += 7
        return false, true
    } else {
        return false, false
    }
}

consume_mul :: proc(text: string, idx_ptr: ^int) -> (int, bool) {
    if text[idx_ptr^:idx_ptr^+4] == "mul(" {
        idx_ptr^ += 4
        return consume_arguments(text, idx_ptr)
    } else {
        return -1, false
    }
}

consume_arguments :: proc(text: string, idx_ptr: ^int) -> (int, bool) {
    first_arg, f_success := consume_int(text, idx_ptr, ',')
    if !f_success {
        return -1, false
    }
    second_arg, s_success := consume_int(text, idx_ptr, ')')
    if !s_success {
        return -1, false
    }
    return first_arg * second_arg, true
}

consume_int :: proc(text: string, idx_ptr: ^int, delim: rune) -> (int, bool) {
    start_idx := idx_ptr^
    for {
        if unicode.is_digit(rune(text[idx_ptr^])) {
            idx_ptr^ += 1
        } else if rune(text[idx_ptr^]) == delim {
            break
        } else {
            return -1, false
        }
    }
    n, ok := strconv.parse_int(text[start_idx:idx_ptr^])
    idx_ptr^ += 1
    return n, true
}

