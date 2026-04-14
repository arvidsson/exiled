extends PlayerSkill
class_name BurstPlayerSkill

@export var bullet_count: int = 3
@export var bullet_interval: float = 0.06
@export var bullet_spread: float = 6.0
@export var bullet_speed: float = 300.0
@export var knockback: float = 120.0

func can_use() -> bool:
	return super.can_use() and player.ammo >= bullet_count

func _execute() -> void:
	_fire()

func _fire() -> void:
	var dmg := player.damage.get_random()
	dmg = int(dmg / 2.0)
	var is_crit := randf() < player.crit_chance
	if is_crit:
		dmg = round(dmg * player.crit_multiplier)

	var base_dir: Vector2 = player.muzzle.global_transform.x
	var spread_rad := bullet_spread * PI / 180.0

	for i in range(bullet_count):
		Tools.call_delay(player, i * bullet_interval, func() -> void:
			var d := base_dir.rotated(randf_range(-spread_rad, spread_rad))
			Bullet.create(player.muzzle.global_position, d, bullet_speed, dmg, knockback)
			Audio.play_sfx(Data.Sounds.Shoot)
			player.ammo -= 1
		)
