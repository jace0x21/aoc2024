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
    
    rules, updates := parse_input(string(data))

    total := 0
    fixed_total := 0
    for update in updates {
        middle := len(update)/2
        if is_valid(rules, update) {
            total += update[middle]
        } else {
            fixed := fix_update(rules, update)
            fixed_total += fixed[middle]
        }
    }

    fmt.printf("Part 1: %d\n", total)
    fmt.printf("Part 2: %d\n", fixed_total)
}

Rules :: map[int][dynamic]int
Update :: []int

parse_input :: proc(input: string) -> (Rules, []Update) {
    sections := strings.split(input, "\n\n")  
    // Parse rules
    rules := make(Rules)
    rule_lines := strings.split_lines(sections[0])
    for idx in 0..<len(rule_lines) {
        left, right := parse_rule(rule_lines[idx])
        if right in rules {
            append(&rules[right], left)
        } else {
            rules[right] = make([dynamic]int)
            append(&rules[right], left)
        }
    }
    
    // Parse updates
    update_lines := strings.split_lines(sections[1])
    updates := slice.mapper(update_lines[:len(update_lines)-1], proc(x: string) -> Update {
        return slice.mapper(strings.split(x, ","), proc(y: string) -> int {
            num, ok := strconv.parse_int(y)
            return num
        })
    })

    return rules, updates
}

parse_rule :: proc(input: string) -> (int, int) {
    page_numbers := strings.split(input, "|")
    first, f_ok := strconv.parse_int(page_numbers[0])
    second, s_ok := strconv.parse_int(page_numbers[1])
    return first, second
}

is_valid :: proc(rules: Rules, update: Update) -> bool {
    for idx in 0..<len(update) {
        pn := update[idx]
        if pn in rules {
            for prec in rules[pn] {
                if slice.contains(update[idx+1:], prec) {
                    return false
                }
            }
        }
    }
    return true
}

fix_update :: proc(rules: Rules, update: Update) -> [dynamic]int {
    fixed := slice.to_dynamic(update)
   
    as_slice := fixed[:]
    for !is_valid(rules, as_slice) {
        all: for idx in 0..<len(fixed) {
            pn := fixed[idx]
            if pn in rules {
                for prec in rules[pn] {
                    for s_idx in idx+1..<len(fixed) {
                        if fixed[s_idx] == prec {
                            num := fixed[s_idx]
                            ordered_remove(&fixed, s_idx)
                            inject_idx := idx-1 if idx > 0 else idx
                            inject_at(&fixed, inject_idx, num)
                            as_slice = fixed[:]
                            break all
                        }
                    }
                }
            }
        }
    }
    return fixed
}
