package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:strconv"

// This solution is a mess lol

main :: proc() {
    data, err := os.read_entire_file_from_filename_or_err("input.txt")
    if err != 0 {
        os.print_error(os.stdin, err, "Error")
    }
   
    fs := parse_input(string(data))
    collect(&fs)
    fmt.printf("Part 1: %d\n", calc_checksum(fs))

    fs = parse_input(string(data))
    bfs := to_blockfs(fs, len(string(data))-1)
    collect_blockfs(&bfs)
    fmt.printf("Part 2: %d\n", calc_checksum(bfs.raw))
}

BlockFilesystem :: struct {
    raw: Filesystem,
    blocks: [dynamic]Block,
    last_fb: int,
}

Block :: struct {
    id: int,
    size: int,
    index: int,
}

Filesystem :: struct {
    blocks: []int,
    last_fb: int,
}

parse_input :: proc(input: string) -> (fs: Filesystem) {
    numbers := slice.mapper(transmute([]u8)input[:len(input)-1], proc(x: u8) -> int {
        return int(x - 48)
    })
    total_blocks := slice.reduce(numbers, 0, proc(acc: int, x: int) -> int {
        return acc + x
    })
    fs.blocks = make([]int, total_blocks)
    cur_id := 0
    fs_idx := 0
    for idx in 0..<len(numbers) {
        number := numbers[idx]
        if idx % 2 == 0 {
            for inc in 0..<number {
                fs.blocks[fs_idx] = cur_id
                fs_idx += 1
            }
            cur_id += 1
        } else {
            for inc in 0..<number {
                fs.blocks[fs_idx] = -1
                fs_idx += 1
            }
        }
    }
    init_last_fb(&fs)
    return
}

init_last_fb :: proc(fs: ^Filesystem) {
    for idx := (len(fs.blocks)-1); idx != 0; idx -= 1 {
        if fs.blocks[idx] != -1 {
            fs.last_fb = idx
            break
        }
    }
}

print_fs :: proc(fs: Filesystem) {
    for block in fs.blocks {
        if block == -1 {
            fmt.print(".")
        } else {
            fmt.printf("%d", block)
        }
    }
    fmt.print("\n")
}

calc_checksum :: proc(fs: Filesystem) -> (checksum: int) {
    for idx in 0..<len(fs.blocks) {
        if fs.blocks[idx] == -1 {
            continue
        }
        checksum += idx * fs.blocks[idx]
    }
    return 
}

collect :: proc(fs: ^Filesystem) {
    for idx in 0..<len(fs.blocks) {
        if idx > fs.last_fb {
            break
        }
        if fs.blocks[idx] == -1 {
            new_val := pop_last_file_block(fs)
            fs.blocks[idx] = new_val
        }
    }
}

pop_last_file_block :: proc(fs: ^Filesystem) -> (value: int) {
    value = fs.blocks[fs.last_fb]
    fs.blocks[fs.last_fb] = -1
    for fs.blocks[fs.last_fb] == -1 {
        fs.last_fb -= 1
    }
    return
}

to_blockfs :: proc(fs: Filesystem, initial_size: int) -> (bfs: BlockFilesystem) {
    bfs.raw = fs
    reserve(&bfs.blocks, initial_size)
    bfs_idx := 0
    idx := 0
    last_id := fs.blocks[fs.last_fb]
    for idx < len(fs.blocks) {
        cur_id := fs.blocks[idx]
        if cur_id == last_id {
            bfs.last_fb = bfs_idx
        }
        block := Block{cur_id, 1, idx}
        idx += 1
        for idx < len(fs.blocks) && fs.blocks[idx] == cur_id {
            block.size += 1
            idx += 1
        }
        append(&bfs.blocks, block)
        bfs_idx += 1
    }
    return
}

collect_blockfs :: proc(bfs: ^BlockFilesystem) {
    file_id := bfs.blocks[bfs.last_fb].id
    main: for file_id != 0 {
        for idx := bfs.last_fb; idx > 0; idx -= 1 {
            if bfs.blocks[idx].id != file_id {
                continue
            }

            replace(bfs, idx)
            file_id -= 1
            continue main
        }
    }
}

replace :: proc(bfs: ^BlockFilesystem, index: int) -> bool {
    for idx in 0..<len(bfs.blocks) {
        if idx >= index {
            return false
        }
        if bfs.blocks[idx].id == -1 && bfs.blocks[idx].size >= bfs.blocks[index].size {
            block := bfs.blocks[index]
            empty_block(bfs, index)
            write_block(bfs, idx, block)
            coalesce(bfs)
            return true
        }
    }
    return false
}

pop_last_block_for_size :: proc(bfs: ^BlockFilesystem, size: int) -> (block: Block) {
    for idx := bfs.last_fb; idx > 0; idx -= 1 {
        if bfs.blocks[idx].id != -1 && bfs.blocks[idx].size <= size {
            block = bfs.blocks[idx]
            empty_block(bfs, idx)
            break
        }
    }
    if block.id == bfs.blocks[bfs.last_fb].id {
        for (bfs.blocks[bfs.last_fb].id == -1) {
            bfs.last_fb -= 1
        }
    }
    return
}

empty_block :: proc(bfs: ^BlockFilesystem, index: int) {
    bfs.blocks[index].id = -1
    raw_idx := bfs.blocks[index].index
    for idx in raw_idx..<raw_idx+bfs.blocks[index].size {
        bfs.raw.blocks[idx] = -1 
    }
}

coalesce :: proc(bfs: ^BlockFilesystem) {
    main: for {
        for idx in 0..<len(bfs.blocks)-1 {
            if bfs.blocks[idx].id != -1 {
                continue
            }
            if bfs.blocks[idx+1].id == -1 {
                bfs.blocks[idx].size += bfs.blocks[idx+1].size
                ordered_remove(&bfs.blocks, idx+1)
                if bfs.last_fb > idx {
                    bfs.last_fb -= 1
                }
                continue main
            }
        }
        break
    }
}

write_block :: proc(bfs: ^BlockFilesystem, idx: int, block: Block) {
    current_block := bfs.blocks[idx]
    raw_idx := current_block.index
    if current_block.size == block.size {
        bfs.blocks[idx] = block
    } else if bfs.blocks[idx+1].id == -1 {
        extra_size := bfs.blocks[idx].size - block.size
        bfs.blocks[idx+1].size += extra_size
        bfs.blocks[idx+1].index -= extra_size
        bfs.blocks[idx] = block
    } else {
        inject_at(&bfs.blocks, idx, block)
        next_block := bfs.blocks[idx+1]
        next_block.size -= block.size
        next_block.id = -1
        next_block.index += block.size
        bfs.blocks[idx+1] = next_block
        bfs.last_fb += 1
    }

    bfs.blocks[idx].index = raw_idx
    for idx in raw_idx..<raw_idx+block.size {
        bfs.raw.blocks[idx] = block.id
    }
}
