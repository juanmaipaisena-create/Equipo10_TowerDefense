class_name Enemy
extends CharacterBody3D

@export var move_speed: float = 0.5
@export var target_position: Vector3 = Vector3.ZERO
@export var stopping_distance: float = 0.2

func _physics_process(_delta: float) -> void:
	var direction: Vector3 = target_position - global_position
	var distance: float = direction.length()
	direction.y = 0.0
	if distance <= stopping_distance:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	velocity = direction.normalized() * move_speed

	move_and_slide()
