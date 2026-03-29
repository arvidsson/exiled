extends Node

enum CollisionLayer {
	WORLD = 1 << 0,
	PLAYER = 1 << 1,
	MOB = 1 << 2,
	PLAYER_ATTACK = 1 << 3,
	MOB_ATTACK = 1 << 4
}
