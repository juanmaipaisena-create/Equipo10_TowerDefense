class_name Incubadora
extends Node3D

@export var subdito_scene: PackedScene
@export var subdito_combinado_scene: PackedScene
@export var intervalo_generacion: float = 5.0
@export var costo_sangre_combinar: int = 10

@onready var camera: Camera3D = $Camera3D
@onready var slots: Board = $SlotsIncubadora
@onready var sacrificio: Board = $ZonaSacrificio
@onready var timer_generacion: Timer = $TimerGeneracion

var subdito_arrastrado: Subdito = null
var celda_origen: BuildCell = null


func _ready() -> void:
	apuntar_camara()
	conectar_celdas()
	timer_generacion.wait_time = intervalo_generacion
	timer_generacion.timeout.connect(_on_timer_generacion_timeout)
	_on_timer_generacion_timeout()
	timer_generacion.start()

	ResourceManager.resource_changed.connect(_on_resource_changed)
	_actualizar_resaltado_sacrificio(ResourceManager.get_amount("sangre"))


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


func _on_timer_generacion_timeout() -> void:
	var celda_libre := _buscar_celda_libre(slots)
	if celda_libre == null:
		return
	_colocar_subdito_nuevo(celda_libre)


func _buscar_celda_libre(board: Board) -> BuildCell:
	for cell in board.get_children():
		if cell is BuildCell and cell.can_build():
			return cell
	return null


func _colocar_subdito_nuevo(cell: BuildCell) -> void:
	var subdito := subdito_scene.instantiate() as Subdito
	cell.add_child(subdito)
	subdito.position = Vector3(0, 0.5, 0)
	cell.set_tower(subdito)
	subdito.celda_actual = cell
	subdito.subdito_pressed.connect(_on_subdito_pressed)


func _on_slot_clicked(cell: BuildCell) -> void:
	pass


func _on_sacrificio_clicked(cell: BuildCell) -> void:
	pass


func _on_subdito_pressed(subdito: Subdito) -> void:
	if subdito_arrastrado != null:
		return

	subdito_arrastrado = subdito
	celda_origen = subdito.celda_actual
	celda_origen.occupied = false
	celda_origen.placed_tower = null

	subdito.reparent(self, true)


func _process(_delta: float) -> void:
	if subdito_arrastrado == null:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var origen := camera.project_ray_origin(mouse_pos)
	var direccion := camera.project_ray_normal(mouse_pos)
	var plano := Plane(Vector3.UP, subdito_arrastrado.global_position.y)
	var punto = plano.intersects_ray(origen, direccion)

	if punto != null:
		subdito_arrastrado.global_position = punto

#arrastrar als subdito a la parte de sacrificio y usar z para generar monedas
func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventKey and event.pressed and event.keycode == KEY_Z:
		ResourceManager.add("sangre", 5)

	if subdito_arrastrado == null:
		return

	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_soltar_subdito()
	if subdito_arrastrado == null:
		return

	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_soltar_subdito()


func _soltar_subdito() -> void:
	var celda_destino := _celda_bajo_mouse(sacrificio)

	if celda_destino == null:
		_devolver_a_origen()
	elif celda_destino.can_build():
		_colocar_en_celda(subdito_arrastrado, celda_destino)
	elif celda_destino.placed_tower is Subdito:
		_intentar_combinar(celda_destino)
	else:
		_devolver_a_origen()

	subdito_arrastrado = null
	celda_origen = null


func _celda_bajo_mouse(board: Board) -> BuildCell:
	var mouse_pos := get_viewport().get_mouse_position()
	var origen := camera.project_ray_origin(mouse_pos)
	var direccion := camera.project_ray_normal(mouse_pos) * 100.0

	var espacio := get_world_3d().direct_space_state
	var consulta := PhysicsRayQueryParameters3D.create(origen, origen + direccion)
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false

	var resultado := espacio.intersect_ray(consulta)
	if resultado.is_empty():
		return null

	var area = resultado["collider"]
	var celda = area.get_parent()
	if celda is BuildCell and celda in board.get_children():
		return celda

	return null


func _devolver_a_origen() -> void:
	subdito_arrastrado.reparent(celda_origen, true)
	subdito_arrastrado.position = Vector3(0, 0.5, 0)
	celda_origen.set_tower(subdito_arrastrado)
	subdito_arrastrado.celda_actual = celda_origen


func _colocar_en_celda(subdito: Subdito, celda: BuildCell) -> void:
	subdito.reparent(celda, true)
	subdito.position = Vector3(0, 0.5, 0)
	celda.set_tower(subdito)
	subdito.celda_actual = celda


func _intentar_combinar(celda: BuildCell) -> void:
	if not ResourceManager.spend("sangre", costo_sangre_combinar):
		_devolver_a_origen()
		return

	var subdito_existente := celda.placed_tower as Subdito
	subdito_existente.queue_free()
	subdito_arrastrado.queue_free()

	celda.occupied = false
	celda.placed_tower = null

	var combinado := subdito_combinado_scene.instantiate() as SubditoCombinado
	celda.add_child(combinado)
	combinado.position = Vector3(0, 0.5, 0)
	celda.set_tower(combinado)


func _on_resource_changed(id: String, new_amount: int) -> void:
	if id == "sangre":
		_actualizar_resaltado_sacrificio(new_amount)


func _actualizar_resaltado_sacrificio(cantidad_sangre: int) -> void:
	var activo := cantidad_sangre >= costo_sangre_combinar
	for cell in sacrificio.get_children():
		if cell is BuildCell:
			cell.resaltar(activo)
