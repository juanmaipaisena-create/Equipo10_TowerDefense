class_name Board
extends Node3D

@export var rows: int = 4
@export var columns: int = 6
@export var cell_size: float = 1.5

@export var build_cell_scene: PackedScene
@export var tower_scene: PackedScene
@export var enemy_scene: PackedScene


func _ready() -> void:
	generate_grid()
	spawn_test_enemy()


func generate_grid() -> void:
	for row in range(rows):
		for column in range(columns):
			create_cell(row, column)

#76
func create_cell(row: int, column: int) -> void:
	var cell := build_cell_scene.instantiate()
	cell.build_requested.connect(_on_cell_build_requested)
	add_child(cell)
	var x = (column -(columns -1)/2)*cell_size
	var z = (row - (rows - 1) / 2.0) * cell_size
	cell.position = Vector3(x, 0.2, z)

func _on_cell_build_requested(cell: BuildCell) -> void:
	if not cell.can_build():
		return
	build_tower(cell)
	
func build_tower(cell: BuildCell) -> void:
	var tower := tower_scene.instantiate() as Tower
	add_child(tower)
	tower.global_position = cell.global_position
	cell.set_occupied(true)
	
func spawn_test_enemy() -> void:
	if enemy_scene == null:
		push_error("No se ha asignado enemy_scene en Main")
		return
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		push_error("No se pudo crear el enemigo")
		return
	add_child(enemy)
	enemy.global_position = Vector3(8.0, 0.0, 0.0)
	enemy.target_position = Vector3(0.0, 0.0, 0.0)
