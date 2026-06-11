extends CharacterBody3D

enum State {PATROL, CHASE}
var current_state = State.PATROL

@export var patrol_speed = 3.0
@export var chase_speed = 6.0
@export var patrol_radius = 20.0 # How far it can wander

var player = null

@onready var nav_agent = $NavigationAgent3D

func _ready():
	# Wait for navigation map to load
	await get_tree().process_frame
	set_new_patrol_point()

func _physics_process(delta):
	match current_state:
		State.PATROL:
			process_patrol()
		State.CHASE:
			process_chase()

func process_patrol():
	# If we reached the point, pick a new one IMMEDIATELY
	if nav_agent.is_navigation_finished():
		set_new_patrol_point()
	
	move_bot(patrol_speed)

func process_chase():
	if player:
		nav_agent.target_position = player.global_position
		move_bot(chase_speed)

func move_bot(speed):
	if nav_agent.is_navigation_finished():
		return

	var current_pos = global_position
	var next_pos = nav_agent.get_next_path_position()
	
	# Calculate direction and velocity
	var direction = (next_pos - current_pos).normalized()
	velocity = direction * speed
	
	# ROTATION: Make the bot face the direction it is moving
	# We use Vector3.UP to keep it standing upright
	if velocity.length() > 0.1:
		var look_target = Vector3(next_pos.x, global_position.y, next_pos.z)
		# Only look if the target isn't exactly where we are
		if global_position.distance_to(look_target) > 0.1:
			look_at(look_target, Vector3.UP)
	
	move_and_slide()

func set_new_patrol_point():
	# Get a random point around the bot
	var random_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	var target_pos = global_position + (random_dir * patrol_radius)
	
	# Tell the navigation agent to go there
	nav_agent.target_position = target_pos

# --- SIGNALS (Connect these in the Node tab) ---

func _on_detection_zone_body_entered(body):
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASE

func _on_detection_zone_body_exited(body):
	if body.is_in_group("player"):
		current_state = State.PATROL
		set_new_patrol_point() # Resume patrol immediately

func _on_kill_zone_body_entered(body):
	if body.is_in_group("player"):
		print("Player Died!")
		get_tree().reload_current_scene()
