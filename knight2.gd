extends CharacterBody3D


const SPEED = 5.0
const ACCELERATION = 4.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 12.0
const MOUSE_SENSITIVITY = 0.0015

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_arm = $CameraArm
@onready var model = $Rig
@onready var anim_tree = $AnimationTree
@onready var anim_state: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/playback")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	handle_movement(delta)

func handle_movement(delta):
	velocity.y -= gravity * delta
	var input = Input.get_vector("left", "right", "forward", "back")
	var dir = Vector3(input.x, 0, input.y).rotated(Vector3.UP, camera_arm.rotation.y)
	velocity = velocity.lerp(dir * SPEED, ACCELERATION * delta)

	anim_tree.set("parameters/IdleWalk/blend_position", velocity.length() / SPEED)
	move_and_slide()

	model.rotation.y = lerp_angle(model.rotation.y, atan2(-velocity.x, -velocity.z), ROTATION_SPEED * delta)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		camera_arm.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		camera_arm.rotation_degrees.x = clamp(camera_arm.rotation_degrees.x, -90.0, 30.0)
		camera_arm.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
