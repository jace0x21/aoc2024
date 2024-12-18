package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

main :: proc() {
    data, err := os.read_entire_file_from_filename_or_err("input.txt")
    if err != 0 {
        os.print_error(os.stdin, err, "Error")
    }

    text := string(data)
    width, height := get_dims(text)
    start := find_guard(text)
    board := Map{data, width, height, start, start, .North}
   
    path := find_path(&board)
    loop_count := find_possible_loops(&board, path[:])

    fmt.printf("Part 1: %d\n", len(path))
    fmt.printf("Part 2: %d\n", loop_count)
}

Map :: struct {
    text: []u8,
    width: int,
    height: int,
    start: int,
    cur_pos: int,
    cur_direction: Direction,
}

Tile :: enum u8 {
    Empty = '.', 
    Obstacle = '#', 
    Visited = 'X',
    Wall = '\n',
    Guard = '^'
}

Direction :: enum {North, East, South, West}

get_dims :: proc(input: string) -> (int, int) {
    lines := strings.split_lines(input) 
    return len(lines[0]), len(lines)
}

find_guard :: proc(input: string) -> int {
    for idx in 0..<len(input) {
        if input[idx] == u8(Tile.Guard) {
            return idx
        }
    }
    return -1
}

turn :: proc(direction: Direction) -> Direction {
    return Direction((int(direction) + 1) % 4)
}

reset :: proc(board: ^Map) {
    for idx in 0..<len(board.text) {
        if idx == board.start {
            board.text[idx] = u8(Tile.Guard)
        }
        else if board.text[idx] == u8(Tile.Visited) {
            board.text[idx] = u8(Tile.Empty)
        }
    }
    board.cur_pos = board.start
    board.cur_direction = .North
}

get_neighbor :: proc(board: Map, idx: int, direction: Direction) -> int {
    switch direction {
    case .North:
        if idx-(board.width+1) >= 0 {
            return idx-(board.width+1)
        } else {
            return -1
        }
    case .South: 
        if idx+(board.width+1) < len(board.text) {
            return idx+(board.width+1)
        } else {
            return -1
        }
    case .West:
        if idx-1 > 0 {
            return idx-1
        }
        return -1
    case .East:
        if idx+1 < len(board.text) {
            return idx+1
        }
        return -1
    case:
        return -1
    }
}

find_path :: proc(board: ^Map) -> [dynamic]int {
    path: [dynamic]int
    
    last_steps: [dynamic]int
    defer delete(last_steps)

    occurance_map := make(map[int][dynamic]int)
    defer delete(occurance_map)

    append(&path, board.cur_pos)
    board.text[board.cur_pos] = u8(Tile.Visited)
    main_loop: for {
        next := get_neighbor(board^, board.cur_pos, board.cur_direction)
        if next == -1 {
            break
        }
        switch Tile(board.text[next]) {
        case .Empty:
            board.text[next] = u8(Tile.Visited)
            board.cur_pos = next
            append(&path, board.cur_pos)
            append(&last_steps, board.cur_pos)
            add_to_occurance_map(&occurance_map, board.cur_pos, len(last_steps)-1) 
        case .Visited:
            board.cur_pos = next
            append(&last_steps, board.cur_pos)
            add_to_occurance_map(&occurance_map, board.cur_pos, len(last_steps)-1) 
            if has_loop(last_steps[:], occurance_map) {
                return nil
            }
        case .Obstacle:
            board.cur_direction = turn(board.cur_direction)
        case .Wall:
            break main_loop
        case .Guard:
            fmt.printf("Unexpectedly found Guard\n")
            return path
        }
    }
    return path
}

add_to_occurance_map :: proc(om: ^map[int][dynamic]int, k: int, v: int) {
    if k in om {
        append(&om[k], v)
    } else {
        om[k] = make([dynamic]int)
        append(&om[k], v)
    }
}

find_possible_loops :: proc(board: ^Map, path: []int) -> int {
    loop_count := 0
    for pos in path {
        reset(board)
        if board.text[pos] == u8(Tile.Guard) {
            continue
        }
        board.text[pos] = u8(Tile.Obstacle)
        if find_path(board) == nil {
            loop_count += 1
        }
        board.text[pos] = u8(Tile.Empty)
    }
    return loop_count
}

has_loop :: proc(last_steps: []int, om: map[int][dynamic]int) -> bool {
    cur_pos := last_steps[len(last_steps)-1]
    for occurance in om[cur_pos] {
        if occurance == (len(last_steps) - 1) {
            continue
        }
        loop_len := (len(last_steps) - occurance) - 1
        if loop_len*2 > len(last_steps) {
            continue
        }
        //fmt.printf("Comparing:\n1: %v\n2: %v\n",
        //    last_steps[occurance-loop_len+1:occurance+1],
        //    last_steps[occurance+1:])
        //os.flush(os.stdout)             
        if slice.equal(
            last_steps[occurance-loop_len+1:occurance+1],
            last_steps[occurance+1:]) {
            return true
        }
    }
    return false
}
