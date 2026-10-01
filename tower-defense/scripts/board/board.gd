class_name Board
extends Node3D

@export var rows: int = 4
@export var columns: int = 6
@export var cell_size: float = 1.5

@export var build_cell_scene: PackedScene


func _ready() -> void:
	generate_grid()


func generate_grid() -> void:
	for row in range(rows):
		for column in range(columns):
			create_cell(row, column)


func create_cell(row: int, column: int) -> void:
	var cell := build_cell_scene.instantiate()
	add_child(cell)
	var x = (column -(columns -1)/2)*cell_size
	var z = (row - (rows - 1) / 2.0) * cell_size
	cell.position = Vector3(x, 0.2, z)
