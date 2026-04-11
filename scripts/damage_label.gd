extends Label

@export var pop_scale: Vector2 = Vector2(0.7, 0.7)
@export var scale_in_duration: float = 0.2
@export var scale_out_duration: float = 0.5
@export var fade_delay: float = 0.4
@export var float_distance: float = 80
@export var float_duration: float = 2.0

func _ready() -> void:
	var t = get_tree().create_tween()
	t.set_parallel(true)
	t.tween_property(self, "scale", pop_scale, scale_in_duration)
	t.tween_property(self, "scale", Vector2.ZERO, scale_out_duration).set_delay(fade_delay)
	t.tween_property(self, "position:y", global_position.y - float_distance, float_duration).set_delay(fade_delay)
	await t.finished
	queue_free()
