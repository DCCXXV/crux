package main

import "core:os"
import "core:strconv"
import rl "vendor:raylib"

SCALE :: 10
PITCH :: 4

BORDER :: 1
GAP :: 1
INSET :: BORDER + GAP

PLAY_W :: (COLS - 1) * PITCH + GLYPH_SIZE
PLAY_H :: (ROWS - 1) * PITCH + GLYPH_SIZE

BOARD_W :: PLAY_W + INSET * 2
BOARD_H :: PLAY_H + INSET * 2

LABEL_H :: GAP + GLYPH_SIZE + GAP
LABEL_Y :: BOARD_H + GAP

DIGIT_GAP :: 1
SCORE_DIGITS :: 3
SCORE_W :: SCORE_DIGITS * DIGIT_W + (SCORE_DIGITS - 1) * DIGIT_GAP

HIGHSCORE_PAD :: 1
HIGHSCORE_BOX_W :: SCORE_W + HIGHSCORE_PAD * 2
HIGHSCORE_BOX_H :: DIGIT_H + HIGHSCORE_PAD * 2
HIGHSCORE_BOX_X :: BOARD_W + GAP
HIGHSCORE_BOX_Y :: GAP
HIGHSCORE_X :: HIGHSCORE_BOX_X + HIGHSCORE_PAD
HIGHSCORE_Y :: HIGHSCORE_BOX_Y + HIGHSCORE_PAD

SCORE_GAP :: 3
SCORE_X :: HIGHSCORE_X
SCORE_Y :: HIGHSCORE_BOX_Y + HIGHSCORE_BOX_H + SCORE_GAP

PANEL_W :: GAP + HIGHSCORE_BOX_W + GAP

CANVAS_W :: BOARD_W + PANEL_W
CANVAS_H :: BOARD_H + LABEL_H + BORDER
WINDOW_W :: CANVAS_W * SCALE
WINDOW_H :: CANVAS_H * SCALE

highscore_path :: proc() -> string {
	dir, _ := os.user_data_dir(context.temp_allocator)
	dir, _ = os.join_path({dir, "xolz"}, context.temp_allocator)
	os.make_directory_all(dir)
	path, _ := os.join_path({dir, "highscore"}, context.temp_allocator)
	return path
}

load_highscore :: proc() -> int {
	data, err := os.read_entire_file(highscore_path(), context.temp_allocator)
	if err != nil do return 0
	n, _ := strconv.parse_int(string(data))
	return n
}

save_highscore :: proc(n: int) {
	buf: [32]u8
	_ = os.write_entire_file(highscore_path(), strconv.write_int(buf[:], i64(n), 10))
}

draw_pattern :: proc(px, py: int, pattern: Pattern, color: rl.Color) {
	for y in 0 ..< GLYPH_SIZE {
		for x in 0 ..< GLYPH_SIZE {
			if !pattern[y][x] do continue
			rl.DrawPixel(i32(px + x), i32(py + y), color)
		}
	}
}

draw_cell :: proc(row, col: int, g: Glyph) {
	if g == .Empty do return
	draw_pattern(INSET + col * PITCH, INSET + row * PITCH, PATTERNS[g], COLORS[g])
}

draw_digit :: proc(px, py: int, digit: Digit, color: rl.Color) {
	for y in 0 ..< DIGIT_H {
		for x in 0 ..< DIGIT_W {
			if !digit[y][x] do continue
			rl.DrawPixel(i32(px + x), i32(py + y), color)
		}
	}
}

draw_digits :: proc(px, py: int, value: int, color: rl.Color) {
	n := value
	for i := SCORE_DIGITS - 1; i >= 0; i -= 1 {
		draw_digit(px + i * (DIGIT_W + DIGIT_GAP), py, DIGITS[n % 10], color)
		n /= 10
	}
}

draw_score :: proc(score: int) {
	draw_digits(SCORE_X, SCORE_Y, score, rl.WHITE)
}

draw_highscore :: proc(score: int) {
	rl.DrawRectangle(HIGHSCORE_BOX_X, HIGHSCORE_BOX_Y, HIGHSCORE_BOX_W, HIGHSCORE_BOX_H, rl.WHITE)
	draw_digits(HIGHSCORE_X, HIGHSCORE_Y, score, rl.BLACK)
}

main :: proc() {
	rl.InitWindow(WINDOW_W, WINDOW_H, "xolz")
	rl.SetTargetFPS(60)

	canvas := rl.LoadRenderTexture(CANVAS_W, CANVAS_H)
	rl.SetTextureFilter(canvas.texture, .POINT)

	src := rl.Rectangle{0, 0, CANVAS_W, -CANVAS_H}
	dst := rl.Rectangle{0, 0, WINDOW_W, WINDOW_H}

	highscore = load_highscore()
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

		update(rl.GetFrameTime())

		rl.BeginTextureMode(canvas)
		rl.ClearBackground(rl.BLACK)

		rl.DrawRectangleLinesEx({0, 0, BOARD_W, CANVAS_H}, BORDER, rl.WHITE)
		rl.DrawLine(0, BOARD_H - 1, BOARD_W, BOARD_H - 1, rl.WHITE)

		for col in 0 ..< COLS {
			draw_pattern(INSET + col * PITCH, LABEL_Y, DICE_DIGITS[col], rl.WHITE)
		}

		draw_score(current_score)
		draw_highscore(highscore)

		rl.DrawLine(1, 5, BOARD_W - 1, 5, rl.Color{20, 20, 20, 255})

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
