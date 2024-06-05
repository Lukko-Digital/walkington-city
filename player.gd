extends CharacterBody3D


const MOUSE_SENSITIVITY = 0.001
const CONTROLLER_SENSITIVITY = 0.05
const SPEED = 5.0
const JUMP_VELOCITY = 8.0
const CAMERA_ANGLE_LIMIT = 50

var twist_input := 0.0
var pitch_input := 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var drill_scene = preload("res://drill.tscn")
@onready var twist_pivot = $TwistPivot
@onready var pitch_pivot = $TwistPivot/PitchPivot

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta * 2

	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (twist_pivot.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	handle_camera()

func handle_camera():
	#twist_input = Input.get_axis("look_right", "look_left") * CONTROLLER_SENSITIVITY
	#pitch_input = Input.get_axis("look_down", "look_up") * CONTROLLER_SENSITIVITY * 0.5
	
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(
		pitch_pivot.rotation.x,
		deg_to_rad(-CAMERA_ANGLE_LIMIT),
		deg_to_rad(CAMERA_ANGLE_LIMIT)
	)
	twist_input = 0
	pitch_input = 0
	
	#print($TwistPivot/PitchPivot/Camera3D.global_transform)

func throw_drill():
	var instance = drill_scene.instantiate()
	var camera_dir = -$TwistPivot/PitchPivot/Camera3D.global_transform.basis.z
	instance.position = global_position# + camera_dir * 2
	instance.direction = camera_dir
	get_parent().add_child(instance)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			twist_input = -event.relative.x * MOUSE_SENSITIVITY
			pitch_input = -event.relative.y * MOUSE_SENSITIVITY
	if event.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("throw"):
		throw_drill()
