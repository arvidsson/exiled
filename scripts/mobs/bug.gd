extends Mob
class_name Bug

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	if dying or attacking:
		return

	process_skills(delta)
	update_facing(player.global_position)

	# Find shooting range from skills
	var shooting_range := 0.0
	for skill in skills:
		if skill is RangedAttackMobSkill:
			shooting_range = max(shooting_range, skill.range)

	if shooting_range == 0.0:
		shooting_range = attack_range # fallback to base attack_range if no ranged skill

	var dist := distance_to_player()
	var too_close_range := shooting_range * 0.7 # move away if closer than half shooting range
	var target_pos := global_position

	if dist > shooting_range:
		# Too far, move towards player
		target_pos = player.global_position
	elif dist < too_close_range:
		# Too close, move away from player
		var dir_away := player.global_position.direction_to(global_position)
		target_pos = global_position + dir_away * 40.0 # target a point further away

	# Always call move_towards to allow for separation logic even when target_pos is global_position
	move_towards(target_pos, delta)

	for skill: MobSkill in skills:
		if skill.can_use(self):
			skill.use(self)
			return

	if velocity.length_squared() > 0.0001:
		play_animation(&"move")
	else:
		play_animation(&"idle")
