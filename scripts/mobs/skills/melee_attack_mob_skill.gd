extends MobSkill
class_name MeleeAttackMobSkill

@export var range: float = 32.0
@export var damage: RangeInt
@export var animation: String

func can_use(mob: Mob) -> bool:
	if not super.can_use(mob):
		return false
	return mob.distance_to_player_sq() <= range * range

func _execute(mob: Mob) -> void:
	mob.attacking = true
	mob.play_animation_once(animation, func():
		if mob.dying:
			return
		if mob.distance_to_player_sq() <= range * range:
			mob.player.take_damage(damage.get_random())
		mob.attacking = false
	)
