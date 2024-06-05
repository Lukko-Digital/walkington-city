extends RigidBody3D

const SPEED = 800
var direction: Vector3 = Vector3.FORWARD

func _ready():
	apply_central_force(direction * SPEED)
