package main

import rl "vendor:raylib"

SCALE :: 10
PITCH :: 4

BORDER :: 1
GAP :: 1
INSET :: BORDER + GAP

PLAY_W :: (COLS - 1) * PITCH + GLYPH_SIZE
PLAY_H :: (ROWS - 1) * PITCH + GLYPH_SIZE

CANVAS_W :: PLAY_W + INSET * 2
CANVAS_H :: PLAY_H + INSET * 2
WINDOW_W :: CANVAS_W * SCALE
WINDOW_H :: CANVAS_H * SCALE

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

		update(rl.GetFrameTime())

		rl.BeginTextureMode(canvas)
		rl.ClearBackground(rl.BLACK)

		rl.DrawRectangleLinesEx({0, 0, CANVAS_W, CANVAS_H}, BORDER, rl.WHITE)

		rl.DrawLine(1, 5, CANVAS_W - 1, 5, rl.Color{20, 20, 20, 255})

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
