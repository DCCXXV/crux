package main

import rl "vendor:raylib"

FONT_TTF :: #load("font/Micro5-Regular.ttf")
FONT_SIZE :: 11
FONT_SPACING :: 0
FONT_CAP_TOP :: 2
FONT_CAP_H :: 5
font: rl.Font

load_font :: proc() {
	font = rl.LoadFontFromMemory(".ttf", raw_data(FONT_TTF), i32(len(FONT_TTF)), FONT_SIZE, nil, 0)
	rl.SetTextureFilter(font.texture, .POINT)
}
