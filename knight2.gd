extends CharacterBody3D

const SPEED = 5.0
const ACCELERATION = 4.0
const JUMP_VELOCITY = 10.0
const ROTATION_SPEED = 12.0
const CAMERA = {
	MAX_LENGTH = 7.0,
	MIN_LENGTH = 2.0,
	HIGHEST_ANGLE = -90.0,
	LOWEST_ANGLE = 30.0,
	MOUSE_SENSITIVITY = 0.0015,
	CONTROLLER_SENSITIVITY = 0.05,
	CONTROLLER_ACCELERATION = 6.0,
	# Speed that camera looks in player's direction when walking
	HORIZONTAL_TRACK_SPEED = 0.5,
	VERTICAL_TRACK_SPEED = 1,
	# Time between last mouse movement and start of camera tracking
	TRACK_DELAY = 0.3,
	# Speed that camera zooms in when camera moves
	MOVEMENT_ZOOM_SPEED = 0.001
}

@onready var camera_arm = $CameraArm
@onready var model = $Rig
@onready var anim_tree = $AnimationTree
@onready var anim_state: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/playback")
@onready var cam_move_timer: Timer = $CameraMovementTimer

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var previously_airborne = true
var jumping: bool:
	set(value):
		anim_tree.set("parameters/conditions/jumping", value)
		jumping = value
var cam_rotation_velocity = Vector2.ZERO

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cam_move_timer.wait_time = CAMERA.TRACK_DELAY

func _process(delta):
	if not Input.get_connected_joypads().is_empty():
		controller_camera_control(delta)

func _physics_process(delta):
	handle_gravity(delta)
	handle_walk(delta)
	handle_jump()
	move_and_slide()
	handle_airborne_animations()
	camera_zoom_out(delta)

func controller_camera_control(delta):
	var controller_input = Input.get_vector("look_down", "look_up", "look_right", "look_left")
	if controller_input:
		cam_move_timer.start()
	cam_rotation_velocity = cam_rotation_velocity.lerp(
		controller_input * CAMERA.CONTROLLER_SENSITIVITY,
		CAMERA.CONTROLLER_ACCELERATION * delta
	)
	camera_arm.rotation.x += cam_rotation_velocity.x
	camera_arm.rotation.y += cam_rotation_velocity.y
	camera_arm.rotation_degrees.x = clamp(camera_arm.rotation_degrees.x, CAMERA.HIGHEST_ANGLE, CAMERA.LOWEST_ANGLE)

func handle_gravity(delta):
	velocity.y -= gravity * delta * 2

func handle_walk(delta):
	var input = Input.get_vector("left", "right", "forward", "back")
	var dir = Vector3(input.x, 0, input.y).rotated(Vector3.UP, camera_arm.rotation.y)
	velocity.x = lerp(velocity.x, dir.x * SPEED, ACCELERATION * delta)
	velocity.z = lerp(velocity.z, dir.z * SPEED, ACCELERATION * delta)
	anim_tree.set("parameters/IdleWalk/blend_position", velocity.length() / SPEED)
	# Rotate model to face walking direction
	model.rotation.y = lerp_angle(model.rotation.y, atan2( - velocity.x, -velocity.z), ROTATION_SPEED * delta)
	# If moving, camera moves to point in walking direction
	if dir and cam_move_timer.is_stopped():
		camera_track(delta)

func handle_jump():
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		jumping = true

func handle_airborne_animations():
	anim_tree.set("parameters/conditions/grounded", is_on_floor())
	if is_on_floor():
		jumping = false
	# Check if airborne and not jumping, e.g. walking off a ledge
	elif not jumping:
		anim_state.travel("Jump_Idle")

func camera_track(delta):
	camera_arm.rotation.y = lerp_angle(camera_arm.rotation.y, model.rotation.y, CAMERA.HORIZONTAL_TRACK_SPEED * delta)
	camera_arm.rotation.x = lerp_angle(camera_arm.rotation.x, 0.0, CAMERA.VERTICAL_TRACK_SPEED * delta)

func camera_zoom_out(delta):
	camera_arm.spring_length = lerp(camera_arm.spring_length, CAMERA.MAX_LENGTH, delta)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		cam_move_timer.start()
		camera_arm.rotation.x -= event.relative.y * CAMERA.MOUSE_SENSITIVITY
		camera_arm.rotation_degrees.x = clamp(camera_arm.rotation_degrees.x, CAMERA.HIGHEST_ANGLE, CAMERA.LOWEST_ANGLE)
		camera_arm.rotation.y -= event.relative.x * CAMERA.MOUSE_SENSITIVITY
		camera_arm.spring_length = lerp(camera_arm.spring_length, CAMERA.MIN_LENGTH, event.relative.length() * CAMERA.MOVEMENT_ZOOM_SPEED)
