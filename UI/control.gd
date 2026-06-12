extends CanvasLayer

@onready var win_label: Label = $WinLabel
@onready var death_label: Label = $DeathLabel
@onready var timer_label: Label = $TimerLabel
@onready var key_label: Label = $KeyLabel
@onready var restart_label: Label = $RestartLabel

var elapsed_time: float = 0.0
var game_over: bool = false

func _ready():
	death_label.visible = false
	restart_label.visible = false
	key_label.text = "Key: No"

func _process(delta):
	if not game_over:
		elapsed_time += delta
		timer_label.text = format_time(elapsed_time)

func _unhandled_input(event):
	if game_over and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().paused = false
		get_tree().reload_current_scene()

func show_win_screen():
	game_over = true
	win_label.visible = true
	restart_label.visible = true
	restart_label.text = "Press R to Restart"
	get_tree().paused = true

func show_death_screen():
	game_over = true
	death_label.visible = true
	await get_tree().create_timer(2.0).timeout
	if game_over:
		get_tree().reload_current_scene()

func update_key_status(has_key: bool):
	key_label.text = "Key: Yes" if has_key else "Key: No"

func format_time(t: float) -> String:
	var mins = int(t) / 60
	var secs = int(t) % 60
	return "%02d:%02d" % [mins, secs]
