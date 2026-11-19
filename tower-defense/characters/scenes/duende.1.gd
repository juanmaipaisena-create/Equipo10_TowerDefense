extends Node3D
@onready var animation_d= $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	animation_d.play("Idle_Duende")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
