## Player controller — handles movement, interaction, and state management.
extends CharacterBody2D

const SPEED: float = 80.0
const DODGE_SPEED: float = 200.0
const DODGE_DURATION: float = 0.3
const DODGE_COOLDOWN: float = 0.8

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var interaction_area: Area2D = $InteractionArea

# State machine
enum State { IDLE, MOVING, DODGING, ATTACKING, INTERACTING, DEAD }
var current_state: State = State.IDLE

# Direction tracking
var facing_direction: Vector2 = Vector2.DOWN
var _dodge_timer: float = 0.0
var _dodge_cooldown_timer: float = 0.0
var _dodge_direction: Vector2 = Vector2.ZERO

# Interaction
var _nearby_interactables: Array[Node] = []
var _interact_timeout: float = 0.0

# Footstep audio
const FOOTSTEP_INTERVAL: float = 0.3
var _footstep_timer: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_setup_visual()
	_sync_position_to_state()


func _setup_visual() -> void:
	if not animated_sprite:
		return

	var idle_tex: Texture2D = load("res://assets/sprites/player/player_idle.png")
	var walk_tex: Texture2D = load("res://assets/sprites/player/player_walk.png")

	if idle_tex == null and walk_tex == null:
		# Fallback to static sprite
		animated_sprite.visible = false
		var fallback := Sprite2D.new()
		fallback.texture = load("res://assets/sprites/player/player_default.png")
		fallback.position = Vector2(0, -8)
		add_child(fallback)
		return

	var sf := SpriteFrames.new()

	# Idle: 64x16 spritesheet, 4 frames of 16x16 (down, left, right, up)
	sf.add_animation("idle")
	sf.set_animation_speed("idle", 4.0)
	if idle_tex:
		for i in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = idle_tex
			atlas.region = Rect2(i * 16, 0, 16, 16)
			sf.add_frame("idle", atlas)

	# Walk: 64x64 spritesheet, 4 rows (directions) x 4 frames of 16x16
	# Directions: row 0=down, 1=left, 2=right, 3=up
	var dir_names: Array[String] = ["walk_down", "walk_left", "walk_right", "walk_up"]
	if walk_tex:
		for dir_idx in range(4):
			var anim_name: String = dir_names[dir_idx]
			sf.add_animation(anim_name)
			sf.set_animation_speed(anim_name, 8.0)
			for frame_idx in range(4):
				var atlas := AtlasTexture.new()
				atlas.atlas = walk_tex
				atlas.region = Rect2(frame_idx * 16, dir_idx * 16, 16, 16)
				sf.add_frame(anim_name, atlas)

	# Remove the default empty animation if it exists
	if sf.has_animation("default"):
		sf.remove_animation("default")

	animated_sprite.sprite_frames = sf
	animated_sprite.play("idle")
	animated_sprite.position = Vector2(0, -8)


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE, State.MOVING:
			_handle_movement(delta)
			_handle_dodge_cooldown(delta)
		State.DODGING:
			_handle_dodge(delta)
		State.ATTACKING:
			pass  # Handled by animation
		State.INTERACTING:
			# Safety timeout — if dialogue never opens, release the player
			_interact_timeout += delta
			if _interact_timeout > 0.5 and not NarrativeEngine.is_in_dialogue():
				print("Player: Interaction timed out — no dialogue opened")
				end_interaction()
		State.DEAD:
			return


func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.DEAD or current_state == State.INTERACTING:
		return

	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("dodge"):
		_try_dodge()
	elif event.is_action_pressed("attack"):
		_try_attack()
	elif event.is_action_pressed("journal"):
		EventBus.notification_requested.emit("Journal opened", "ui")
	elif event.is_action_pressed("inventory"):
		EventBus.notification_requested.emit("Inventory opened", "ui")


func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * SPEED
		facing_direction = input_dir.normalized()
		current_state = State.MOVING
		_update_animation("walk")
		_update_facing()

		# Footstep audio
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			AudioManager.play_footstep()
			_footstep_timer = FOOTSTEP_INTERVAL
	else:
		velocity = Vector2.ZERO
		_footstep_timer = 0.0  # Reset so first step plays immediately
		if current_state == State.MOVING:
			current_state = State.IDLE
			_update_animation("idle")

	move_and_slide()
	_sync_position_to_state()


func _try_dodge() -> void:
	if current_state == State.DODGING or _dodge_cooldown_timer > 0.0:
		return

	current_state = State.DODGING
	_dodge_timer = DODGE_DURATION
	_dodge_cooldown_timer = DODGE_COOLDOWN

	# Dodge in movement direction, or facing direction if standing still
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_dodge_direction = input_dir.normalized() if input_dir != Vector2.ZERO else facing_direction

	_update_animation("dodge")


func _handle_dodge(delta: float) -> void:
	_dodge_timer -= delta
	if _dodge_timer <= 0.0:
		current_state = State.IDLE
		_update_animation("idle")
		return

	velocity = _dodge_direction * DODGE_SPEED
	move_and_slide()
	_sync_position_to_state()


func _handle_dodge_cooldown(delta: float) -> void:
	if _dodge_cooldown_timer > 0.0:
		_dodge_cooldown_timer -= delta


func _try_attack() -> void:
	if current_state != State.IDLE and current_state != State.MOVING:
		return

	current_state = State.ATTACKING
	_update_animation("attack")
	# Attack completion handled by animation signal


func _try_interact() -> void:
	if _nearby_interactables.is_empty():
		print("Player: No interactables nearby")
		return
	print("Player: Found %d interactables" % _nearby_interactables.size())

	# Sort by distance, interact with closest
	var closest: Node = _nearby_interactables[0]
	var closest_dist: float = global_position.distance_squared_to(closest.global_position)
	for interactable in _nearby_interactables:
		var dist: float = global_position.distance_squared_to(interactable.global_position)
		if dist < closest_dist:
			closest = interactable
			closest_dist = dist

	current_state = State.INTERACTING
	_interact_timeout = 0.0
	EventBus.player_interacted.emit(closest)


## Called by dialogue system when dialogue ends.
func end_interaction() -> void:
	current_state = State.IDLE
	_update_animation("idle")


## Take damage from combat.
func take_damage(amount: float, source: String = "") -> void:
	var health: float = GameState.get_state("player.health", 100.0)
	health -= amount
	GameState.set_state("player.health", maxf(health, 0.0))
	EventBus.player_took_damage.emit(amount, source)

	if health <= 0.0:
		_die()


## Heal the player.
func heal(amount: float) -> void:
	var health: float = GameState.get_state("player.health", 100.0)
	var max_health: float = GameState.get_state("player.max_health", 100.0)
	health = minf(health + amount, max_health)
	GameState.set_state("player.health", health)
	EventBus.player_healed.emit(amount)


func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	_update_animation("death")
	EventBus.player_died.emit()


func _update_animation(anim_name: String) -> void:
	if animated_sprite == null:
		return
	var dir_suffix: String = _get_direction_suffix()
	var full_name: String = "%s_%s" % [anim_name, dir_suffix]
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(full_name):
		animated_sprite.play(full_name)
	elif animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)


func _update_facing() -> void:
	if interaction_ray:
		interaction_ray.target_position = facing_direction * 16.0


func _get_direction_suffix() -> String:
	if absf(facing_direction.x) > absf(facing_direction.y):
		return "right" if facing_direction.x > 0 else "left"
	else:
		return "down" if facing_direction.y > 0 else "up"


func _sync_position_to_state() -> void:
	GameState.set_state("player.position_x", global_position.x)
	GameState.set_state("player.position_y", global_position.y)


func _on_interaction_area_body_entered(body: Node) -> void:
	print("Player: Body entered interaction area: %s, groups: %s" % [body.name, str(body.get_groups())])
	if body.is_in_group("interactable"):
		_nearby_interactables.append(body)
		print("Player: Added interactable: %s" % body.name)


func _on_interaction_area_body_exited(body: Node) -> void:
	_nearby_interactables.erase(body)


func _on_interaction_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable"):
		_nearby_interactables.append(area)


func _on_interaction_area_area_exited(area: Area2D) -> void:
	_nearby_interactables.erase(area)


func _on_animated_sprite_animation_finished() -> void:
	if current_state == State.ATTACKING:
		current_state = State.IDLE
		_update_animation("idle")
