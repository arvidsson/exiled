extends MobSkill
class_name RangedAttackMobSkill

@export var range: float = 32.0
@export var damage: RangeInt
@export var animation: String
@export var bullet_speed: float = 150

func can_use(mob: Mob) -> bool:
	if not super.can_use(mob):
		return false
	return mob.distance_to_player_sq() <= range * range

func _execute(mob: Mob) -> void:
	mob.attacking = true
	mob.play_animation_once(animation, func():
		if mob.dying:
			return
		var b = Bullet.create_mob(mob.global_position, mob.dir_to_player(), bullet_speed, damage.get_random())
		#bullet.look_at(mob.player.global_position)
		mob.attacking = false
	)
