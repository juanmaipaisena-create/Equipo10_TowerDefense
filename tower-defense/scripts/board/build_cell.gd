class_name BuildCell
extends Node3D

signal build_requested(cell: BuildCell)
signal cell_clicked(cell)

@export var normal_color: Color = Color(0.2, 0.7, 0.2)
@export var hover_color: Color = Color(0.8, 0.9, 0.2)
@export var occupied_color: Color = Color(0.15, 0.15, 0.15)

@onready var mesh: MeshInstance3D = $Mesh
@onready var area: Area3D = $Area3D

var occupied: bool = false
var placed_tower: Node3D = null


func _ready() -> void:
	_pintar(normal_color)


# Pinta la celda. Si no tiene material (por ejemplo, después de resaltar(false)), lo crea.
func _pintar(color: Color) -> void:
	if mesh.material_override == null:
		mesh.material_override = StandardMaterial3D.new()
	mesh.material_override.albedo_color = color


# Color de reposo: oscuro si está ocupada, verde si está libre.
func _color_base() -> Color:
	return occupied_color if occupied else normal_color


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cell_clicked.emit(self)


func _on_area_3d_mouse_entered() -> void:
	print("Mouse sobre BuildCell")
	if occupied:
		return
	_pintar(hover_color)


func _on_area_3d_mouse_exited() -> void:
	_pintar(_color_base())


func can_build() -> bool:
	return not occupied


func set_tower(tower: Node3D) -> void:
	placed_tower = tower
	occupied = true


func resaltar(activo: bool) -> void:
	_pintar(Color.SEASHELL if activo else _color_base())


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#solo necesitamos event
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed && can_build():
		if can_build():
			print("Podemos construir aquí")
			build_requested.emit(self)
	else:
		print("Esta celda está ocupada")


func set_occupied(value: bool) -> void:
	occupied = value
	_pintar(_color_base())
