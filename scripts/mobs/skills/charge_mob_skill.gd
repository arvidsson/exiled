extends MobSkill
class_name ChargeMobSkill

@export var charge_range: float = 120.0
@export var charge_speed_multiplier: float = 3.0
@export var charge_duration: float = 0.5
@export var prep_duration: float = 0.3

var charging := false
var prepping := false
var charge_dir := Vector2.ZERO

func can_use(mob: Mob) -> bool:
	if charging or prepping:
		return false
	if not super.can_use(mob):
		return false
	return mob.distance_to_player_sq() <= charge_range * charge_range

func _execute(mob: Mob) -> void:
	prepping = true
	charge_dir = mob.dir_to_player()

	# Stop mob during prep
	var original_speed = mob.speed
	mob.speed = 0.0

	# Optional: play prep animation or effect
	# mob.play_animation(&"prep_charge")

	Tools.call_delay(mob, prep_duration, func():
		if !is_instance_valid(mob): return
		if mob.dying: return
		prepping = false
		charging = true
		mob.speed = original_speed * charge_speed_multiplier

		Tools.call_delay(mob, charge_duration, func():
			if !is_instance_valid(mob): return
			charging = false
			mob.speed = original_speed
		)
	)

func process(delta: float) -> void:
	super.process(delta)
	# Logic for charging could be here, but we are modifying mob.speed directly for now.
	# If we wanted to lock the direction during charge, we'd handle it here or in Warrior.
