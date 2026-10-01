class_name BuildCell
extends Node3D

@export var normal_color: Color = Color(0.2, 0.7, 0.2)
@export var hover_color: Color = Color(0.8, 0.9, 0.2)

@onready var mesh: MeshInstance3D = $Mesh

var occupied: bool = false

func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = normal_color
	mesh.material_override = material


func _on_area_3d_mouse_entered() -> void:
	print("Mouse sobre BuildCell")
	mesh.material_override.albedo_color = hover_color


func _on_area_3d_mouse_exited() -> void:
	mesh.material_override.albedo_color = normal_color


func can_build() -> bool:
	return not occupied
