extends Resource
class_name MobSkill

@export var cooldown: float = 1.0

var remaining := 0.0

func can_use(mob: Mob) -> bool:
	return remaining <= 0.0 and not mob.dying

func use(mob: Mob) -> void:
	remaining = cooldown
	_execute(mob)

func _execute(mob: Mob) -> void:
	# override
	pass

func process(delta: float) -> void:
	if remaining > 0.0:
		remaining -= delta
