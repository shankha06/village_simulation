## UI Theme — generates a professional dark fantasy Theme resource.
## Called from main.gd to style all UI elements consistently.
extends RefCounted
class_name UITheme

# Dark fantasy color palette
const PANEL_BG := Color(0.08, 0.05, 0.04, 0.92)
const PANEL_BORDER := Color(0.855, 0.69, 0.28, 1.0)  # Gold
const TEXT_PRIMARY := Color(0.91, 0.88, 0.82, 1.0)  # Parchment
const TEXT_SECONDARY := Color(0.66, 0.64, 0.58, 1.0)  # Muted
const TEXT_SPEAKER := Color(0.9, 0.75, 0.4, 1.0)  # Gold
const BUTTON_BG := Color(0.12, 0.08, 0.06, 0.85)
const BUTTON_HOVER := Color(0.18, 0.12, 0.08, 0.95)
const BUTTON_PRESSED := Color(0.22, 0.15, 0.10, 1.0)
const ACCENT_RED := Color(0.67, 0.2, 0.2)
const ACCENT_GREEN := Color(0.4, 0.55, 0.33)
const HEALTH_RED := Color(0.7, 0.15, 0.12)
const HEALTH_BG := Color(0.2, 0.1, 0.08)


static func create_theme() -> Theme:
	var theme := Theme.new()

	# --- Panel ---
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL_BG
	panel_style.border_color = PANEL_BORDER
	panel_style.border_width_bottom = 2
	panel_style.border_width_top = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	# --- Button Normal ---
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = BUTTON_BG
	btn_normal.border_color = Color(0.4, 0.35, 0.25, 0.6)
	btn_normal.border_width_left = 3
	btn_normal.border_width_bottom = 1
	btn_normal.border_width_top = 1
	btn_normal.border_width_right = 1
	btn_normal.corner_radius_top_left = 2
	btn_normal.corner_radius_top_right = 2
	btn_normal.corner_radius_bottom_left = 2
	btn_normal.corner_radius_bottom_right = 2
	btn_normal.content_margin_left = 12
	btn_normal.content_margin_right = 8
	btn_normal.content_margin_top = 6
	btn_normal.content_margin_bottom = 6
	theme.set_stylebox("normal", "Button", btn_normal)

	# --- Button Hover ---
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = BUTTON_HOVER
	btn_hover.border_color = PANEL_BORDER
	btn_hover.border_width_left = 3
	btn_hover.border_width_bottom = 1
	btn_hover.border_width_top = 1
	btn_hover.border_width_right = 1
	btn_hover.corner_radius_top_left = 2
	btn_hover.corner_radius_top_right = 2
	btn_hover.corner_radius_bottom_left = 2
	btn_hover.corner_radius_bottom_right = 2
	btn_hover.content_margin_left = 12
	btn_hover.content_margin_right = 8
	btn_hover.content_margin_top = 6
	btn_hover.content_margin_bottom = 6
	theme.set_stylebox("hover", "Button", btn_hover)

	# --- Button Pressed ---
	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = BUTTON_PRESSED
	btn_pressed.border_color = PANEL_BORDER
	btn_pressed.border_width_left = 3
	btn_pressed.border_width_bottom = 1
	btn_pressed.border_width_top = 1
	btn_pressed.border_width_right = 1
	btn_pressed.corner_radius_top_left = 2
	btn_pressed.corner_radius_top_right = 2
	btn_pressed.corner_radius_bottom_left = 2
	btn_pressed.corner_radius_bottom_right = 2
	btn_pressed.content_margin_left = 12
	btn_pressed.content_margin_right = 8
	btn_pressed.content_margin_top = 6
	btn_pressed.content_margin_bottom = 6
	theme.set_stylebox("pressed", "Button", btn_pressed)

	# --- Button Focus ---
	var btn_focus := StyleBoxFlat.new()
	btn_focus.bg_color = BUTTON_HOVER
	btn_focus.border_color = PANEL_BORDER
	btn_focus.border_width_left = 3
	btn_focus.border_width_bottom = 1
	btn_focus.border_width_top = 1
	btn_focus.border_width_right = 1
	btn_focus.corner_radius_top_left = 2
	btn_focus.corner_radius_top_right = 2
	btn_focus.corner_radius_bottom_left = 2
	btn_focus.corner_radius_bottom_right = 2
	btn_focus.content_margin_left = 12
	btn_focus.content_margin_right = 8
	btn_focus.content_margin_top = 6
	btn_focus.content_margin_bottom = 6
	theme.set_stylebox("focus", "Button", btn_focus)

	# --- Label Colors ---
	theme.set_color("font_color", "Label", TEXT_PRIMARY)
	theme.set_color("font_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", PANEL_BORDER)
	theme.set_color("font_focus_color", "Button", PANEL_BORDER)
	theme.set_color("font_pressed_color", "Button", TEXT_SPEAKER)

	# --- Font Sizes ---
	theme.set_font_size("font_size", "Label", 13)
	theme.set_font_size("font_size", "Button", 12)
	theme.set_font_size("font_size", "RichTextLabel", 13)

	# --- ProgressBar (health) ---
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = HEALTH_BG
	pb_bg.corner_radius_top_left = 2
	pb_bg.corner_radius_top_right = 2
	pb_bg.corner_radius_bottom_left = 2
	pb_bg.corner_radius_bottom_right = 2
	theme.set_stylebox("background", "ProgressBar", pb_bg)

	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = HEALTH_RED
	pb_fill.corner_radius_top_left = 2
	pb_fill.corner_radius_top_right = 2
	pb_fill.corner_radius_bottom_left = 2
	pb_fill.corner_radius_bottom_right = 2
	theme.set_stylebox("fill", "ProgressBar", pb_fill)

	# --- RichTextLabel ---
	theme.set_color("default_color", "RichTextLabel", TEXT_PRIMARY)

	return theme
