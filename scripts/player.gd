extends CharacterBody2D

@export var max_speed: float
@export var bullet_speed: float = 300.0
@export var roll_speed_mult: float = 1.5
@export var max_stamina: float = 100.0
@export var stamina_regen_per_sec: float = 25.0
@export var roll_stamina_cost: float = 35.0
@export var max_hp: int = 2
@export var xp_per_level: float = 100.0
@export var magazine_size: int = 6
@export var fire_interval_sec: float = 0.2
@export var reload_duration_sec: float = 1.0

const HURT_FLASH_PEAK := Color(5.0, 5.0, 5.0)
const HURT_FLASH_DURATION := 0.12

var cur_dir := Vector2.DOWN
var current_hp: int
var _rolling := false
var _roll_dir := Vector2.DOWN
var current_stamina: float
var current_xp: float = 0.0
var player_level: int = 1
var _hurt_tween: Tween
var ammo: int
var _reloading := false
var _reload_remaining: float = 0.0
var _fire_cooldown: float = 0.0

@onready var sprite := $AnimatedSprite2D
@onready var gun := $Gun
@onready var muzzle := $Gun/Muzzle

func _ready() -> void:
	current_stamina = max_stamina
	current_hp = max_hp
	ammo = magazine_size
	call_deferred(&"_sync_xp_bar")
	call_deferred(&"_sync_hp_label")
	call_deferred(&"_sync_ammo_label")


func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_per_level:
		current_xp -= xp_per_level
		player_level += 1
	_sync_xp_bar()


func take_damage(amount: int) -> void:
	current_hp -= amount
	_play_hurt_flash()
	_sync_hp_label()
	var par := get_parent()
	if par != null:
		var fc: Node = par.get_node_or_null("FollowCamera")
		if fc != null and fc.has_method(&"add_shake"):
			fc.call(&"add_shake", 6.0)
	if current_hp <= 0:
		get_tree().reload_current_scene()


func _play_hurt_flash() -> void:
	if _hurt_tween != null:
		_hurt_tween.kill()
	_hurt_tween = create_tween()
	_hurt_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sprite.modulate = HURT_FLASH_PEAK
	_hurt_tween.tween_property(sprite, "modulate", Color.WHITE, HURT_FLASH_DURATION)


func _process(_delta: float) -> void:
	if _rolling:
		return
	var target := get_global_mouse_position()
	if (target - global_position).length_squared() > 0.0001:
		gun.look_at(target)
		gun.scale.y = -1.0 if target.x < global_position.x else 1.0
	else:
		gun.scale.y = 1.0

func _physics_process(delta: float) -> void:
	if current_stamina < max_stamina:
		current_stamina = minf(max_stamina, current_stamina + stamina_regen_per_sec * delta)

	if Input.is_action_just_pressed("roll") and not _rolling and current_stamina >= roll_stamina_cost:
		_start_roll()

	if _rolling:
		velocity = _roll_dir * max_speed * roll_speed_mult
		move_and_slide()
		_sync_stamina_bar()
		_sync_hp_label()
		_sync_ammo_label()
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

	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	if _reloading:
		_reload_remaining -= delta
		if _reload_remaining <= 0.0:
			_reloading = false
			ammo = magazine_size
			_fire_cooldown = fire_interval_sec

	if not _reloading:
		if Input.is_action_just_pressed("reload") and ammo < magazine_size:
			_start_reload()
		elif Input.is_action_pressed("shoot") and ammo == 0:
			_start_reload()

	if not _reloading and Input.is_action_pressed("shoot") and ammo > 0 and _fire_cooldown <= 0.0:
		_fire()
		ammo -= 1
		_fire_cooldown = fire_interval_sec

	_sync_stamina_bar()
	_sync_hp_label()
	_sync_ammo_label()

func _start_roll() -> void:
	current_stamina = maxf(0.0, current_stamina - roll_stamina_cost)
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

func _sync_stamina_bar() -> void:
	if Refs.stamina_bar == null:
		return
	var bar: ProgressBar = Refs.stamina_bar
	bar.max_value = max_stamina
	bar.value = current_stamina


func _sync_xp_bar() -> void:
	if Refs.xp_bar == null:
		return
	var bar: ProgressBar = Refs.xp_bar
	bar.max_value = xp_per_level
	bar.value = current_xp


func _sync_hp_label() -> void:
	if Refs.hp_label == null:
		return
	Refs.hp_label.text = "hp %d / %d" % [current_hp, max_hp]


func _sync_ammo_label() -> void:
	if Refs.ammo_label == null:
		return
	Refs.ammo_label.text = "ammo %d / %d" % [ammo, magazine_size]


func _start_reload() -> void:
	if _reloading or ammo >= magazine_size:
		return
	_reloading = true
	_reload_remaining = reload_duration_sec


func _fire() -> void:
	var bullet := Refs.bullet_pool.spawn(null, muzzle.global_position) as Area2D
	bullet.setup(muzzle.global_transform.x, bullet_speed)
	SoundManager.play_sfx(Prefabs.shoot_snd)

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
