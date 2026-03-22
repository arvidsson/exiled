extends Node
class_name Pool

const META_OWNER := &"_pool_owner"

## The scene to use for new instances.
@export var template: PackedScene
## Used as parent when spawn() is called with no argument. If null, falls back to this pool's parent.
@export var spawn_parent: Node
## Number of instances to create in _ready (0 = skip).
@export var prewarm_on_ready: int = 0

var _available: Array[Node] = []
var _active := {}
var _spawn_count: int = 0

func _ready() -> void:
	if prewarm_on_ready > 0:
		prewarm(prewarm_on_ready)

func prewarm(count: int) -> void:
	for i in range(count):
		var node := _create_instance()
		_spawn_count += 1
		node.name = "%s_%d" % [node.name, _spawn_count]
		add_child(node)
		_available.append(node)

## Returns a node parented to `parent` when set, otherwise `spawn_parent`, otherwise the pool's parent.
func spawn(parent: Node = null, position: Vector2 = Vector2.ZERO) -> Node:
	var node: Node
	if _available.is_empty():
		node = _create_instance()
		_spawn_count += 1
		node.name = "%s_%d" % [node.name, _spawn_count]
	else:
		node = _available.pop_back()
		if node.get_parent() == self:
			remove_child(node)

	_active[node] = true
	_set_active(node, true)
	var p := parent if parent != null else spawn_parent if spawn_parent != null else get_parent()
	if p != null:
		p.add_child(node)
	if node is Node2D:
		(node as Node2D).global_position = position
	if node.has_method(&"on_spawn"):
		node.on_spawn()
	return node

func despawn(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.get_meta(META_OWNER, null) != self:
		push_warning("Pool.despawn: node does not belong to this pool.")
		return
	if not _active.has(node):
		push_warning("Pool: trying to despawn an inactive node.")
		return

	if node.has_method(&"on_despawn"):
		node.on_despawn()

	var par := node.get_parent()
	if par != null:
		par.remove_child(node)

	_set_active(node, false)
	_active.erase(node)
	add_child(node)
	_available.append(node)

func available_count() -> int:
	return _available.size()

func active_count() -> int:
	return _active.size()

func _create_instance() -> Node:
	assert(template != null, "Pool requires a template scene.")
	var node := template.instantiate() as Node
	node.set_meta(META_OWNER, self )
	_set_active(node, false)
	return node

func _set_active(node: Node, active: bool) -> void:
	if node is CanvasItem:
		(node as CanvasItem).visible = active
	if node is Area2D:
		var area := node as Area2D
		area.monitoring = active
		area.monitorable = active
	elif not active and node is CharacterBody2D:
		# Pooled bodies still collide unless layers are cleared; on_spawn must restore.
		var body := node as CharacterBody2D
		body.collision_layer = 0
		body.collision_mask = 0
	node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
