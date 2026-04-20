extends Mob
class_name Warrior

enum State {
	CHASE,
	EVADE,
	PREP,
	CHARGE
}

@export var evade_weight: float = 120.0
@export var evade_radius: float = 80.0

@export var melee_attack: MeleeAttackMobSkill
@export var charge: ChargeMobSkill

var current_state := State.CHASE

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	if dying or attacking:
		return

	process_skills(delta)

	var charge_skill: ChargeMobSkill = _get_charge_skill()
	var is_charging = charge_skill != null and charge_skill.charging
	var is_prepping = charge_skill != null and charge_skill.prepping

	# Determine current behavior state
	var evade_vec = _get_evasion_vector()

	if is_charging:
		current_state = State.CHARGE
	elif is_prepping:
		current_state = State.PREP
	elif evade_vec.length_squared() > 0.001:
		current_state = State.EVADE
	else:
		current_state = State.CHASE

	# Update facing (unless charging)
	if current_state != State.CHARGE:
		update_facing(player.global_position)

	# Check for skill usage (e.g. melee attack)
	for skill: MobSkill in skills:
		if skill.can_use(self):
			skill.use(self)
			return

	# Execute movement based on state
	match current_state:
		State.CHARGE:
			move_towards(global_position + charge_skill.charge_dir * 100.0, delta)
		State.PREP:
			stop()
		State.EVADE:
			# Move in evasion direction instead of towards player
			var original_speed = speed
			speed = evade_weight
			move_towards(global_position + evade_vec * 100.0, delta)
			speed = original_speed
		State.CHASE:
			move_towards(player.global_position, delta)
	if velocity.length_squared() > 0.0001:
		play_animation(&"move")
	else:
		play_animation(&"idle")

func _get_charge_skill() -> ChargeMobSkill:
	for skill in skills:
		if skill is ChargeMobSkill:
			return skill as ChargeMobSkill
	return null

func _get_evasion_vector() -> Vector2:
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

	return evade.limit_length(1.0)
