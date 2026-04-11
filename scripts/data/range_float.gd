extends Resource
class_name RangeFloat

@export var min: float = 0
@export var max: float = 100

func get_random() -> float:
	return randf_range(min, max)

func clamp_value(value: float) -> float:
	return clamp(value, min, max)
