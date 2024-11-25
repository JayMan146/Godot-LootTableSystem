extends CharacterBody2D

@export var speed: float

func _physics_process(_delta: float) -> void:
	var horizontal_direction: float = Input.get_axis("move_left", "move_right")
	var vertical_direction: float = Input.get_axis("move_up", "move_down")
	
	velocity = Vector2(horizontal_direction, vertical_direction).normalized() * speed

	move_and_slide()


