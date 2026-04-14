extends PlayerSkill
class_name RollPlayerSkill

@export var roll_speed_mult: float = 1.5

var roll_dir := Vector2.DOWN
var rolling := false

func tick(delta: float) -> bool:
	if not rolling:
		return false
	super.tick(delta)
	player.velocity = roll_dir * player.movement_speed * roll_speed_mult
	player.move_and_slide()
	return true

func _execute() -> void:
	_start_roll()

func _start_roll() -> void:
	rolling = true
	player.invincible = true
	var d:Vector2 = player.cur_dir
	if d.length_squared() < 0.0001:
		d = Vector2.DOWN
	roll_dir = d.normalized()
	player.gun.hide()
	_play_roll_anim(roll_dir)
	player.sprite.animation_finished.connect(_on_roll_finished, CONNECT_ONE_SHOT)

func _on_roll_finished() -> void:
	rolling = false
	cd_timer.stop()
	player.invincible = false
	player.active_skill = null
	player.gun.show()

func _play_roll_anim(dir: Vector2) -> void:
	var anim: String
	if abs(dir.x) < abs(dir.y):
		player.sprite.flip_h = false
		player.sprite.offset.x = 0
		anim = "roll_down" if dir.y > 0 else "roll_up"
	else:
		anim = "roll_right"
		player.sprite.flip_h = dir.x < 0
		player.sprite.offset.x = -24 if dir.x < 0 else 0
	player.sprite.play(anim)
