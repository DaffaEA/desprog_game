extends StaticBody3D

signal server_rebooted

var current_progress: float = 0.0
@export var hold_time: float = 3.0 # How many seconds to hold

func get_prompt(player):
	if not player.has_network_key:
		return "Needs Network Key"
	return "Hold [E] to Reboot Server"

func interact_hold(player, delta):
	if player.has_network_key:
		current_progress += (100.0 / hold_time) * delta
		if current_progress >= 100:
			finish_reboot()
		return current_progress
	return 0.0

func reset_progress():
	current_progress = 0.0

func finish_reboot():
	server_rebooted.emit()
	print("Server Rebooted! Emergency Exit Open.")
	set_process(false) # Stop interaction
