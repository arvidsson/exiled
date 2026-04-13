class_name Tools
extends Node

## Instantiates a scene at a position and adds it to a parent.
static func instantiate_at_position(scene: PackedScene, parent: Node, pos: Vector2) -> Node:
	var instance = scene.instantiate()
	parent.add_child(instance)
	instance.global_position = pos
	return instance

# Creates a progress timer and starts it immediately.
static func start_progress_timer(time: float, callback: Callable) -> ProgressTimer:
	var timer = ProgressTimer.new()
	timer.start(time)
	timer.get_tree().create_timer(time).timeout.connect(callback)
	return timer

## Creates a tween and starts it immediately.
static func tween_property(node: Node, property: String, to, duration: float) -> Tween:
	var tween = node.create_tween()
	tween.tween_property(node, property, to, duration)
	return tween

## Starts a one-shot scene-tree delay. Disconnect `callback` from the returned
## timer's `timeout` (or drop your reference after disconnecting) to cancel early.
static func call_delay(parent: Node, time: float, callback: Callable) -> SceneTreeTimer:
	var timer := parent.get_tree().create_timer(time)
	timer.timeout.connect(callback, CONNECT_ONE_SHOT)
	return timer
