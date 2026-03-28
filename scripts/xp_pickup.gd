extends Area2D
class_name XPPickup

@export var magnet_radius: float = 80.0
@export var suck_speed: float = 240.0
@export var collect_distance: float = 6.0
@export var lifetime: float = 30.0

var xp_amount: int = 0
var _collected := false
var _lifetime_timer: SceneTreeTimer


func _on_spawn() -> void:
	_cancel_lifetime()
	_collected = false
	_lifetime_timer = Tools.call_delay(self, lifetime, _on_lifetime_ended)


func _on_despawn() -> void:
	_cancel_lifetime()


func _cancel_lifetime() -> void:
	if _lifetime_timer == null:
		return
	if _lifetime_timer.timeout.is_connected(_on_lifetime_ended):
		_lifetime_timer.timeout.disconnect(_on_lifetime_ended)
	_lifetime_timer = null


func _on_lifetime_ended() -> void:
	_lifetime_timer = null
	if _collected:
		return
	Pools.despawn(self)


func setup(amount: int) -> void:
	xp_amount = amount


func _physics_process(delta: float) -> void:
	if _collected:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
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
	if _collected:
		return
	_collected = true
	_cancel_lifetime()
	if player.has_method(&"add_xp"):
		player.add_xp(xp_amount)
	Pools.despawn(self)
