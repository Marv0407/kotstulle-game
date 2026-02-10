extends CharacterBody2D

@export var speed := 200.0

func _physics_process(delta):
	var direction := Vector2.ZERO

	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()
