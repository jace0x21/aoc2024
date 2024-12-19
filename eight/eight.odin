package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strings"

main :: proc() {
    data, err := os.read_entire_file_from_filename_or_err("input.txt")
    if err != 0 {
        os.print_error(os.stdin, err, "Error")
    }

    x, y := get_dims(data)
    dims := Dimensions{x, y}

    antennas := find_antennas(data)
    defer delete(antennas)
    
    antinode_set: [dynamic]Vector
    true_antinode_set: [dynamic]Vector
    for antenna in antennas {
        get_antinodes(dims, &antinode_set, antennas[antenna][:])
        append_true_antinodes_from_antennas(&true_antinode_set, antennas[antenna][:], dims)
    }

    fmt.printf("Part 1: %d\n", len(antinode_set))
    fmt.printf("Part 2: %d\n", len(true_antinode_set))
}

Dimensions :: struct {width, height: int}
Vector :: struct {x, y: int}

// With the given antenna locations, determine valid antinode locations
get_antinodes :: proc(dims: Dimensions, antinode_set: ^[dynamic]Vector, locations: []Vector) {
    for idx in 0..<len(locations) {
        for other in 0..<len(locations) {
            if idx == other {
                continue
            }
            a, b := get_antinodes_for_pair(locations[idx], locations[other])
            if bounds_check_vector(a, dims) && !slice.contains(antinode_set[:], a) {
                append(antinode_set, a)
            }
            if bounds_check_vector(b, dims) && !slice.contains(antinode_set[:], b) {
                append(antinode_set, b)
            }
        }
    }
}

bounds_check_vector :: proc(v: Vector, dims: Dimensions) -> bool {
    if v.x < 0 || v.y < 0 {
        return false
    }
    if v.x >= dims.width || v.y >= dims.height {
        return false
    }
    return true
}

get_antinodes_for_pair :: proc(a: Vector, b: Vector) -> (Vector, Vector) {
    a := [2]int{a.x, a.y}
    b := [2]int{b.x, b.y}
    result_a, result_b := (a + (a - b)), (b + (b - a))
    return Vector{result_a[0], result_a[1]}, Vector{result_b[0], result_b[1]}
}

append_true_antinodes_from_antennas :: proc(antinode_set: ^[dynamic]Vector, locations: []Vector, dims: Dimensions) {
    for idx in 0..<len(locations) {
        for other in 0..<len(locations) {
            if idx == other {
                continue
            }
            append_true_antinodes(antinode_set, dims, locations[idx], locations[other])
        }
    }
}

append_true_antinodes :: proc(antinode_set: ^[dynamic]Vector, dims: Dimensions, a: Vector, b: Vector) {
    // Determine slope and intercept
    a := [2]int{a.x, a.y}
    b := [2]int{b.x, b.y}

    slope := a - b
    gcd := math.gcd(slope.x, slope.y)
    slope = slope / gcd
    
    cur := a
    for {
        cur -= slope
        antinode := Vector{cur[0], cur[1]}
        if !bounds_check_vector(antinode, dims) {
            break
        }
        if !slice.contains(antinode_set[:], antinode) {
            append(antinode_set, antinode)
        }
    }

    cur = a
    for {
        cur += slope
        antinode := Vector{cur[0], cur[1]}
        if !bounds_check_vector(antinode, dims) {
            break
        }
        if !slice.contains(antinode_set[:], antinode) {
            append(antinode_set, antinode)
        }
    }
}

// Find all the antennas on the board and convert them to vectors
find_antennas :: proc(data: []u8) -> map[u8][dynamic]Vector {
    width, height := get_dims(data)
    antennas := make(map[u8][dynamic]Vector)
    for idx in 0..<len(data) {
        // Ignore empty tiles and newlines
        if data[idx] != '.' && data[idx] != '\n' {
            antenna := data[idx]
            if antenna in antennas {
                append(&antennas[antenna], idx_to_vector(idx, width, height))
            } else {
                antennas[antenna] = make([dynamic]Vector)
                append(&antennas[antenna], idx_to_vector(idx, width, height))
            }
        }
    }
    return antennas
}

get_dims :: proc(data: []u8) -> (width: int, height: int) {
    lines := slice.filter(strings.split_lines(string(data)), 
        proc(x: string) -> bool {
            return x != ""
        }
    )
    width = len(lines[0])
    height = len(lines)
    return
}

// Convert an index into the data buffer into a vector
idx_to_vector :: proc(idx: int, width: int, height: int) -> Vector {
    x := (idx % (width+1))
    y := (height - (idx / (width+1))) - 1
    return Vector{x, y}
}

