extends StaticBody3D

@export var item_name: String = "Network Key"

func interact(player):
	if not GameManager.power_on:
		return
	GameManager.has_key = true
	print("Picked up Network Key")
	queue_free() # Remove the key from the map
