extends CharacterBody2D
class_name Player

@export var movement_speed: float = 50.0
@export var bullet_speed: float = 300.0

@export var max_stamina: float = 100.0
@export var stamina_regen: float = 25.0 # per sec

@export var max_health: int = 2
@export var xp_per_level: float = 100.0
@export var magazine_size: int = 6
@export var fire_interval_sec: float = 0.2 # fire_speed
@export var reload_duration_sec: float = 1.0 # reload_speed
@export var damage: RangeInt
@export var crit_chance: float = 0.01
@export var crit_multiplier: float = 1.5

@export var skills: Dictionary[Globals.Skill, PlayerSkill]

const HURT_FLASH_PEAK := Color(5.0, 5.0, 5.0)
const HURT_FLASH_DURATION := 0.12

var cur_dir := Vector2.DOWN
var active_skill: PlayerSkill = null
var health: int
var dying := false
var invincible := false
var stamina: float: set = _set_stamina
var current_xp: float = 0.0
var player_level: int = 1
var hurt_tween: Tween
var ammo: int: set = _set_ammo
var total_ammo: int
var reloading := false

var fire_timer: CooldownTimer = CooldownTimer.new()
var reload_timer: ActionTimer = ActionTimer.new()

@onready var sprite := $AnimatedSprite2D
@onready var gun := $Gun
@onready var muzzle := $Gun/Muzzle

func _ready() -> void:
	stamina = max_stamina
	health = max_health
	ammo = magazine_size
	total_ammo = magazine_size * 2
	call_deferred(&"_sync_xp_bar")
	call_deferred(&"_sync_hp_label")
	call_deferred(&"_sync_ammo_label")
	call_deferred(&"_sync_stamina_bar")
	for key in skills.keys():
		var skill: PlayerSkill = skills[key].duplicate()
		skill.setup(self)
		skills[key] = skill

func _set_stamina(value: float):
	stamina = clamp(value, 0.0, max_stamina)
	_sync_stamina_bar()

func _set_ammo(value: int):
	ammo = clamp(value, 0, magazine_size)
	_sync_ammo_label()

func _sync_stamina_bar() -> void:
	Events.stamina_changed.emit(stamina, max_stamina)
func _sync_xp_bar() -> void:
	Events.xp_changed.emit(current_xp, xp_per_level)
func _sync_hp_label() -> void:
	Events.health_changed.emit(health, max_health)
func _sync_ammo_label() -> void:
	Events.ammo_changed.emit(ammo, total_ammo)

func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_per_level:
		current_xp -= xp_per_level
		player_level += 1
		Events.levelup.emit()
	_sync_xp_bar()

func take_damage(amount: int = 1) -> void:
	# TODO: hack! should check elsewhere, yup cuz now bullets gets destroyed on collision!
	if invincible or dying:
		return
	health -= amount
	_play_hurt_flash()
	_sync_hp_label()
	var par := get_parent()
	if par != null:
		var fc: Node = par.get_node_or_null("FollowCamera")
		if fc != null and fc.has_method(&"add_shake"):
			fc.call(&"add_shake", 6.0)
	if health <= 0:
		_die()

func _disconnect_animation_finished(callback: Callable) -> void:
	if sprite.animation_finished.is_connected(callback):
		sprite.animation_finished.disconnect(callback)

func _play_animation(name: StringName) -> void:
	if sprite.animation != name:
		sprite.play(name)

func _play_animation_once(anim: StringName, callback: Callable) -> void:
	_disconnect_animation_finished(callback)
	sprite.play(anim)
	sprite.animation_finished.connect(callback, CONNECT_ONE_SHOT)

func _die() -> void:
	dying = true
	reloading = false
	velocity = Vector2.ZERO
	gun.hide()  # hide gun during death animation
	_play_animation_once("die", _on_death_anim_finished)

func _on_death_anim_finished() -> void:
	Tools.call_delay(self, 1.2, func() -> void:
		get_tree().reload_current_scene()
	)

func _play_hurt_flash() -> void:
	if hurt_tween != null:
		hurt_tween.kill()
	hurt_tween = create_tween()
	hurt_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sprite.modulate = HURT_FLASH_PEAK
	hurt_tween.tween_property(sprite, "modulate", Color.WHITE, HURT_FLASH_DURATION)

func _try_use_skill(skill_id: Globals.Skill) -> void:
	var skill: PlayerSkill = skills.get(skill_id)
	if skill == null:
		return
	if not skill.can_use():
		return
	skill.use()
	Events.skill_used.emit(skill_id, skill.cooldown)
	active_skill = skill

func _handle_skill_input() -> void:
	if active_skill != null:
		return
	for action: String in Globals.input_to_skill.keys():
		if Input.is_action_just_pressed(action):
			print("pressed: ", action)
			var skill_id: Globals.Skill = Globals.input_to_skill[action]
			_try_use_skill(skill_id)

func _update_gun_visuals():
	# gun aim
	var target := get_global_mouse_position()
	gun.look_at(target)
	gun.scale.y = -1.0 if target.x < global_position.x else 1.0

	# change gun z index depending on if we are facing upwards or not
	var facing_up: bool = abs(cur_dir.x) < abs(cur_dir.y) and cur_dir.y < 0
	gun.z_index = -1 if facing_up else 1

func _process(_delta: float) -> void:
	if dying:
		return
	_update_gun_visuals()

func _physics_process(delta: float) -> void:
	if dying:
		return

	# stamina regen
	if stamina < max_stamina:
		stamina = minf(max_stamina, stamina + stamina_regen * delta)

	_handle_skill_input()

	if active_skill and active_skill.tick(delta):
		return

	# move
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * movement_speed
	move_and_slide()

	# update animation
	if dir.length() > 0:
		cur_dir = dir
		_update_anim("move", dir)
	else:
		_update_anim("idle", cur_dir)

	fire_timer.tick(delta)
	reload_timer.tick(delta)

	if Input.is_action_just_pressed("reload"):
		_reload()
	elif Input.is_action_pressed("primary_action") and ammo == 0:
		_reload()

	if not reloading and Input.is_action_pressed("primary_action") and ammo > 0 and fire_timer.is_ready():
		_fire()
		ammo -= 1
		fire_timer.start(fire_interval_sec)

func _reload() -> void:
	if reloading or ammo >= magazine_size or total_ammo <= 0:
		return
	Audio.play_sfx(Data.Sounds.Reload)
	reloading = true
	reload_timer.start(reload_duration_sec,
		func():
			reloading = false
			var needed := magazine_size - ammo
			var to_load := min(needed, total_ammo) as int
			if to_load > 0:
				total_ammo -= to_load
				ammo += to_load
	)

func _fire() -> void:
	Events.skill_used.emit(Globals.Skill.PRIMARY, fire_interval_sec)
	var dmg := damage.get_random()
	var is_crit := randf() < crit_chance
	if is_crit:
		dmg = round(dmg * crit_multiplier)

	Bullet.create(muzzle.global_position, muzzle.global_transform.x, bullet_speed, dmg)
	Audio.play_sfx(Data.Sounds.Shoot)

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

	if sprite.animation != anim:
		sprite.play(anim)
