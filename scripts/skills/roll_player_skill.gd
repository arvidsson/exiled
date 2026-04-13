extends PlayerSkill
class_name RollPlayerSkill

@export var roll_speed_mult: float = 1.5

var roll_dir := Vector2.DOWN

func tick(player: Player, delta: float) -> void:
	super.tick(player, delta)
	player.velocity = roll_dir * player.movement_speed * roll_speed_mult
	player.move_and_slide()

func _execute(player: Player) -> void:
	_start_roll(player)

func _start_roll(player: Player) -> void:
	var d := player.cur_dir
	if d.length_squared() < 0.0001:
		d = Vector2.DOWN
	roll_dir = d.normalized()
	player.gun.hide()
	_play_roll_anim(player, roll_dir)
	player.sprite.animation_finished.connect(
		func():
			_on_roll_finished(player),
		CONNECT_ONE_SHOT
	)

func _on_roll_finished(player: Player) -> void:
	player.gun.show()

func _play_roll_anim(player: Player, dir: Vector2) -> void:
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
