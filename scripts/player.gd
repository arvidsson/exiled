extends CharacterBody2D

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

@export var max_speed: float
@export var bullet_speed: float = 300.0

var cur_dir := Vector2.DOWN

@onready var sprite := $AnimatedSprite2D
@onready var gun := $Gun
@onready var muzzle := $Gun/Muzzle


func _process(_delta: float) -> void:
	var target := get_global_mouse_position()
	if (target - global_position).length_squared() > 0.0001:
		gun.look_at(target)
		gun.scale.y = -1.0 if target.x < global_position.x else 1.0
	else:
		gun.scale.y = 1.0


func _physics_process(_delta: float) -> void:
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


func _fire() -> void:
	var bullet: Area2D = BULLET_SCENE.instantiate()
	bullet.setup(muzzle.global_transform.x, bullet_speed)
	bullet.global_position = muzzle.global_position
	get_parent().add_child(bullet)


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
