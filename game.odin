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

game_over: bool
current_score: int
highscore: int

clear_board :: proc() {
	for row in 0 ..< ROWS {
		for col in 0 ..< COLS {
			board[row][col] = .Empty
		}
	}
	game_over = false
	current_score = 0
	spawn_piece()
}

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

clear_matches :: proc() {
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
	if match_count > 0 do play_break_sound()
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

glyph_size :: proc(g: Glyph) -> int {
	n := 0
	for row in PATTERNS[g] {
		for on in row {
			if on do n += 1
		}
	}
	return n
}

score_matches :: proc() -> int {
	total := 1
	for i in 0 ..< match_count {
		total *= glyph_size(matches_found[i].glyph)
	}
	return total
}

resolve :: proc() {
	combo := 1
	cleared := false
	for _ in 0 ..< 16 {
		scan({.Cross, .BigO, .Plus, .House})
		if match_count == 0 do break
		combo *= score_matches()
		cleared = true
		clear_matches()
		apply_gravity()
	}
	if cleared do current_score += combo
}

random_glyph :: proc() -> Glyph {
	return Glyph(1 + rand.int_max(len(Glyph) - 1))
}

piece_col: int
piece_row: int
piece_glyph: Glyph

next_piece_glyph := Glyph.Empty

fall_timer: f32
FALL_INTERVAL :: 0.4

SPAWN_GRACE :: 0.5

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

	if (next_piece_glyph == .Empty) do next_piece_glyph = random_glyph()
	piece_glyph = next_piece_glyph
	next_piece_glyph = random_glyph()

	fall_timer = -SPAWN_GRACE
}

hard_drop :: proc() {
	if board[piece_row][piece_col] != .Empty do return
	for piece_row + 1 < ROWS && board[piece_row + 1][piece_col] == .Empty {
		piece_row += 1
	}
	lock_piece()
}

lock_piece :: proc() {
	if board[piece_row][piece_col] != .Empty {
		game_over = true
		return
	}

	if piece_row > 0 do play_place_sound(piece_col)
	board[piece_row][piece_col] = piece_glyph
	resolve()

	for col in 0 ..< COLS {
		if board[0][col] != .Empty {
			play_game_over_sound()
			game_over = true
			return
		}
	}

	spawn_piece()
}

paused: bool

update :: proc(dt: f32) {
	if game_over {
		if current_score > highscore {
			highscore = current_score
			save_highscore(highscore)
		}
		if rl.GetKeyPressed() != .KEY_NULL do clear_board()
		return
	}

	if rl.IsKeyPressed(.M) {
		if rl.GetMasterVolume() == 0 {
			rl.SetMasterVolume(0.8)
		} else {
			rl.SetMasterVolume(0)
		}
	}

	/*
	if rl.IsKeyPressed(.P) {
		paused = !paused
		if !paused {
			move_left = {}
			move_right = {}
			soft_drop = {}
		}	
	}
	*/

	if rl.IsKeyPressed(.R) do clear_board()

	if paused do return

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
			if board[piece_row][k] != .Empty do continue
			piece_col = k
			hard_drop()
		}
	}

	fall_timer += dt
	if fall_timer >= FALL_INTERVAL {
		fall_timer = 0
		if piece_row + 1 >= ROWS || board[piece_row + 1][piece_col] != .Empty {
			lock_piece()
		} else {
			piece_row += 1
		}
	}
}
