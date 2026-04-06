## ItemData — resource defining an item's properties.
class_name ItemData
extends Resource

enum ItemType { CONSUMABLE, WEAPON, ARMOR, KEY_ITEM, LORE, TOOL }

@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var icon: Texture2D
@export var base_value: int = 0
@export var stackable: bool = true
@export var max_stack: int = 99

# Effects when used
@export_group("Effects")
@export var heal_amount: float = 0.0
@export var damage_amount: float = 0.0
@export var state_effects: Dictionary = {}  # {state_key: value} to set on use

# Equipment stats
@export_group("Equipment")
@export var equip_slot: String = ""  # "weapon", "armor", "accessory"
@export var attack_bonus: float = 0.0
@export var defense_bonus: float = 0.0

# Lore/key item
@export_group("Story")
@export var codex_entry: String = ""  # Unlocks this codex entry when picked up
@export var is_quest_item: bool = false
