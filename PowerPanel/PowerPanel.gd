extends StaticBody3D

signal power_activated

var current_progress: float = 0.0
@export var hold_time: float = 3.0

func get_prompt(player):
	if not GameManager.has_fuse:
		return "Needs Fuse"
	return "Hold [E] to Activate Power"

func interact_hold(player, delta):
	if GameManager.has_fuse:
		current_progress += (100.0 / hold_time) * delta
		if current_progress >= 100:
			finish_activation()
		return current_progress
	return 0.0

func reset_progress():
	current_progress = 0.0

func finish_activation():
	GameManager.power_on = true
	power_activated.emit()
	print("Power Activated!")
	set_process(false)
