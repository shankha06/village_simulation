## PlayerStats — manages inventory, skills, and player progression.
## Works through GameState for persistence.
extends Node

# Inventory: Array of {item_id: String, quantity: int}
var _inventory: Array[Dictionary] = []

# Equipment slots
var _equipped: Dictionary = {
	"weapon": "",
	"armor": "",
	"accessory": "",
}


func _ready() -> void:
	pass


## Add an item to inventory.
func add_item(item_id: String, quantity: int = 1) -> void:
	# Check if item already exists and is stackable
	for entry in _inventory:
		if entry.item_id == item_id:
			entry.quantity += quantity
			_sync_to_state()
			return

	_inventory.append({"item_id": item_id, "quantity": quantity})
	GameState.set_state("player.has_item.%s" % item_id, true)
	_sync_to_state()


## Remove an item from inventory.
func remove_item(item_id: String, quantity: int = 1) -> bool:
	for i in range(_inventory.size()):
		if _inventory[i].item_id == item_id:
			_inventory[i].quantity -= quantity
			if _inventory[i].quantity <= 0:
				_inventory.remove_at(i)
				GameState.set_state("player.has_item.%s" % item_id, false)
			_sync_to_state()
			return true
	return false


## Check if player has an item.
func has_item(item_id: String, quantity: int = 1) -> bool:
	for entry in _inventory:
		if entry.item_id == item_id and entry.quantity >= quantity:
			return true
	return false


## Get item count.
func get_item_count(item_id: String) -> int:
	for entry in _inventory:
		if entry.item_id == item_id:
			return entry.quantity
	return 0


## Get full inventory.
func get_inventory() -> Array[Dictionary]:
	return _inventory


## Add gold.
func add_gold(amount: int) -> void:
	GameState.delta_state("player.gold", amount)


## Remove gold. Returns false if insufficient.
func remove_gold(amount: int) -> bool:
	var current: int = GameState.get_state("player.gold", 0)
	if current < amount:
		return false
	GameState.delta_state("player.gold", -amount)
	return true


## Get gold amount.
func get_gold() -> int:
	return GameState.get_state("player.gold", 0)


## Equip an item.
func equip(slot: String, item_id: String) -> void:
	if _equipped.has(slot):
		_equipped[slot] = item_id
		GameState.set_state("player.equipped.%s" % slot, item_id)


## Unequip an item.
func unequip(slot: String) -> String:
	var old: String = _equipped.get(slot, "")
	_equipped[slot] = ""
	GameState.set_state("player.equipped.%s" % slot, "")
	return old


## Get equipped item in a slot.
func get_equipped(slot: String) -> String:
	return _equipped.get(slot, "")


## Serialize for saving.
func serialize() -> Dictionary:
	return {
		"inventory": _inventory.duplicate(true),
		"equipped": _equipped.duplicate(),
	}


## Deserialize from save.
func deserialize(data: Dictionary) -> void:
	_inventory = data.get("inventory", [])
	_equipped = data.get("equipped", {"weapon": "", "armor": "", "accessory": ""})
	_sync_to_state()


func _sync_to_state() -> void:
	# Sync all item flags to GameState
	for entry in _inventory:
		GameState.set_state("player.has_item.%s" % entry.item_id, true)
