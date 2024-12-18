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

// Represent the map and its state
Map :: struct {
    text: []u8,
    width: int,
    height: int,
    start: int,
    cur_pos: int,
    cur_direction: Direction,
}

// Represent a tile on the map
// We use the file's raw data to represent the map so 
// we can treat newlines as the wall
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

// We always turn to the right
turn :: proc(direction: Direction) -> Direction {
    return Direction((int(direction) + 1) % 4)
}

// Reset the board to its initial state
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

// Do arithmetic to determine neighbors
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

// Find the unique tiles visited along the guard's path
// If a infinite loop is detected, return -1
find_path :: proc(board: ^Map) -> [dynamic]int {
    path: [dynamic]int

    // Reserve some capacity for our data structures
    // to avoid time spent on resizing
    last_steps: [dynamic]int
    reserve(&last_steps, 5000)
    defer delete(last_steps)

    // The occurance map is to help us quickly find loops
    // We do this by finding repeating sub-sequences in last_steps
    occurance_map := make(map[int][dynamic]int)
    reserve(&occurance_map, 5000)
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
        om[k] = make([dynamic]int, 0, 10)
        append(&om[k], v)
    }
}

// Given a path, try placing one obstacle to find possible loops
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

// Given the current steps a guard has taken, determine if they are in a loop
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
        if slice.equal(
            last_steps[occurance-loop_len+1:occurance+1],
            last_steps[occurance+1:]) {
            return true
        }
    }
    return false
}
