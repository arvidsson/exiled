extends Mob
class_name Warrior

@export var evade_weight: float = 120.0
@export var evade_radius: float = 80.0

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

func _get_custom_velocity() -> Vector2:
	var evade := Vector2.ZERO
	var space_state = get_world_2d().direct_space_state

	var circle = CircleShape2D.new()
	circle.radius = evade_radius

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0, global_position)
	params.collision_mask = Globals.CollisionLayer.PLAYER_ATTACK
	params.collide_with_areas = true
	params.collide_with_bodies = false

	var results = space_state.intersect_shape(params, 5)
	for res in results:
		var area = res.collider
		# Use duck typing or check class name if Bullet is not recognized
		if area.has_method(&"setup") and "velocity" in area:
			var bullet_vel: Vector2 = area.velocity
			if bullet_vel.length_squared() < 1.0:
				continue

			var to_mob = global_position - area.global_position
			var bullet_dir = bullet_vel.normalized()

			# If bullet is moving away from us, ignore
			if to_mob.dot(bullet_dir) < 0:
				continue

			# Project to_mob onto bullet_dir to find closest point on bullet path
			var projection = to_mob.dot(bullet_dir)
			var closest_point_on_path = bullet_dir * projection
			var dist_to_path_vec = to_mob - closest_point_on_path
			var dist_to_path = dist_to_path_vec.length()

			# If it's already far enough from our center, ignore
			if dist_to_path > 24.0:
				continue

			# Evade perpendicular to bullet path
			var evade_dir : Vector2
			if dist_to_path < 0.1:
				# Bullet is exactly on us, pick a random perpendicular
				evade_dir = Vector2(-bullet_dir.y, bullet_dir.x)
				if randf() < 0.5:
					evade_dir = -evade_dir
			else:
				evade_dir = dist_to_path_vec.normalized()

			# Strength of evasion depends on how close the bullet is to hitting us
			var strength = (24.0 - dist_to_path) / 24.0
			evade += evade_dir * strength

	return evade.limit_length(1.0) * evade_weight
