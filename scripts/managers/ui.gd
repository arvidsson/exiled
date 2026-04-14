extends CanvasLayer

@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var xp_bar: ProgressBar = $XpBar
@onready var hp_label: Label = $HpLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var levelup_panel: Panel = $LevelUpPanel

@onready var options = [
	$LevelUpPanel/Container/Option1,
	$LevelUpPanel/Container/Option2,
	$LevelUpPanel/Container/Option3
]

@onready var player: Player = %Player

var upgrade_pool = [
	{"name":"Increase Health","apply":func(p): p.max_hp += 5; p.current_hp += 5},
	{"name":"Increase Damage","apply":func(p): p.damage += 5}, # BUG
	{"name":"Increase Speed","apply":func(p): p.max_speed += 10},
	{"name":"Stamina Regen","apply":func(p): p.stamina_regen_per_sec += 5},
	{"name":"Increase Ammo","apply":func(p): p.magazine_size += 3; p.total_ammo += 3},
]

var current_choices = []

func _ready():
	Events.ammo_changed.connect(_on_ammo_changed)
	Events.health_changed.connect(_on_health_changed)
	Events.stamina_changed.connect(_on_stamina_changed)
	Events.xp_changed.connect(_on_xp_changed)
	Events.levelup.connect(_on_levelup)
	levelup_panel.visible = false

func _on_ammo_changed(cur: int, max: int):
	ammo_label.text = "%d / %d" % [cur, max]

func _on_health_changed(cur: int, max: int):
	hp_label.text = "%d / %d" % [cur, max]

func _on_stamina_changed(cur: float, max: float):
	stamina_bar.value = cur
	stamina_bar.max_value = max

func _on_xp_changed(cur: int, max: int):
	xp_bar.value = cur
	xp_bar.max_value = max

func _on_levelup():
	var pool = upgrade_pool.duplicate()
	pool.shuffle()
	current_choices = pool.slice(0, 3)
	for i in range(3):
		var rect = options[i]
		rect.get_node("Label").text = current_choices[i]["name"]
	levelup_panel.visible = true
	get_tree().paused = true

func _on_option_pressed(index: int):
	var upgrade = current_choices[index]
	print("Selected upgrade:", upgrade["name"])
	upgrade["apply"].call(player)
	levelup_panel.visible = false
	get_tree().paused = false
