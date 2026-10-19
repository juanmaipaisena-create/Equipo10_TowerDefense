extends Node3D

@onready var animation_z = $Zombie_1/AnimationPlayer

func _ready() -> void:
	animation_z.play("caminar-esqueleto")
	pass # Replace with function body.



func _process(delta):
	pass
