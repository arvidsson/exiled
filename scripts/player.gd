extends CharacterBody2D

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

@export var max_speed: float
@export var bullet_speed: float = 300.0
@export var roll_speed_mult: float = 1.5

var cur_dir := Vector2.DOWN
var _rolling := false
var _roll_dir := Vector2.DOWN

@onready var sprite := $AnimatedSprite2D
@onready var gun := $Gun
@onready var muzzle := $Gun/Muzzle


func _process(_delta: float) -> void:
	if _rolling:
		return
	var target := get_global_mouse_position()
	if (target - global_position).length_squared() > 0.0001:
		gun.look_at(target)
		gun.scale.y = -1.0 if target.x < global_position.x else 1.0
	else:
		gun.scale.y = 1.0


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("roll") and not _rolling:
		_start_roll()

	if _rolling:
		velocity = _roll_dir * max_speed * roll_speed_mult
		move_and_slide()
		return

	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * max_speed
	move_and_slide()

	if dir.length() > 0:
		cur_dir = dir
		_update_anim("move", dir)
	else:
		_update_anim("idle", cur_dir)

	# Player facing only (matches _update_anim "up" vs down/horizontal).
	var facing_up: bool = abs(cur_dir.x) < abs(cur_dir.y) and cur_dir.y < 0
	gun.z_index = -1 if facing_up else 1

	if Input.is_action_just_pressed("shoot"):
		_fire()


func _start_roll() -> void:
	var d := cur_dir
	if d.length_squared() < 0.0001:
		d = Vector2.DOWN
	_roll_dir = d.normalized()
	_rolling = true
	gun.hide()
	_play_roll_anim(_roll_dir)
	sprite.animation_finished.connect(_on_roll_finished, CONNECT_ONE_SHOT)


func _on_roll_finished() -> void:
	_rolling = false
	gun.show()


func _fire() -> void:
	var bullet: Area2D = BULLET_SCENE.instantiate()
	bullet.setup(muzzle.global_transform.x, bullet_speed)
	bullet.global_position = muzzle.global_position
	get_parent().add_child(bullet)


func _play_roll_anim(dir: Vector2) -> void:
	var anim: String
	if abs(dir.x) < abs(dir.y):
		sprite.flip_h = false
		sprite.offset.x = 0
		anim = "roll_down" if dir.y > 0 else "roll_up"
	else:
		anim = "roll_right"
		sprite.flip_h = dir.x < 0
		sprite.offset.x = -24 if dir.x < 0 else 0
	sprite.play(anim)


func _update_anim(state: String, dir: Vector2) -> void:
	var anim := ""

	if abs(dir.x) < abs(dir.y):
		sprite.flip_h = false
		sprite.offset.x = 0
		if dir.y > 0:
			anim = state + "_down"
		else:
			anim = state + "_up"
	else:
		anim = state + "_right"
		sprite.flip_h = dir.x < 0
		# HACK: offset fix
		sprite.offset.x = -24 if dir.x < 0 else 0

	# Avoid restarting animation every frame
	if sprite.animation != anim:
		sprite.play(anim)
