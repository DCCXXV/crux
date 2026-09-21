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

parse_pattern :: proc "contextless" (rows: [GLYPH_SIZE]string) -> Pattern {
	p: Pattern
	for row, y in rows {
		for x in 0 ..< GLYPH_SIZE {
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

// odinfmt: disable
DICE_DIGITS := [COLS]Pattern {
	parse_pattern({
		"o o o",
		"o x o",
		"o o o",
	}),

	parse_pattern({
		"x o o",
		"o o o",
		"o o x",
	}),

	parse_pattern({
		"o o x",
		"o x o",
		"x o o",
	}),

	parse_pattern({
		"x o x",
		"o o o",
		"x o x",
	}),

	parse_pattern({
		"x o x",
		"o x o",
		"x o x",
	}),

	parse_pattern({
		"x o x",
		"x o x",
		"x o x",
	}),

	parse_pattern({
		"x o x",
		"x x x",
		"x o x",
	}),

	parse_pattern({
		"x x x",
		"x o x",
		"x x x",
	}),

	parse_pattern({
		"x x x",
		"x x x",
		"x x x",
	}),
}
// odinfmt: enable

DIGIT_W :: 3
DIGIT_H :: 5

Digit :: [DIGIT_H][DIGIT_W]bool

parse_digit :: proc "contextless" (rows: [DIGIT_H]string) -> Digit {
	d: Digit
	for row, y in rows {
		for x in 0 ..< DIGIT_W {
			d[y][x] = row[x * 2] == 'x'
		}
	}
	return d
}

// odinfmt: disable
DIGITS := [10]Digit {
	parse_digit({
		"x x x",
		"x o x",
		"x o x",
		"x o x",
		"x x x",
	}),

	parse_digit({
		"x x o",
		"o x o",
		"o x o",
		"o x o",
		"x x x",
	}),

	parse_digit({
		"x x x",
		"o o x",
		"x x x",
		"x o o",
		"x x x",
	}),

	parse_digit({
		"x x x",
		"o o x",
		"x x x",
		"o o x",
		"x x x",
	}),

	parse_digit({
		"x o x",
		"x o x",
		"x x x",
		"o o x",
		"o o x",
	}),

	parse_digit({
		"x x x",
		"x o o",
		"x x x",
		"o o x",
		"x x x",
	}),

	parse_digit({
		"x x x",
		"x o o",
		"x x x",
		"x o x",
		"x x x",
	}),

	parse_digit({
		"x x x",
		"o o x",
		"o o x",
		"o o x",
		"o o x",
	}),

	parse_digit({
		"x x x",
		"x o x",
		"x x x",
		"x o x",
		"x x x",
	}),

	parse_digit({
		"x x x",
		"x o x",
		"x x x",
		"o o x",
		"x x x",
	}),
}
