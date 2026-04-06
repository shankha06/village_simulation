## Inventory UI -- toggled with the "inventory" input action (I key).
## Displays all items the player owns, read from GameState "player.has_item.*" keys.
## Loads item definitions from data/items/items.json.
extends CanvasLayer

const _UITheme = preload("res://scenes/ui/ui_theme.gd")

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleBar/TitleLabel
@onready var close_button: Button = $Panel/VBox/TitleBar/CloseButton
@onready var item_grid: GridContainer = $Panel/VBox/ScrollContainer/ItemGrid
@onready var gold_label: Label = $Panel/VBox/GoldBar/GoldLabel
@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var tooltip_label: RichTextLabel = $TooltipPanel/TooltipLabel

# Item definitions loaded from JSON: {item_id: item_data}
var _item_defs: Dictionary = {}
var _is_open: bool = false

# Tooltip tracking
var _hovered_item_id: String = ""


func _ready() -> void:
	visible = false
	panel.visible = false
	tooltip_panel.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	close_button.pressed.connect(_close)

	# Load item definitions
	_load_item_data()


func _process(_delta: float) -> void:
	# Move tooltip to follow mouse when visible
	if tooltip_panel.visible:
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		tooltip_panel.position = mouse_pos + Vector2(12, 12)
		# Clamp to viewport
		var vp_size: Vector2 = get_viewport().get_visible_rect().size
		var tp_size: Vector2 = tooltip_panel.size
		if tooltip_panel.position.x + tp_size.x > vp_size.x:
			tooltip_panel.position.x = mouse_pos.x - tp_size.x - 4
		if tooltip_panel.position.y + tp_size.y > vp_size.y:
			tooltip_panel.position.y = mouse_pos.y - tp_size.y - 4


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_toggle()
		get_viewport().set_input_as_handled()
	elif _is_open and event.is_action_pressed("pause_menu"):
		_close()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	if _is_open:
		_close()
	else:
		_open()


func _open() -> void:
	_is_open = true
	visible = true
	panel.visible = true
	_populate_inventory()
	get_tree().paused = true


func _close() -> void:
	_is_open = false
	visible = false
	panel.visible = false
	tooltip_panel.visible = false
	_hovered_item_id = ""
	get_tree().paused = false


func _load_item_data() -> void:
	var file := FileAccess.open("res://data/items/items.json", FileAccess.READ)
	if file == null:
		push_warning("InventoryUI: Cannot open items.json")
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data: Dictionary = json.data
		var items: Array = data.get("items", [])
		for item in items:
			if item is Dictionary and item.has("id"):
				_item_defs[item.id] = item


func _populate_inventory() -> void:
	# Clear existing children
	for child in item_grid.get_children():
		child.queue_free()

	# Update gold display
	var gold: int = GameState.get_state("player.gold", 0) as int
	gold_label.text = "%d gold" % gold

	# Find all items the player has
	var item_keys: Array[String] = GameState.get_keys_with_prefix("player.has_item.")
	var found_items: Array[Dictionary] = []
	for key in item_keys:
		if GameState.get_state(key, false):
			var item_id: String = key.replace("player.has_item.", "")
			var item_def: Dictionary = _item_defs.get(item_id, {})
			if item_def.size() > 0:
				found_items.append(item_def)
			else:
				# Unknown item -- show with raw id
				found_items.append({"id": item_id, "name": item_id.capitalize().replace("_", " "), "description": "An unknown item.", "type": "MISC"})

	if found_items.size() == 0:
		var empty_label := Label.new()
		empty_label.text = "Your pockets are empty."
		empty_label.add_theme_font_size_override("font_size", 10)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.45, 1.0))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_grid.add_child(empty_label)
		return

	for item_data in found_items:
		_add_item_slot(item_data)


func _add_item_slot(item_data: Dictionary) -> void:
	var item_id: String = item_data.get("id", "")
	var item_name: String = item_data.get("name", "???")
	var item_type: String = item_data.get("type", "MISC")

	# Slot container
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(72, 84)

	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = Color(0.1, 0.08, 0.07, 0.9)
	slot_style.border_color = Color(0.3, 0.25, 0.18, 0.6)
	slot_style.border_width_left = 1
	slot_style.border_width_top = 1
	slot_style.border_width_right = 1
	slot_style.border_width_bottom = 1
	slot_style.set_corner_radius_all(3)
	slot_style.content_margin_left = 4.0
	slot_style.content_margin_right = 4.0
	slot_style.content_margin_top = 4.0
	slot_style.content_margin_bottom = 4.0
	slot.add_theme_stylebox_override("panel", slot_style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	slot.add_child(vbox)

	# Item icon
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Try to load icon from assets/sprites/items/
	var icon_path: String = "res://assets/sprites/items/%s.png" % item_id
	if ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
	else:
		# Fallback: colored rectangle placeholder
		var placeholder := ColorRect.new()
		placeholder.custom_minimum_size = Vector2(32, 32)
		match item_type:
			"CONSUMABLE":
				placeholder.color = Color(0.3, 0.5, 0.3, 0.8)
			"WEAPON":
				placeholder.color = Color(0.5, 0.3, 0.3, 0.8)
			"ARMOR":
				placeholder.color = Color(0.3, 0.3, 0.5, 0.8)
			"KEY_ITEM":
				placeholder.color = Color(0.5, 0.45, 0.2, 0.8)
			"LORE":
				placeholder.color = Color(0.4, 0.35, 0.5, 0.8)
			_:
				placeholder.color = Color(0.35, 0.35, 0.35, 0.8)
		vbox.add_child(placeholder)

	if icon_rect.texture:
		vbox.add_child(icon_rect)

	# Item name
	var name_label := Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65, 1.0))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = 64
	vbox.add_child(name_label)

	# Hover detection -- use mouse_entered/exited on the slot
	slot.mouse_entered.connect(_on_item_hover_entered.bind(item_id))
	slot.mouse_exited.connect(_on_item_hover_exited.bind(item_id))
	slot.mouse_filter = Control.MOUSE_FILTER_STOP

	item_grid.add_child(slot)


func _on_item_hover_entered(item_id: String) -> void:
	_hovered_item_id = item_id
	var item_data: Dictionary = _item_defs.get(item_id, {})
	var item_name: String = item_data.get("name", item_id.capitalize().replace("_", " "))
	var description: String = item_data.get("description", "")
	var item_type: String = item_data.get("type", "")
	var value: int = item_data.get("base_value", 0) as int

	var tooltip_text: String = "[b]%s[/b]" % item_name
	if item_type != "":
		tooltip_text += "\n[color=#8a7a5a]%s[/color]" % item_type.replace("_", " ")
	if description != "":
		tooltip_text += "\n%s" % description
	if value > 0:
		tooltip_text += "\n[color=#d4a824]Value: %d gold[/color]" % value

	tooltip_label.text = tooltip_text
	tooltip_panel.visible = true


func _on_item_hover_exited(_item_id: String) -> void:
	_hovered_item_id = ""
	tooltip_panel.visible = false
