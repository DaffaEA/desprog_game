extends StaticBody3D

signal door_entered

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var blocker: CollisionShape3D = $BlockerCollision

var is_unlocked: bool = false

func _ready():
	if mesh:
		var mat = mesh.get_surface_override_material(0).duplicate()
		mesh.set_surface_override_material(0, mat)

func _process(_delta):
	if not is_unlocked and GameManager.server_on:
		unlock()

func unlock():
	is_unlocked = true
	blocker.disabled = true
	if mesh:
		mesh.get_surface_override_material(0).albedo_color = Color(0, 1, 0)
	print("Exit Door Unlocked!")

func _on_detection_zone_body_entered(body):
	if body.is_in_group("player") and is_unlocked:
		door_entered.emit()
