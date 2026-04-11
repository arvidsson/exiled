extends Node

func _ready() -> void:
	print("[Data] ready")

class Mobs:
	static var Bug: PackedScene = load("uid://dw6i8s0i62np2")
	static var Lizard: PackedScene = load("uid://cr74oa801on3x")
	static var Warrior: PackedScene = load("uid://brpqs6g30un30")

class Scenes:
	static var XpPickup: PackedScene = load("uid://bg4ey3x532mxi")
	static var Bullet: PackedScene = load("uid://y3manbrwbttw")
	static var MobBullet: PackedScene = load("uid://r3sd2tgxs5li")

class FX:
	static var DamageLabel: PackedScene = load("uid://cjnddsux8u1av")

class Sounds:
	static var Hurt: AudioStream = load("uid://dkr3n0efaj0lc")
	static var Shoot: AudioStream = load("uid://cs0iuyy7ky0is")
	static var Reload: AudioStream = load("uid://c21fo2s5r3ywm")

class Music:
	static var Default: AudioStream = load("uid://5kbn2v4ysu3v")
