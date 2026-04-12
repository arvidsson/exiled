extends MobSkill
class_name MeleeAttackMobSkill

@export var range: float = 32.0
@export var damage: RangeInt
@export var animation: String
@export var slash_offset: float = 8.0

func can_use(mob: Mob) -> bool:
	if not super.can_use(mob):
		return false
	return mob.distance_to_player_sq() <= range * range

func _execute(mob: Mob) -> void:
	mob.attacking = true
	mob.play_animation_once(animation, func():
		if mob.dying:
			return
		# spawn a slash effect instead of applying damage directly
		var slash: Slash = Pools.spawn(Data.Scenes.Slash, mob.global_position)
		if slash:
			var dir := mob.dir_to_player()
			slash.rotation = dir.angle()
			slash.global_position += dir * slash_offset
			slash.damage = damage.get_random()
		mob.attacking = false
	)
