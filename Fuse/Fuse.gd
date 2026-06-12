extends StaticBody3D

@export var item_name: String = "Fuse"

func interact(player):
	GameManager.has_fuse = true
	print("Picked up Fuse")
	queue_free()
