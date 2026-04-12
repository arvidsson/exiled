extends Node

func _ready() -> void:
	print("[Pools] ready")

var _pools: Dictionary[PackedScene, Pool] = {}

class Pool:
	extends Node

	var _scene: PackedScene
	var _pool_size: int = 10
	var _available: Array = []
	var _active: Dictionary = {}
	var _count: int = 0
	var _active_parent: Node = null

	func _init(scene: PackedScene, parent: Node, pool_size: int = 10):
		_scene = scene
		_pool_size = pool_size
		_active_parent = parent
		_create_pool()

	func _create_pool():
		_available.clear()
		_active.clear()
		for i in range(_pool_size):
			var instance = _create_instance()
			_set_active(instance, false)

	func _create_instance() -> Node:
		var instance = _scene.instantiate()
		_count += 1
		instance.set_meta("_pool", self)
		instance.name = "%s_%d" % [instance.name, _count]
		_available.append(instance)
		add_child(instance)
		return instance

	func _set_active(node: Node, active: bool) -> void:
		node.visible = active
		node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		var parent = _active_parent if active else self
		node.reparent(parent)

	func spawn(position: Vector2 = Vector2.ZERO) -> Node:
		var instance: Node
		if _available.is_empty():
			instance = _create_instance()
		else:
			instance = _available.pop_back()

		_active[instance] = true
		_set_active(instance, true)
		instance.global_position = position
		if instance.has_method("_on_spawn"):
			instance.call("_on_spawn")
		return instance

	func despawn(instance: Node) -> void:
		if _active.has(instance):
			if instance.has_method("_on_despawn"):
				instance.call("_on_despawn")
			_active.erase(instance)
			_available.append(instance)
			_set_active(instance, false)
		else:
			push_warning("[Pools] Instance not in pool, freeing instead: ", instance.name)
			instance.queue_free()

func clear():
	for pool in _pools.values():
		if is_instance_valid(pool):
			pool.queue_free()
	_pools.clear()

func register(scene: PackedScene, parent: Node, pool_size: int = 10):
	var scene_name: String = scene.resource_path.get_file().get_basename()
	if _pools.has(scene):
		push_warning("[Pools] Pool already exists for:", scene_name)
		return
	var pool = Pool.new(scene, parent, pool_size)
	_pools[scene] = pool
	add_child(pool)
	print_debug("[Pools] Registered " + scene_name)

func spawn(scene: PackedScene, position: Vector2 = Vector2.ZERO) -> Node:
	var scene_name: String = scene.resource_path.get_file().get_basename()
	if not _pools.has(scene):
		push_warning("[Pools] Pool not found for:", scene_name)
		return null
	return _pools[scene].spawn(position)

func despawn(instance: Node) -> void:
	if instance.has_meta("_pool"):
		var pool: Pool = instance.get_meta("_pool")
		pool.despawn(instance)
	else:
		push_warning("[Pools] Instance does not belong to any pool, freeing instead: ", instance.name)
		instance.queue_free()
