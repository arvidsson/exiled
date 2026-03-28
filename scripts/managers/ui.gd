extends CanvasLayer

@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var xp_bar: ProgressBar = $XpBar
@onready var hp_label: Label = $HpLabel
@onready var ammo_label: Label = $AmmoLabel

func _ready():
	Events.ammo_changed.connect(_on_ammo_changed)
	Events.hp_changed.connect(_on_hp_changed)
	Events.stamina_changed.connect(_on_stamina_changed)
	Events.xp_changed.connect(_on_xp_changed)

func _on_ammo_changed(cur: int, max: int):
	ammo_label.text = "%d / %d" % [cur, max]

func _on_hp_changed(cur: int, max: int):
	hp_label.text = "%d / %d" % [cur, max]

func _on_stamina_changed(cur: float, max: float):
	stamina_bar.value = cur
	stamina_bar.max_value = max

func _on_xp_changed(cur: int, max: int):
	xp_bar.value = cur
	xp_bar.max_value = max
