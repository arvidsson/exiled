extends Mob
class_name Bug

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	if dying or attacking:
		return

	process_skills(delta)
	update_facing(player.global_position)

	for skill: MobSkill in skills:
		if skill.can_use(self):
			skill.use(self)
			return

	move_towards(player.global_position, delta)

	if velocity.length_squared() > 0.0001:
		play_animation(&"move")
	else:
		play_animation(&"idle")
