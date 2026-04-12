extends AnimatedSprite2D
class_name Slash

@export var damage: int = 1
@export var hit_frame: int = 2
@onready var area: Area2D = $Area2D
var _has_hit: bool = false

func _ready() -> void:
	# ensure area is not monitoring until hit window
	area.monitoring = false
	# connect signals once (pooled instances keep connections)
	if not frame_changed.is_connected(_on_frame_changed):
		frame_changed.connect(_on_frame_changed)
	if not animation_finished.is_connected(_on_anim_finished):
		animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT)
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)

func _on_spawn() -> void:
	# reset state and start the slash animation
	_has_hit = false
	area.monitoring = false
	frame = 0
	play("default")

func _on_frame_changed() -> void:
	if frame == hit_frame:
		# open a short hit window and rely on body_entered for reliable physics detection
		_has_hit = false
		area.monitoring = true
		# wait a short time so physics can detect overlaps, then close window
		await get_tree().create_timer(0.04).timeout
		area.monitoring = false

func _on_body_entered(body: Node) -> void:
	if _has_hit:
		return
	if body and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		_has_hit = true

func _on_anim_finished() -> void:
	Pools.despawn(self)
