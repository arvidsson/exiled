extends Resource
class_name RangeInt

@export var min: int = 0
@export var max: int = 100

func get_random() -> int:
	return randi_range(min, max)

func clamp_value(value: int) -> int:
	return clamp(value, min, max)
