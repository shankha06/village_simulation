## PlayerCombat — component script attached to the player for combat mechanics.
## Handles attacks, dodging, damage, and hitbox creation.
## Reads weapon damage from GameState ("player.equipped.weapon").
## Designed to be a child node of the player CharacterBody2D.
extends Node2D

signal attack_started
signal attack_ended
signal dodge_started
signal dodge_ended
signal hit_taken(amount: float, source: String)
signal died

# Animation states (tracked here for combat layer; player.gd owns movement states)
enum CombatState { IDLE, ATTACKING, DODGING, HIT_STUN, DEAD }
var combat_state: CombatState = CombatState.IDLE

# Dodge tuning
const DODGE_DURATION: float = 0.3
const DODGE_COOLDOWN: float = 0.8

# Attack tuning
const ATTACK_DURATION: float = 0.25
const ATTACK_HITBOX_SIZE: Vector2 = Vector2(20.0, 14.0)
const ATTACK_HITBOX_OFFSET: float = 16.0
const HIT_STUN_DURATION: float = 0.2

# Unarmed / fallback damage
const UNARMED_DAMAGE: float = 3.0

# Weapon damage lookup: item_id -> base damage.
# In a full implementation this would come from ItemData resources.
# CombatManager or an item database can override via set_weapon_table().
var _weapon_damage_table: Dictionary = {
	"": UNARMED_DAMAGE,
	"fists": UNARMED_DAMAGE,
	"rusty_sword": 8.0,
	"iron_sword": 12.0,
	"silver_blade": 18.0,
	"woodcutter_axe": 10.0,
	"hunting_knife": 6.0,
}

# Internal timers
var _attack_timer: float = 0.0
var _dodge_timer: float = 0.0
var _dodge_cooldown_timer: float = 0.0
var _hit_stun_timer: float = 0.0

# References
var _player: CharacterBody2D = null
var _active_hitbox: Area2D = null

# I-frame tracking (true while dodging — enemy attacks pass through)
var is_invincible: bool = false


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	if _player == null:
		push_warning("PlayerCombat: must be a child of a CharacterBody2D (the player).")


func _physics_process(delta: float) -> void:
	match combat_state:
		CombatState.ATTACKING:
			_process_attack(delta)
		CombatState.DODGING:
			_process_dodge(delta)
		CombatState.HIT_STUN:
			_process_hit_stun(delta)
		CombatState.DEAD:
			return
		_:
			pass

	# Tick dodge cooldown regardless of state
	if _dodge_cooldown_timer > 0.0:
		_dodge_cooldown_timer -= delta


## Initiate a melee attack. Returns true if the attack started.
func attack() -> bool:
	if combat_state != CombatState.IDLE:
		return false
	if _player == null:
		return false

	combat_state = CombatState.ATTACKING
	_attack_timer = ATTACK_DURATION

	_create_attack_hitbox()
	attack_started.emit()
	return true


## Initiate a dodge roll with i-frames. Returns true if dodge started.
func dodge() -> bool:
	if combat_state != CombatState.IDLE:
		return false
	if _dodge_cooldown_timer > 0.0:
		return false

	combat_state = CombatState.DODGING
	_dodge_timer = DODGE_DURATION
	_dodge_cooldown_timer = DODGE_COOLDOWN
	is_invincible = true

	dodge_started.emit()
	return true


## Apply damage to the player from an external source.
func take_damage(amount: float, source: String = "") -> void:
	if combat_state == CombatState.DEAD:
		return
	if is_invincible:
		return  # Dodging — i-frames active

	# Apply defense reduction from armor
	var armor_id: String = GameState.get_state("player.equipped.armor", "")
	var defense: float = _get_armor_defense(armor_id)
	var final_damage: float = maxf(amount - defense, 1.0)

	# Reduce health through GameState
	var health: float = GameState.get_state("player.health", 100.0)
	health -= final_damage
	GameState.set_state("player.health", maxf(health, 0.0))

	EventBus.player_took_damage.emit(final_damage, source)
	hit_taken.emit(final_damage, source)

	if health <= 0.0:
		_die()
		return

	# Enter hit stun (brief flinch)
	combat_state = CombatState.HIT_STUN
	_hit_stun_timer = HIT_STUN_DURATION

	# Spawn damage number
	_spawn_damage_number(final_damage, false)


## Get current weapon damage from GameState + weapon table.
func get_weapon_damage() -> float:
	var weapon_id: String = GameState.get_state("player.equipped.weapon", "")
	return _weapon_damage_table.get(weapon_id, UNARMED_DAMAGE)


## Allow external systems to register weapon damage values.
func register_weapon_damage(weapon_id: String, damage: float) -> void:
	_weapon_damage_table[weapon_id] = damage


## Whether this component considers the player in an active combat animation.
func is_busy() -> bool:
	return combat_state != CombatState.IDLE


# --- Internal ---

func _process_attack(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_end_attack()


func _process_dodge(delta: float) -> void:
	_dodge_timer -= delta
	if _dodge_timer <= 0.0:
		is_invincible = false
		combat_state = CombatState.IDLE
		dodge_ended.emit()


func _process_hit_stun(delta: float) -> void:
	_hit_stun_timer -= delta
	if _hit_stun_timer <= 0.0:
		combat_state = CombatState.IDLE


func _create_attack_hitbox() -> void:
	if _player == null:
		return

	# Determine facing direction from the player
	var facing: Vector2 = _player.facing_direction if "facing_direction" in _player else Vector2.DOWN

	# Create a temporary Area2D as the hitbox
	var hitbox := Area2D.new()
	hitbox.name = "AttackHitbox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 4  # Layer 3: enemies / NPCs
	hitbox.monitoring = true
	hitbox.monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = ATTACK_HITBOX_SIZE
	shape.shape = rect
	hitbox.add_child(shape)

	# Position in facing direction
	hitbox.position = facing.normalized() * ATTACK_HITBOX_OFFSET

	_player.add_child(hitbox)
	_active_hitbox = hitbox

	# Connect to detect hits
	hitbox.area_entered.connect(_on_attack_hit_area)
	hitbox.body_entered.connect(_on_attack_hit_body)


func _end_attack() -> void:
	combat_state = CombatState.IDLE

	# Remove the temporary hitbox
	if _active_hitbox and is_instance_valid(_active_hitbox):
		_active_hitbox.queue_free()
		_active_hitbox = null

	attack_ended.emit()


func _on_attack_hit_area(area: Area2D) -> void:
	_deal_damage_to(area.get_parent())


func _on_attack_hit_body(body: Node2D) -> void:
	_deal_damage_to(body)


func _deal_damage_to(target: Node) -> void:
	if target == null or target == _player:
		return
	if not target.has_method("take_damage"):
		return

	var damage: float = get_weapon_damage()
	target.take_damage(damage, "player")

	# Spawn damage number at target position
	if target is Node2D:
		_spawn_damage_number_at(damage, target.global_position, false)


func _die() -> void:
	combat_state = CombatState.DEAD
	is_invincible = false
	died.emit()
	# Player death is handled by player.gd through EventBus.player_died


func _get_armor_defense(armor_id: String) -> float:
	# Armor defense lookup — mirrors weapon table approach
	# In full implementation, read from ItemData resources
	if armor_id == "" or armor_id == "none":
		return 0.0
	# Placeholder: read from GameState if set externally
	var defense_key: String = "item.%s.defense" % armor_id
	return GameState.get_state(defense_key, 0.0)


func _spawn_damage_number(amount: float, is_heal: bool) -> void:
	if _player == null:
		return
	_spawn_damage_number_at(amount, _player.global_position + Vector2(0, -8), is_heal)


func _spawn_damage_number_at(amount: float, pos: Vector2, is_heal: bool) -> void:
	# Load the damage number scene/script
	var dmg_label := preload("res://scenes/combat/damage_number.gd").new()
	dmg_label.setup(amount, pos, is_heal)
	# Add to the scene tree at root level so it doesn't move with the target
	var tree: SceneTree = get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(dmg_label)
