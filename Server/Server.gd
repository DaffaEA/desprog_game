extends StaticBody3D

signal server_rebooted

var current_progress: float = 0.0
@export var hold_time: float = 3.0 # How many seconds to hold

func get_prompt(player):
	if not GameManager.power_on:
		return "No Power"
	if not GameManager.has_key:
		return "Needs Network Key"
	return "Hold [E] to Reboot Server"

func interact_hold(player, delta):
	if GameManager.power_on and GameManager.has_key:
		current_progress += (100.0 / hold_time) * delta
		if current_progress >= 100:
			finish_reboot()
		return current_progress
	return 0.0

func reset_progress():
	current_progress = 0.0

func finish_reboot():
	GameManager.server_on = true
	server_rebooted.emit()
	print("Server Rebooted!")
	set_process(false) # Stop interaction
