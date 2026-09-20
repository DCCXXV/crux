package main

import rl "vendor:raylib"

GLYPH_SIZE :: 3

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
