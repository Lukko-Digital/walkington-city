extends RigidBody3D

const SPEED = 800
var direction: Vector3

func _ready():
	#look_at(global_position + direction)
	rotation.y = atan2(direction.x, direction.z)
	apply_central_force(direction * SPEED)

func _on_body_entered(body):
	freeze = true
	set_collision_layer_value(1, true)
