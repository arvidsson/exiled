extends Node

# =========================
# CONFIG
# =========================
@export var sfx_pool_size: int = 10
@export var bus_sfx := "SFX"
@export var bus_music := "Music"

# =========================
# INTERNAL
# =========================
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()

# =========================
# READY
# =========================
func _ready():
	_rng.randomize()

	# Create SFX pool
	for i in sfx_pool_size:
		var p := AudioStreamPlayer.new()
		p.bus = bus_sfx
		add_child(p)
		_sfx_players.append(p)

	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = bus_music
	add_child(_music_player)

# =========================
# SFX
# =========================
func play_sfx(
	stream: AudioStream,
	volume_db: float = 0.0,
	pitch_scale: float = 1.0,
	random_pitch: float = 0.0
):
	var player := _get_free_player()

	player.stream = stream
	player.volume_db = volume_db

	# Optional pitch variation
	if random_pitch > 0.0:
		player.pitch_scale = pitch_scale + _rng.randf_range(-random_pitch, random_pitch)
	else:
		player.pitch_scale = pitch_scale

	player.play()

# Play from array (random variation)
func play_sfx_random(streams: Array):
	if streams.is_empty():
		return

	play_sfx(streams[_rng.randi_range(0, streams.size() - 1)])

# =========================
# MUSIC
# =========================
func play_music(stream: AudioStream, volume_db: float = 0.0):
	if _music_player.stream == stream and _music_player.playing:
		return

	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()

func stop_music():
	_music_player.stop()

func fade_out_music(duration: float = 1.0):
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -80, duration)
	tween.tween_callback(_music_player.stop)

# =========================
# VOLUME CONTROL
# =========================
func set_sfx_volume(db: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_sfx), db)

func set_music_volume(db: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_music), db)

# =========================
# INTERNAL HELPERS
# =========================
func _get_free_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p

	# If all are busy, reuse the first one
	return _sfx_players[0]
