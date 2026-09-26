package main

import rl "vendor:raylib"

Scene :: enum {
	Menu,
	Game,
	Settings,
}

scene: Scene

Menu_Item :: enum {
	Play,
	Settings,
}

MENU_LABELS := [Menu_Item]cstring {
	.Play     = "PLAY",
	.Settings = "SETTINGS",
}

menu_selected: Menu_Item

BUTTON_PAD :: 1
BUTTON_H :: (BORDER + BUTTON_PAD) * 2 + FONT_CAP_H
BUTTON_GAP :: 3
BUTTONS_H :: len(Menu_Item) * BUTTON_H + (len(Menu_Item) - 1) * BUTTON_GAP
BUTTONS_Y :: (SCREEN_H - BUTTONS_H) / 2

text_width :: proc(text: cstring) -> int {
	w := 0
	x := 0
	for c in string(text) {
		i := rl.GetGlyphIndex(font, c)
		w = x + int(font.glyphs[i].offsetX) + int(font.recs[i].width)
		x += int(font.glyphs[i].advanceX) + FONT_SPACING
	}
	return w
}

button_width :: proc() -> int {
	w := 0
	for label in MENU_LABELS do w = max(w, text_width(label))
	return w + (BORDER + BUTTON_PAD) * 2
}

button_rect :: proc(item: Menu_Item) -> rl.Rectangle {
	w := button_width()
	x := (SCREEN_W - w) / 2
	y := BUTTONS_Y + int(item) * (BUTTON_H + BUTTON_GAP)
	return {f32(x), f32(y), f32(w), BUTTON_H}
}

activate_menu_item :: proc(item: Menu_Item) {
	switch item {
	case .Play:
		clear_board()
		scene = .Game
	case .Settings:
		scene = .Settings
	}
}

update_menu :: proc(mouse: rl.Vector2) {
	if rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W) {
		menu_selected = Menu_Item((int(menu_selected) + len(Menu_Item) - 1) % len(Menu_Item))
	}
	if rl.IsKeyPressed(.DOWN) || rl.IsKeyPressed(.S) {
		menu_selected = Menu_Item((int(menu_selected) + 1) % len(Menu_Item))
	}
	if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
		activate_menu_item(menu_selected)
		return
	}

	for item in Menu_Item {
		if !rl.CheckCollisionPointRec(mouse, button_rect(item)) do continue
		if rl.GetMouseDelta() != {} do menu_selected = item
		if rl.IsMouseButtonPressed(.LEFT) {
			menu_selected = item
			activate_menu_item(item)
		}
	}
}

draw_menu :: proc() {
	for item in Menu_Item {
		rect := button_rect(item)
		fg, bg := rl.WHITE, rl.BLACK
		if item == menu_selected do fg, bg = bg, fg

		rl.DrawRectangleRec(rect, bg)
		rl.DrawRectangleLinesEx(rect, BORDER, rl.WHITE)

		label := MENU_LABELS[item]
		x := int(rect.x) + (int(rect.width) - text_width(label)) / 2
		y := int(rect.y) + (BUTTON_H - FONT_CAP_H) / 2 - FONT_CAP_TOP
		rl.DrawTextEx(font, label, {f32(x), f32(y)}, FONT_SIZE, FONT_SPACING, fg)
	}
}
