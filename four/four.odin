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

    text := string(data)
    width, height := get_dims(text)
    board := Board{text, width, height}
    
    line_matches := 0
    x_matches := 0
    for idx in 0..<len(board.text) {
        matches := count_matching_paths(board, idx, "XMAS")
        line_matches += matches

        if is_x(board, idx, "MAS") {
            x_matches += 1
        }
    }

    fmt.printf("Part 1: %d\n", line_matches)
    fmt.printf("Part 2: %d\n", x_matches)
}

Board :: struct {
    text: string,
    width: int,
    height: int,
}

Direction :: enum {Top, TopLeft, TopRight, Bottom, BottomLeft, BottomRight, Left, Right}

is_x :: proc(board: Board, pos: int, word: string) -> bool {
    if board.text[pos] != word[1] {
        return false
    }

    tl := get_neighbor(board, pos, .TopLeft)
    if tl == -1 {
        return false
    }
    tr := get_neighbor(board, pos, .TopRight)
    if tr == -1 {
        return false
    }
    bl := get_neighbor(board, pos, .BottomLeft)
    if bl == -1 {
        return false
    }
    br := get_neighbor(board, pos, .BottomRight)
    if br == -1 {
        return false
    }

    key := word[0] ~ word[2]
    if (board.text[br] ~ board.text[tl] == key) && 
       (board.text[bl] ~ board.text[tr] == key) {
        return true
    } else {
        return false
    }
}

count_matching_paths :: proc(board: Board, pos: int, word: string) -> int {
    total := 0
    for direction, idx in Direction {
        if is_matching_path(board, pos, direction, word) {
            total += 1
        }
    }
    return total
}

is_matching_path :: proc(board: Board, pos: int, direction: Direction, word: string) -> bool {
    if board.text[pos] != word[0] {
        return false
    }
    if len(word) == 1 {
        return true
    }
    neighbor := get_neighbor(board, pos, direction)
    if neighbor == -1 {
        return false
    }
    return is_matching_path(board, neighbor, direction, word[1:])
}


get_dims :: proc(input: string) -> (int, int) {
    lines := strings.split_lines(input) 
    return len(lines[0]), len(lines)
}

get_neighbors :: proc(board: Board, idx: int) -> [dynamic]int {
    neighbors: [dynamic]int

    for direction, index in Direction {
        neighbor := get_neighbor(board, idx, direction)
        if neighbor != -1 {
            append(&neighbors, neighbor)
        }
    }

    return neighbors
}

get_neighbor :: proc(board: Board, idx: int, direction: Direction) -> int {
    switch direction {
    case .Top:
        if idx-(board.width+1) >= 0 {
            return idx-(board.width+1)
        } else {
            return -1
        }
    case .Bottom: 
        if idx+(board.width+1) < len(board.text) {
            return idx+(board.width+1)
        } else {
            return -1
        }
    case .Left:
        if idx-1 > 0 {
            if board.text[idx-1] != '\n' {
                return idx-1
            }
        }
        return -1
    case .Right:
        if idx+1 < len(board.text) {
            if board.text[idx+1] != '\n' {
                return idx+1
            }
        }
        return -1
    case .TopLeft:
        top := get_neighbor(board, idx, .Top)
        if top != -1 {
            return get_neighbor(board, top, .Left)
        } else {
            return -1
        }
    case .TopRight:
        top := get_neighbor(board, idx, .Top)
        if top != -1 {
            return get_neighbor(board, top, .Right)
        } else {
            return -1
        }
    case .BottomLeft:
        bottom := get_neighbor(board, idx, .Bottom)
        if bottom != -1 {
            return get_neighbor(board, bottom, .Left)
        } else {
            return -1
        }
    case .BottomRight:
        bottom := get_neighbor(board, idx, .Bottom)
        if bottom != -1 {
            return get_neighbor(board, bottom, .Right)
        } else {
            return -1
        }
    case:
        return -1
    }
}

