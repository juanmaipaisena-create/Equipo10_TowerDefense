extends Node3D

@onready var animation_z = $Zombie_1/AnimationPlayer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_z.play("caminar-esqueleto")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
