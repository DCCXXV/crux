package main

import "core:math/rand"
import rl "vendor:raylib"

SCALE :: 10
PITCH :: 4
COLS :: 9
ROWS :: 10

BORDER :: 1
GAP :: 1
INSET :: BORDER + GAP

GLYPH :: 3

PLAY_W :: (COLS - 1) * PITCH + GLYPH
PLAY_H :: (ROWS - 1) * PITCH + GLYPH

CANVAS_W :: PLAY_W + INSET * 2
CANVAS_H :: PLAY_H + INSET * 2
WINDOW_W :: CANVAS_W * SCALE
WINDOW_H :: CANVAS_H * SCALE

Glyph :: enum {
	Empty,
	Cross,
	BigO,
	Plus,
	House,
}

Pattern :: [3][3]bool

parse_pattern :: proc "contextless" (rows: [3]string) -> Pattern {
	p: Pattern
	for row, y in rows {
		for x in 0 ..< 3 {
			p[y][x] = row[x * 2] == 'x'
		}
	}
	return p
}

// odinfmt: disable
PATTERNS := [Glyph]Pattern {
	.Empty = {},

	.Cross = parse_pattern({
		"x o x",
		"o x o",
		"x o x",
	}),

	.BigO = parse_pattern({
		"x x x",
		"x o x",
		"x x x",		
	}),

	.Plus = parse_pattern({
		"o x o",
		"x x x",
		"o x o",
	}),

	.House = parse_pattern({
		"o x o",
		"x o x",
		"x x x",
	}),
}
// odinfmt: enable

COLORS := [Glyph]rl.Color {
	.Empty = {0, 0, 0, 255},
	.Cross = {255, 0, 0, 255},
	.BigO  = {0, 0, 255, 255},
	.Plus  = {0, 255, 0, 255},
	.House = {255, 255, 0, 255},
}

Board :: [ROWS][COLS]Glyph
board: Board

draw_cell :: proc(row, col: int, g: Glyph) {
	if g == .Empty do return
	pattern := PATTERNS[g]
	color := COLORS[g]
	for y in 0 ..< 3 {
		for x in 0 ..< 3 {
			if !pattern[y][x] do continue
			px := INSET + col * PITCH + x
			py := INSET + row * PITCH + y
			rl.DrawPixel(i32(px), i32(py), color)
		}
	}
}

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

resolve :: proc() {
	for _ in 0 ..< 16 {
		scan({.Cross, .BigO, .Plus, .House})
		if match_count == 0 do break
		clear()
		apply_gravity()
	}
}

main :: proc() {

	rl.InitWindow(WINDOW_W, WINDOW_H, "xolz")
	rl.SetTargetFPS(60)

	canvas := rl.LoadRenderTexture(CANVAS_W, CANVAS_H)
	rl.SetTextureFilter(canvas.texture, .POINT)

	src := rl.Rectangle{0, 0, CANVAS_W, -CANVAS_H}
	dst := rl.Rectangle{0, 0, WINDOW_W, WINDOW_H}

	spawn_piece()
	for !rl.WindowShouldClose() {
		/*
		if rl.IsMouseButtonPressed(.LEFT) {
			mx := (int(rl.GetMouseX()) / SCALE - INSET) / PITCH
			my := (int(rl.GetMouseY()) / SCALE - INSET) / PITCH
			if mx >= 0 && mx < COLS && my >= 0 && my < ROWS {
				g := board[my][mx]
				board[my][mx] = Glyph((int(g) + 1) % len(Glyph))
			}
		}
		*/

		dt := rl.GetFrameTime()

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

		rl.BeginTextureMode(canvas)
		rl.ClearBackground(rl.BLACK)

		rl.DrawRectangleLinesEx({0, 0, CANVAS_W, CANVAS_H}, BORDER, rl.WHITE)

		rl.DrawLine(1, 5, CANVAS_W-1, 5, rl.Color{20, 20, 20, 255})

		draw_cell(piece_row, piece_col, piece_glyph)

		for row in 0 ..< ROWS {
			for col in 0 ..< COLS {
				draw_cell(row, col, board[row][col])
			}
		}

		rl.EndTextureMode()

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexturePro(canvas.texture, src, dst, {0, 0}, 0, rl.WHITE)
		rl.EndDrawing()
	}

	rl.UnloadRenderTexture(canvas)
	rl.CloseWindow()
}
