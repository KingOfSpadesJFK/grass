extends CharacterBody3D


const SPEED = 1.5
const JUMP_VELOCITY = 4.5


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var sensitivity := 0.1
		var mouse_vel := Vector2(event.relative.x, event.relative.y) * sensitivity
		$Head.rotate_y(-event.relative.x * 0.01)
		$Head/Eye.rotate_x(-event.relative.y * 0.01)
		$Head/Eye.rotation.x = clamp($Head/Eye.rotation.x, -1.5, 1.5)


func _physics_process(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("player_left", "player_right", "player_up", "player_down")
	var direction: Vector3 = ($Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		var speed = SPEED
		if Input.is_action_pressed("player_sprint"):
			speed *= 2
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
