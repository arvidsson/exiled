extends Node

## Seconds from start until credit gain reaches its end value.
@export var ramp_duration_sec: float = 600.0 # 10 minutes for full ramp
## Credits gained per second at the start.
@export var credit_gain_start: float = 5.0
## Credits gained per second at the end of the ramp.
@export var credit_gain_end: float = 50.0
## Maximum credits the director can save up.
@export var max_credits: float = 500.0
## How often the director tries to spawn something.
@export var tick_interval: float = 1.0
## Ring sits just outside the visible viewport (world units past the view diagonal).
@export var ring_margin: float = 40.0
## Keep spawn points inside the level rectangle.
@export var clamp_to_level: bool = true
## Maximum number of enemies allowed at once.
@export var max_enemies: int = 40
## Probability that the director will skip a tick to save up for a bigger burst.
@export var skip_tick_chance: float = 0.2
## Multiplier for credit gain when in aggressive mode.
@export var aggression_multiplier: float = 2.5

@export var available_scenes: Array[PackedScene]

@export var aggressive_mode: bool = false
@export var ammo_spawn_interval_low: float = 12.0 # seconds between ammo spawns when low

var _elapsed: float = 0.0
var _credits: float = 0.0
var _tick_accum: float = 0.0
var _ammo_spawn_timer: float = 0.0


# Helper to hold scene and its associated data/cost
class SpawnCard:
	var scene: PackedScene
	var data: MobData
	var cost: int:
		get: return data.spawn_cost if data else 10

var _spawn_cards: Array[SpawnCard] = []

func _ready() -> void:
	# Load default scenes if none provided
	if available_scenes.is_empty():
		available_scenes.append(load("uid://dw6i8s0i62np2")) # Bug
		#available_scenes.append(load("uid://cr74oa801on3x")) # Lizard
		available_scenes.append(load("uid://brpqs6g30un30")) # Warrior

	# Initialize spawn cards by peeking into scenes
	for scene in available_scenes:
		var card := SpawnCard.new()
		card.scene = scene
		# Instantiate temporarily to get the data reference
		var temp = scene.instantiate()
		if "data" in temp:
			card.data = temp.data
		temp.queue_free()
		_spawn_cards.append(card)

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var player_count := get_tree().get_nodes_in_group(&"player").size()
	if player_count == 0:
		return
	var player := _get_player()
	if player == null:
		return

	_elapsed += delta

	# Gain credits (scales with time and player count)
	var gain_rate := lerpf(credit_gain_start, credit_gain_end, _ramp_t())
	gain_rate *= (1.0 + (player_count - 1) * 0.5) # +50% credits per extra player

	if aggressive_mode:
		gain_rate *= aggression_multiplier

	_credits = minf(_credits + gain_rate * delta, max_credits)

	# Ammo spawn logic: if player is on last mag or empty, spawn ammo outside view
	if player is Player and (player.total_ammo == 0 or player.ammo == 0):
		_ammo_spawn_timer += delta
		if _ammo_spawn_timer >= ammo_spawn_interval_low:
			_ammo_spawn_timer = 0.0
			var ammo_drop = _spawn_one_on_ring(Data.Scenes.Ammo, player.global_position, cam) as Ammo
			if ammo_drop:
				ammo_drop.setup(player.magazine_size)
	else:
		_ammo_spawn_timer = 0.0

	_tick_accum += delta
	if _tick_accum >= tick_interval:
		_tick_accum = 0.0
		if randf() > skip_tick_chance:
			_attempt_spawn(player.global_position, cam)

func _ramp_t() -> float:
	if ramp_duration_sec <= 0.0:
		return 1.0
	return clampf(_elapsed / ramp_duration_sec, 0.0, 1.0)

func _get_player() -> Node2D:
	for n in get_tree().get_nodes_in_group(&"player"):
		if n is Node2D:
			return n as Node2D
	return null

func _get_enemy_count() -> int:
	return get_tree().get_nodes_in_group(&"mobs").size()

func _attempt_spawn(center: Vector2, cam: Camera2D) -> void:
	var enemy_count := _get_enemy_count()
	if enemy_count >= max_enemies:
		return

	var budget := _credits
	if budget < _get_min_cost():
		return

	# Filter affordable cards
	var affordable: Array[SpawnCard] = []
	var most_expensive: SpawnCard = null

	for card in _spawn_cards:
		if card.cost <= budget:
			affordable.append(card)
			if most_expensive == null or card.cost > most_expensive.cost:
				most_expensive = card

	if affordable.is_empty():
		return

	# Risk of Rain style: the director often waits until it can afford "better" things.
	# If we can only afford the cheapest unit, there's a high chance we wait.
	if affordable.size() == 1 and budget < 100.0:
		# If we only afford a Bug (10) but budget is still low,
		# 80% chance to wait for more.
		if randf() < 0.8:
			return

	# Weighted selection: expensive mobs are preferred if affordable
	affordable.sort_custom(func(a, b): return a.cost > b.cost)

	var selected_card: SpawnCard = null
	for card in affordable:
		# 60% chance to pick this one if it's among the more expensive ones
		# This gives a bias towards the top of the sorted list
		if randf() < 0.6:
			selected_card = card
			break

	if selected_card == null:
		selected_card = affordable[-1] # fallback to cheapest

	# Extra patience: if we picked something much cheaper than our budget,
	# maybe skip to save for a BIG burst or a better unit.
	if budget > 60.0 and selected_card.cost < budget * 0.25:
		if randf() < 0.5:
			return

	# Group spawn
	var max_to_spawn := randi_range(1, 4)
	if _elapsed > 300.0:
		max_to_spawn = randi_range(2, 6)

	# Spend at least some of the budget
	var spawned := 0
	while spawned < max_to_spawn and _credits >= selected_card.cost and (enemy_count + spawned) < max_enemies:
		_credits -= selected_card.cost
		_spawn_one_on_ring(selected_card.scene, center, cam)
		spawned += 1
func _get_min_cost() -> int:
	var min_cost := 999999
	for card in _spawn_cards:
		min_cost = min(min_cost, card.cost)
	return min_cost

func _ring_radius(cam: Camera2D) -> float:
	var half := get_viewport().get_visible_rect().size / (2.0 * cam.zoom)
	return half.length() + ring_margin

func _spawn_one_on_ring(scene: PackedScene, center: Vector2, cam: Camera2D) -> Node:
	var angle := randf() * TAU
	var r := _ring_radius(cam)
	var pos := center + Vector2.from_angle(angle) * r
	if clamp_to_level:
		var level = get_node_or_null("../Level")
		if level:
			var lr: Rect2 = level.level_rect
			pos.x = clampf(pos.x, lr.position.x, lr.end.x)
			pos.y = clampf(pos.y, lr.position.y, lr.end.y)

	return Pools.spawn(scene, pos)
