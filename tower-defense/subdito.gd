class_name Subdito
extends CharacterBody3D

signal subdito_pressed(subdito: Subdito)

@export var nombre: String = "Subdito"

var celda_actual: BuildCell = null


func _ready() -> void:
	input_event.connect(_on_input_event)


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		subdito_pressed.emit(self)
