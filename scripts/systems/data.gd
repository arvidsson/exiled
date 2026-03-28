extends Node

@export var mob_data: Array[MobData] = []
@export var scenes: Array[PackedScene] = []

var _mob_data_lookup: Dictionary[String, MobData] = {}
var _scenes_lookup: Dictionary[String, PackedScene] = {}

func _ready():
	_build_mob_data_lookup()
	_build_scenes_lookup()

func get_mob_data(name: String) -> MobData:
	if not _mob_data_lookup.has(name):
		push_warning("[Data] Resource not found:", name)
		return null
	return _mob_data_lookup[name]

func get_scene(name: String) -> PackedScene:
	if not _scenes_lookup.has(name):
		push_warning("[Data] Scene not found: %s" % name)
		return null
	return _scenes_lookup[name]

func _build_mob_data_lookup():
	_mob_data_lookup.clear()
	for m in mob_data:
		if not "resource_name" in m:
			push_warning("[Data] Resource missing name:", m)
			continue
		_mob_data_lookup[m.resource_name] = m

func _build_scenes_lookup():
	_scenes_lookup.clear()
	for s in scenes:
		var name := s.resource_path.get_file().get_basename()
		if name == "":
			push_warning("[Data] Scene missing resource_name:", s)
			continue
		_scenes_lookup[name] = s
