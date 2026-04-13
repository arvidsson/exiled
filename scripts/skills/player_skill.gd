extends Resource
class_name PlayerSkill

@export var cooldown: float = 1.0
@export var stamina_cost: float = 0.0
@export var controls_movement: bool = false

var cd_timer: CooldownTimer

func can_use(player: Player) -> bool:
	return cd_timer.is_ready() and player.stamina > stamina_cost

func use(player: Player) -> void:
	cd_timer.start(cooldown)
	player.stamina = maxf(0.0, player.stamina - stamina_cost)
	_execute(player)

func tick(player: Player, delta: float) -> void:
	cd_timer.tick(delta)
	# override if stuff should happen each frame

func _execute(player: Player) -> void:
	# override
	pass
