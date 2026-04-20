class_name Wisp
extends Mob

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	if dying:
		return

	move_towards(player.global_position, delta)
	update_facing(player.global_position)

	if distance_to_player() <= attack_range:
		player.take_damage(1)
		_die()
		return

	if velocity.length_squared() > 0.01:
		play_animation(&"walk")
	else:
		play_animation(&"idle")
