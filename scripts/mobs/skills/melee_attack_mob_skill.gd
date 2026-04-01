extends MobSkill
class_name MeleeAttackMobSkill

@export var range: float = 32.0
@export var damage: int = 1
@export var animation: String

func can_use(mob: Mob) -> bool:
	if not super.can_use(mob):
		return false

	return mob._distance_to_player_sq() <= range * range

func _execute(mob: Mob) -> void:
	mob._play_animation_once(animation, func():
		if mob._distance_to_player_sq() <= range * range:
			mob._player.take_damage(damage)
	)
