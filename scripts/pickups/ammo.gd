extends Area2D
class_name Ammo

@export var magnet_radius: float = 80.0
@export var suck_speed: float = 240.0
@export var collect_distance: float = 6.0
@export var lifetime: float = 60.0

@onready var player: Player = get_tree().get_first_node_in_group("player") as Player

var amount: int = 0
var collected := false
var lifetime_timer: SceneTreeTimer

func _on_spawn() -> void:
	_cancel_lifetime()
	collected = false
	lifetime_timer = Tools.call_delay(self, lifetime, _on_lifetime_ended)

func _on_despawn() -> void:
	_cancel_lifetime()

func _cancel_lifetime() -> void:
	if lifetime_timer == null:
		return
	if lifetime_timer.timeout.is_connected(_on_lifetime_ended):
		lifetime_timer.timeout.disconnect(_on_lifetime_ended)
	lifetime_timer = null

func _on_lifetime_ended() -> void:
	lifetime_timer = null
	if collected:
		return
	Pools.despawn(self)

func setup(amount: int) -> void:
	self.amount = amount

func _physics_process(delta: float) -> void:
	if collected:
		return

	var to_player := player.global_position - global_position
	var dist_sq := to_player.length_squared()
	var collect_sq := collect_distance * collect_distance
	if dist_sq <= collect_sq:
		_collect(player)
		return

	var magnet_sq := magnet_radius * magnet_radius
	if dist_sq <= magnet_sq:
		var dir := to_player.normalized()
		global_position += dir * suck_speed * delta

func _collect(player: Node2D) -> void:
	if collected:
		return
	collected = true
	_cancel_lifetime()
	if player.has_method(&"add_ammo"):
		player.add_ammo(amount)
	Pools.despawn(self)
