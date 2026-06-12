extends CharacterBody3D

enum State {IDLE, PATROL, CHASE}
var current_state = State.PATROL

@export var patrol_speed = 3.0
@export var chase_speed = 6.0
@export var idle_time = 3.0
@export var patrol_points: Array[Vector3] = []

var player = null
var idle_timer: float = 0.0
var current_patrol_index: int = 0
var patrol_forward: bool = true

@onready var nav_agent = $NavigationAgent3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var _chase_color := Color(1, 1, 0)
var _patrol_color := Color(1, 0, 0)
var _idle_color := Color(0.5, 0.5, 0.5)

func _ready():
	var mat = mesh_instance.get_surface_override_material(0).duplicate()
	mesh_instance.set_surface_override_material(0, mat)
	await get_tree().process_frame
	if patrol_points.size() > 0:
		nav_agent.target_position = patrol_points[0]
	else:
		set_new_random_point()

func _physics_process(delta):
	match current_state:
		State.IDLE:
			process_idle(delta)
		State.PATROL:
			process_patrol()
		State.CHASE:
			process_chase()

func process_idle(delta):
	idle_timer -= delta
	if idle_timer <= 0:
		current_state = State.PATROL
		mesh_instance.get_surface_override_material(0).albedo_color = _patrol_color
		advance_patrol_point()

func process_patrol():
	if nav_agent.is_navigation_finished():
		current_state = State.IDLE
		mesh_instance.get_surface_override_material(0).albedo_color = _idle_color
		idle_timer = idle_time
		return
	move_bot(patrol_speed)

func process_chase():
	if player:
		nav_agent.target_position = player.global_position
		move_bot(chase_speed)

func move_bot(speed):
	if nav_agent.is_navigation_finished():
		return
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	velocity = direction * speed
	if velocity.length() > 0.1:
		var look_target = Vector3(next_pos.x, global_position.y, next_pos.z)
		if global_position.distance_to(look_target) > 0.1:
			look_at(look_target, Vector3.UP)
	move_and_slide()

func advance_patrol_point():
	if patrol_points.size() == 0:
		set_new_random_point()
		return
	if patrol_forward:
		current_patrol_index += 1
		if current_patrol_index >= patrol_points.size():
			current_patrol_index = patrol_points.size() - 2
			patrol_forward = false
	else:
		current_patrol_index -= 1
		if current_patrol_index < 0:
			current_patrol_index = 1
			patrol_forward = true
	current_patrol_index = clampi(current_patrol_index, 0, patrol_points.size() - 1)
	nav_agent.target_position = patrol_points[current_patrol_index]

func set_new_random_point():
	var random_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	nav_agent.target_position = global_position + random_dir * 20.0

func _on_detection_zone_body_entered(body):
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASE
		mesh_instance.get_surface_override_material(0).albedo_color = _chase_color

func _on_detection_zone_body_exited(body):
	if body.is_in_group("player"):
		current_state = State.PATROL
		mesh_instance.get_surface_override_material(0).albedo_color = _patrol_color
		if patrol_points.size() > 0:
			nav_agent.target_position = patrol_points[current_patrol_index]
		else:
			set_new_random_point()

func _on_kill_zone_body_entered(body):
	if body.is_in_group("player"):
		print("Player Died!")
		var hud = get_tree().root.find_child("CanvasLayer", true, false)
		if hud and hud.has_method("show_death_screen"):
			hud.show_death_screen()
		else:
			get_tree().reload_current_scene()
