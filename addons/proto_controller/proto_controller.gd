# ProtoController v1.1 (Modified with Interaction System)
# Original by Brackeys - CC0 License

extends CharacterBody3D

@export_group("Movement Ability")
@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_sprint : bool = true
@export var can_freefly : bool = false

@export_group("Speeds")
@export var look_speed : float = 0.002
@export var base_speed : float = 7.0
@export var jump_velocity : float = 4.5
@export var sprint_speed : float = 10.0
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
@export var input_left : String = "move_left"
@export var input_right : String = "move_right"
@export var input_forward : String = "move_forward" # Changed to match common WASD setup
@export var input_back : String = "move_back"
@export var input_jump : String = "ui_accept"
@export var input_sprint : String = "sprint"
@export var input_interact : String = "interact" # Added for Key/Server
@export var input_freefly : String = "freefly"

@export_group("Interaction References")
## Drag your Head/RayCast3D here
@onready var interaction_ray : RayCast3D = $Head/RayCast3D 
## Path to your HUD labels (Adjust if paths are different)
@onready var prompt_label : Label = get_tree().root.find_child("InteractPrompt", true, false)
@onready var progress_bar : ProgressBar = get_tree().root.find_child("InteractBar", true, false)

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

# GAME STATE
var has_network_key : bool = false
var pickup_msg_timer: float = 0.0
var is_dead: bool = false

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying: enable_freefly()
		else: disable_freefly()

func _process(delta: float) -> void:
	handle_interaction(delta)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if global_position.y < -10:
		is_dead = true
		var hud = get_tree().root.find_child("CanvasLayer", true, false)
		if hud and hud.has_method("show_death_screen"):
			hud.show_death_screen()
		return
	
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta

	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

	move_speed = sprint_speed if can_sprint and Input.is_action_pressed(input_sprint) else base_speed

	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.z = 0
	
	move_and_slide()

## INTERACTION SYSTEM LOGIC
func handle_interaction(delta: float):
	if pickup_msg_timer > 0:
		pickup_msg_timer -= delta
		if pickup_msg_timer <= 0:
			clear_hud()
		return
	
	if interaction_ray.is_colliding():
		var obj = interaction_ray.get_collider()
		
		if obj.has_method("interact"):
			update_hud(obj.item_name if "item_name" in obj else "Item", false)
			if Input.is_action_just_pressed(input_interact):
				obj.interact(self)
				var hud = get_tree().root.find_child("CanvasLayer", true, false)
				if hud and hud.has_method("update_key_status"):
					hud.update_key_status(true)
				update_hud("Picked up " + (obj.item_name if "item_name" in obj else "Item"), false)
				pickup_msg_timer = 2.0
		
		# 2. Handle Hold Interactions (Server)
		elif obj.has_method("interact_hold"):
			var prompt = obj.get_prompt(self) if obj.has_method("get_prompt") else "Hold to interact"
			update_hud(prompt, Input.is_action_pressed(input_interact))
			
			if Input.is_action_pressed(input_interact):
				var progress = obj.interact_hold(self, delta)
				if progress_bar: progress_bar.value = progress
			else:
				if obj.has_method("reset_progress"): obj.reset_progress()
		
		else:
			clear_hud()
	else:
		clear_hud()

func update_hud(text: String, show_bar: bool):
	if prompt_label: prompt_label.text = text
	if progress_bar: progress_bar.visible = show_bar

func clear_hud():
	if prompt_label: prompt_label.text = ""
	if progress_bar: 
		progress_bar.visible = false
		progress_bar.value = 0

## HELPER FUNCTIONS
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func check_input_mappings():
	var actions = [input_left, input_right, input_forward, input_back, input_jump, input_interact]
	for action in actions:
		if not InputMap.has_action(action):
			push_error("Missing InputAction: " + action)
