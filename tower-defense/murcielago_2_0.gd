extends Node3D
@onready var animation_m = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_m.play("Idle_mur")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
