extends Node

@export var scenes: Array[PackedScene] = []
@export var sounds: Array[AudioStream] = []
@export var music: Array[AudioStream] = []

var _scenes_lookup: Dictionary[String, PackedScene] = {}
var _sounds_lookup: Dictionary[String, AudioStream] = {}
var _music_lookup: Dictionary[String, AudioStream] = {}

func _ready():
	_build_scenes_lookup()
	_build_sounds_lookup()
	_build_music_lookup()

func get_scene(name: String) -> PackedScene:
	if not _scenes_lookup.has(name):
		push_warning("[Data] Scene not found: %s" % name)
		return null
	return _scenes_lookup[name]

func get_sound(name: String) -> AudioStream:
	if not _sounds_lookup.has(name):
		push_warning("[Data] Sound not found: %s" % name)
		return null
	return _sounds_lookup[name]

func get_music(name: String) -> AudioStream:
	if not _music_lookup.has(name):
		push_warning("[Data] Music not found: %s" % name)
		return null
	return _music_lookup[name]

func _build_scenes_lookup():
	_scenes_lookup.clear()
	for s in scenes:
		var name := s.resource_path.get_file().get_basename()
		if name == "":
			push_warning("[Data] Scene missing resource_name:", s)
			continue
		_scenes_lookup[name] = s

func _build_sounds_lookup():
	_sounds_lookup.clear()
	for snd in sounds:
		var name := snd.resource_path.get_file().get_basename()
		if name == "":
			push_warning("[Data] Sound missing name: %s" % snd)
			continue
		_sounds_lookup[name] = snd

func _build_music_lookup():
	_music_lookup.clear()
	for m in music:
		var name := m.resource_path.get_file().get_basename()
		if name == "":
			push_warning("[Data] Music missing name: %s" % m)
			continue
		_music_lookup[name] = m
