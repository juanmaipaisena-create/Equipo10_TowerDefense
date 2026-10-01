class_name Incubadora
extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var slots: Board = $SlotsIncubadora
@onready var sacrificio: Board = $ZonaSacrificio


func _ready() -> void:
	apuntar_camara()
	conectar_celdas()


func apuntar_camara() -> void:
	var centro := Vector3(
		(slots.columns - 1) * slots.cell_size / 2.0,
		0.0,
		(slots.rows - 1) * slots.cell_size / 2.0
	)
	camera.position = centro + Vector3(0.0, 6.0, 4.0)
	camera.look_at(centro)


func conectar_celdas() -> void:
	for cell in slots.get_children():
		if cell is BuildCell:
			cell.cell_clicked.connect(_on_slot_clicked)

	for cell in sacrificio.get_children():
		if cell is BuildCell:
			cell.cell_clicked.connect(_on_sacrificio_clicked)


func _on_slot_clicked(cell: BuildCell) -> void:
	print("Clic en slot de incubadora: ", cell)


func _on_sacrificio_clicked(cell: BuildCell) -> void:
	print("Clic en zona de sacrificio: ", cell)
