extends Resource
class_name MobSkill

@export var cooldown: float = 1.0

var _cooldown_remaining := 0.0

func can_use(mob: Mob) -> bool:
	return _cooldown_remaining <= 0.0

func use(mob: Mob) -> void:
	_cooldown_remaining = cooldown
	_execute(mob)

func _execute(mob: Mob) -> void:
	# override
	pass

func process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta
