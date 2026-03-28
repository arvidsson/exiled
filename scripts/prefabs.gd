extends Node

static var enemy: PackedScene = load("uid://b5s1262tw3qbw")
static var bullet: PackedScene = load("uid://y3manbrwbttw")

static var shoot_snd: AudioStream = preload("res://sfx/wBullet2.wav")
static var hit_snd: AudioStream = preload("res://sfx/wLizardGHit.wav")
static var music: AudioStream = preload("res://sfx/JDSherbert - Ambiences Music Pack - Desert Sirocco.mp3")
