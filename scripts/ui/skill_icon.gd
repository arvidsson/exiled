extends TextureButton

@export var skill: Globals.Skill

@onready var progress_bar: TextureProgressBar = $ProgressBar

func _ready() -> void:
	Events.skill_used.connect(_on_skill_used)

func _on_skill_used(skill: Globals.Skill, cooldown: float):
	if self.skill != skill:
		return
	progress_bar.value = 1.0
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 0.0, cooldown)
