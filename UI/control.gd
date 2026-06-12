extends CanvasLayer

@onready var win_label: Label = $WinLabel
@onready var death_label: Label = $DeathLabel
@onready var timer_label: Label = $TimerLabel
@onready var status_fuse: Label = $StatusFuse
@onready var status_power: Label = $StatusPower
@onready var status_key: Label = $StatusKey
@onready var status_server: Label = $StatusServer
@onready var restart_label: Label = $RestartLabel

var elapsed_time: float = 0.0
var game_over: bool = false

func _ready():
	death_label.visible = false
	restart_label.visible = false
	update_status()
func _process(delta):
	if not game_over:
		elapsed_time += delta
		timer_label.text = format_time(elapsed_time)
		update_status()

func _unhandled_input(event):
	if game_over and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().paused = false
		GameManager.reset()
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
		GameManager.reset()
		get_tree().reload_current_scene()

func update_status():
	status_fuse.text = "Fuse: Yes" if GameManager.has_fuse else "Fuse: No"
	status_power.text = "Power: Yes" if GameManager.power_on else "Power: No"
	status_key.text = "Key: Yes" if GameManager.has_key else "Key: No"
	status_server.text = "Server: Yes" if GameManager.server_on else "Server: No"

func format_time(t: float) -> String:
	var mins = int(t) / 60
	var secs = int(t) % 60
	return "%02d:%02d" % [mins, secs]
