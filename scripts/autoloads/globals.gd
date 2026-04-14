extends Node

func _ready() -> void:
	print("[Globals] ready")

enum CollisionLayer {
	WORLD = 1 << 0,
	PLAYER = 1 << 1,
	MOB = 1 << 2,
	PLAYER_ATTACK = 1 << 3,
	MOB_ATTACK = 1 << 4
}

enum Skill {
	PRIMARY,
	SECONDARY,
	TERTIARY,
	UTILITY,
	SPECIAL
}

static var input_to_skill := {
	"primary_action": Skill.PRIMARY,
	"secondary_action": Skill.SECONDARY,
	"utility_action": Skill.UTILITY,
	"special_action": Skill.SPECIAL
}
