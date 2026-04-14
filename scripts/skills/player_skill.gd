extends Resource
class_name PlayerSkill

@export var cooldown: float = 1.0
@export var stamina_cost: float = 0.0

var cd_timer: CooldownTimer = CooldownTimer.new()
var player: Player

func setup(p: Player) -> void:
	player = p

func can_use() -> bool:
	return cd_timer.is_ready() and player.stamina > stamina_cost

func use() -> void:
	cd_timer.start(cooldown)
	player.stamina = player.stamina - stamina_cost
	_execute()

# returns true if it controls movement
func tick(delta: float) -> bool:
	# override if stuff should happen each frame
	cd_timer.tick(delta)
	if cd_timer.is_ready():
		player.active_skill = null
	return false

func _execute() -> void:
	# override
	pass
