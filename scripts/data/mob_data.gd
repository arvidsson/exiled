extends Resource
class_name MobData

@export var spawn_cost: int = 10
@export var speed: float = 40.0
@export var attack_range: float = 32.0
@export var attack_cooldown: float = 1.2
@export var xp_reward: int = 10
@export var health: int = 3
@export var skills: Array[MobSkill]
