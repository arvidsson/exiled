extends Node2D

const WALL_THICKNESS := 24.0

@export var level_rect: Rect2 = Rect2(0, 0, 2000, 1500)
@export var grass_count: int = 400
@export var grass_margin: float = 8.0
@export var grass_scenes: Array[PackedScene] = []

@onready var _grass_container: Node2D = $GrassContainer


func _ready() -> void:
	_place_players_at_level_center()
	call_deferred("_sync_follow_camera_to_player")
	_spawn_grass()
	_create_walls()


func _place_players_at_level_center() -> void:
	var c := level_rect.get_center()
	for n in get_tree().get_nodes_in_group("player"):
		if n is Node2D:
			(n as Node2D).global_position = c


func _sync_follow_camera_to_player() -> void:
	var p := get_tree().get_first_node_in_group("player")
	var cam := get_parent().get_node_or_null("FollowCamera")
	if p is Node2D and cam is Node2D:
		(cam as Node2D).global_position = (p as Node2D).global_position


func _spawn_grass() -> void:
	if grass_scenes == null or _grass_container == null:
		return
	var r := level_rect
	var x0 := r.position.x + grass_margin
	var x1 := r.end.x - grass_margin
	var y0 := r.position.y + grass_margin
	var y1 := r.end.y - grass_margin
	if x0 > x1 or y0 > y1:
		return
	for i in grass_count:
		var random_scene: PackedScene = grass_scenes.pick_random()
		var g: Node2D = random_scene.instantiate()
		g.position = Vector2(randf_range(x0, x1), randf_range(y0, y1))
		g.z_index = -2
		_grass_container.add_child(g)


func _create_walls() -> void:
	var bounds := Node2D.new()
	bounds.name = "Bounds"
	add_child(bounds)

	var t := WALL_THICKNESS
	var r := level_rect
	var cx := r.position.x + r.size.x * 0.5
	var cy := r.position.y + r.size.y * 0.5

	_add_wall(bounds, Vector2(r.position.x - t * 0.5, cy), Vector2(t, r.size.y))
	_add_wall(bounds, Vector2(r.end.x + t * 0.5, cy), Vector2(t, r.size.y))
	_add_wall(bounds, Vector2(cx, r.position.y - t * 0.5), Vector2(r.size.x + t * 2.0, t))
	_add_wall(bounds, Vector2(cx, r.end.y + t * 0.5), Vector2(r.size.x + t * 2.0, t))


func _add_wall(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = pos
	var col := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	col.shape = rect_shape
	body.add_child(col)
	parent.add_child(body)
