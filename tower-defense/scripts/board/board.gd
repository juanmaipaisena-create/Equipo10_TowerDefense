class_name Board
extends Node3D

@export var rows: int = 4
@export var columns: int = 6
@export var cell_size: float = 1.5
@export var build_cell_scene: PackedScene
@export var tower_scene: PackedScene
@export var enemy_scene: PackedScene
@export var campo_de_batalla: bool = false
@export var intervalo_zombies: float = 3.0
@export var x_aparicion: float = 8.0
@export var x_meta: float = -8.0
@export var tower_cost: int = 50


var dragged_entity: Node3D = null
var drag_start_position: Vector3
var drag_start_cell: BuildCell = null
var board_cells: Array[BuildCell] = []

func _ready() -> void:
	generate_grid()
	print("BOARD ", name, " campo: ", campo_de_batalla, " enemy_scene: ", enemy_scene)
	if campo_de_batalla and enemy_scene != null:
		var timer := Timer.new()
		timer.wait_time = intervalo_zombies
		timer.timeout.connect(spawn_zombie)
		add_child(timer)
		timer.start()

func generate_grid() -> void:
	for row in range(rows):
		for column in range(columns):
			create_cell(row, column)

func create_cell(row: int, column: int) -> void:
	var cell := build_cell_scene.instantiate() as BuildCell
	cell.build_requested.connect(_on_cell_build_requested)
	add_child(cell)
	board_cells.append(cell)
	
	var x = (column - (columns - 1) / 2.0) * cell_size
	var z = (row - (rows - 1) / 2.0) * cell_size
	cell.position = Vector3(x, 0.2, z)

func _on_cell_build_requested(cell: BuildCell) -> void:
	if GameManager.game_over:
		return
	if not GameManager.build_mode:
		return
	if not cell.can_build():
		return
	if tower_scene == null:
		push_error("Board: no hay una Tower Scene asignada")
		return
	if not GameManager.can_afford(tower_cost):
		GameManager.status_changed.emit("No tienes monedas suficientes")
		return
	if GameManager.spend_money(tower_cost):
		build_tower(cell)

func build_tower(cell: BuildCell) -> void:
	if tower_scene == null:
		return

	var tower := tower_scene.instantiate() as Node3D
	if tower == null:
		push_error("No se pudo instanciar la torre")
		return

	add_child(tower)
	tower.global_position = cell.global_position
	tower.set("celda_actual", cell)
	if tower.has_signal("subdito_pressed"):
		tower.subdito_pressed.connect(_on_entity_pressed)
	elif tower.has_signal("combinado_pressed"):
		tower.combinado_pressed.connect(_on_entity_pressed)
	cell.set_tower(tower)

func _on_entity_pressed(entity: Node3D) -> void:
	dragged_entity = entity
	drag_start_position = entity.global_position
	drag_start_cell = entity.get("celda_actual")

func _input(event: InputEvent) -> void:
	if dragged_entity and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_drop_entity()

func _physics_process(delta: float) -> void:
	if dragged_entity:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var mouse_pos = get_viewport().get_mouse_position()
			var drop_plane = Plane(Vector3.UP, drag_start_position.y)
			var ray_origin = camera.project_ray_origin(mouse_pos)
			var ray_dir = camera.project_ray_normal(mouse_pos)
			
			var intersection = drop_plane.intersects_ray(ray_origin, ray_dir)
			if intersection:
				dragged_entity.global_position = dragged_entity.global_position.lerp(intersection, 25.0 * delta)

func _drop_entity() -> void:
	var nearest_cell: BuildCell = null
	var min_dist: float = INF
	
	for cell in board_cells:
		var dist = dragged_entity.global_position.distance_to(cell.global_position)
		if dist < min_dist and dist < cell_size:
			min_dist = dist
			nearest_cell = cell

	if nearest_cell and nearest_cell != drag_start_cell:
		if not nearest_cell.can_build():
			intentar_combinar_subdito(nearest_cell, dragged_entity, drag_start_cell)
		else:
			_mover_a_celda(dragged_entity, nearest_cell)
	else:
		dragged_entity.global_position = drag_start_position
		
	dragged_entity = null
	drag_start_cell = null

func _mover_a_celda(entity: Node3D, target_cell: BuildCell) -> void:
	if drag_start_cell:
		drag_start_cell.set_occupied(false)
		
	target_cell.set_occupied(true)
	entity.set("celda_actual", target_cell)
	entity.global_position = target_cell.global_position

func intentar_combinar_subdito(target_cell: BuildCell, entity: Node3D, origin_cell: BuildCell) -> void:
	entity.global_position = drag_start_position


func spawn_zombie() -> Enemy:
	if enemy_scene == null:
		push_error("Board: asigna Enemy Scene en el Inspector")
		return null
	if rows <= 0:
		push_error("Board: rows debe ser mayor que cero")
		return null
	var fila: int = randi_range(0, rows - 1)
	var z: float = (fila - (rows - 1) / 2.0) * cell_size
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		push_error("Board: Enemy Scene no tiene el script Enemy")
		return null
	add_child(enemy)
	enemy.global_position = to_global(
		Vector3(x_aparicion, 0.0, z)
	)
	enemy.target_position = to_global(
		Vector3(x_meta, 0.0, z)
	)
	return enemy
