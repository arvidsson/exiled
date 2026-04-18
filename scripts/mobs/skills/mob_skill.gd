extends Resource
class_name MobSkill

@export var cooldown_min: float = 1.0
@export var cooldown_max: float = 1.2

var remaining := 0.0

func can_use(mob: Mob) -> bool:
	return remaining <= 0.0 and not mob.dying

func use(mob: Mob) -> void:
	remaining = randf_range(cooldown_min, cooldown_max)
	_execute(mob)

func _execute(_mob: Mob) -> void:
	# override
	pass

func process(delta: float) -> void:
	if remaining > 0.0:
		remaining -= delta
