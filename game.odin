package main

import "core:math/rand"
import rl "vendor:raylib"

COLS :: 9
ROWS :: 10

Board :: [ROWS][COLS]Glyph
board: Board

Match :: struct {
	row, col: int,
	glyph:    Glyph,
}

matches_found: [49]Match
match_count: int

matches :: proc(row, col: int, g: Glyph) -> bool {
	pattern := PATTERNS[g]
	for dy in 0 ..< 3 {
		for dx in 0 ..< 3 {
			cell := board[row + dy][col + dx]
			if pattern[dy][dx] {
				if cell != g do return false
			}
		}
	}
	return true
}

scan :: proc(active: []Glyph) {
	for row in 0 ..= ROWS - 3 {
		for col in 0 ..= COLS - 3 {
			for g in active {
				if matches(row, col, g) {
					matches_found[match_count] = Match{row, col, g}
					match_count += 1
				}
			}
		}
	}
}

clear :: proc() {
	for i in 0 ..< match_count {
		m := matches_found[i]
		pattern := PATTERNS[m.glyph]
		for dy in 0 ..< 3 {
			for dx in 0 ..< 3 {
				if pattern[dy][dx] {
					board[m.row + dy][m.col + dx] = .Empty
				}
			}
		}
	}
	match_count = 0
}

apply_gravity :: proc() {
	for col in 0 ..< COLS {
		write := ROWS - 1
		for row := ROWS - 1; row >= 0; row -= 1 {
			if board[row][col] != .Empty {
				board[write][col] = board[row][col]
				if write != row do board[row][col] = .Empty
				write -= 1
			}
		}
	}
}

resolve :: proc() {
	for _ in 0 ..< 16 {
		scan({.Cross, .BigO, .Plus, .House})
		if match_count == 0 do break
		clear()
		apply_gravity()
	}
}

random_glyph :: proc() -> Glyph {
	return Glyph(1 + rand.int_max(len(Glyph) - 1))
}

piece_col: int
piece_row: int
piece_glyph: Glyph

fall_timer: f32
FALL_INTERVAL :: 0.4

DAS_DELAY :: 0.16
DAS_RATE :: 0.04

Repeater :: struct {
	held:  bool,
	timer: f32,
}

repeat_steps :: proc(r: ^Repeater, down: bool, dt: f32) -> int {
	if !down {
		r.held = false
		return 0
	}
	if !r.held {
		r.held = true
		r.timer = DAS_DELAY
		return 1
	}
	r.timer -= dt
	steps := 0
	for r.timer <= 0 {
		r.timer += DAS_RATE
		steps += 1
	}
	return steps
}

move_left: Repeater
move_right: Repeater
soft_drop: Repeater

spawn_piece :: proc() {
	piece_col = rand.int_max(COLS)
	piece_row = 0
	piece_glyph = random_glyph()
}

hard_drop :: proc() {
	for piece_row + 1 < ROWS && board[piece_row + 1][piece_col] == .Empty {
		piece_row += 1
	}
	board[piece_row][piece_col] = piece_glyph
	resolve()
	spawn_piece()
	fall_timer = 0
}

update :: proc(dt: f32) {
	if rl.IsKeyPressed(.SPACE) do hard_drop()

	for _ in 0 ..< repeat_steps(&move_left, rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A), dt) {
		if piece_col > 0 && board[piece_row][piece_col - 1] == .Empty do piece_col -= 1
	}
	for _ in 0 ..< repeat_steps(&move_right, rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D), dt) {
		if piece_col < COLS - 1 && board[piece_row][piece_col + 1] == .Empty do piece_col += 1
	}
	for _ in 0 ..< repeat_steps(&soft_drop, rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S), dt) {
		if piece_row + 1 < ROWS && board[piece_row + 1][piece_col] == .Empty {
			piece_row += 1
			fall_timer = 0
		}
	}

	for k in 0 ..< COLS {
		if rl.IsKeyPressed(rl.KeyboardKey(int(rl.KeyboardKey.ONE) + k)) {
			piece_col = k
			hard_drop()
		}
	}

	fall_timer += dt
	if fall_timer >= FALL_INTERVAL {
		fall_timer = 0
		if piece_row + 1 >= ROWS || board[piece_row + 1][piece_col] != .Empty {
			board[piece_row][piece_col] = piece_glyph
			resolve()
			spawn_piece()
		} else {
			piece_row += 1
		}
	}
}
