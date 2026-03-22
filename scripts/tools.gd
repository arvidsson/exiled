class_name Tools
extends Node

static func instantiate_at_position(scene: PackedScene, parent: Node, pos: Vector3) -> Node:
	var instance = scene.instantiate()
	parent.add_child(instance)
	instance.global_position = pos
	return instance

static func start_progress_timer(time: float, callback: Callable) -> ProgressTimer:
	var timer = ProgressTimer.new()
	Refs.level_container.add_child(timer)
	timer.start(time)
	timer.get_tree().create_timer(time).timeout.connect(callback)
	return timer

static func tween_property(node: Node, property: String, to, duration: float) -> Tween:
	var tween = node.create_tween()
	tween.tween_property(node, property, to, duration)
	return tween

static func call_delay(parent: Node, time: float, callback: Callable) -> void:
	parent.get_tree().create_timer(time).timeout.connect(callback)
