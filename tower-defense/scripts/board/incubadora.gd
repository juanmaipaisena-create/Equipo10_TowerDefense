class_name Incubadora
extends Node3D

@export var subdito_scene: PackedScene
@export var subdito_combinado_scene: PackedScene
@export var escenas_combinado: Array[PackedScene] = []
@export var intervalo_generacion: float = 3.0
@export var costo_combinar_base: int = 15
@export var aumento_costo_por_nivel: int = 5
@export var oleada_para_combinados: int = 3
@export var costo_combinado_incubadora: int = 30
@export var minutos_minimo: float = 2.0
@export var minutos_maximo: float = 5.0

@onready var camera: Camera3D = $Camera3D
@onready var slots: Board = $SlotsIncubadora
@onready var sacrificio: Board = $ZonaSacrificio
@onready var timer_generacion: Timer = $TimerGeneracion

var costo_sangre_combinar: int = 15
var subdito_arrastrado: Subdito = null
var celda_origen: BuildCell = null
var combinado_arrastrado: SubditoCombinado = null
var celda_origen_combinado: BuildCell = null

var _timer_combinado: Timer
var _combinado_programado: bool = false
var _combinado_pendiente: bool = false


func _ready() -> void:
	add_to_group("incubadora")
	costo_sangre_combinar = costo_combinar_base
	apuntar_camara()
	conectar_celdas()

	_timer_combinado = Timer.new()
	_timer_combinado.one_shot = true
	_timer_combinado.timeout.connect(_on_timer_combinado_timeout)
	add_child(_timer_combinado)
	GameManager.wave_changed.connect(_on_wave_changed)
	_on_wave_changed(GameManager.current_wave)

	timer_generacion.wait_time = intervalo_generacion
	timer_generacion.timeout.connect(_on_timer_generacion_timeout)
	_on_timer_generacion_timeout()
	timer_generacion.start()

	ResourceManager.resource_changed.connect(_on_resource_changed)
	_actualizar_resaltado_sacrificio(ResourceManager.get_amount("sangre"))


func _costo_para_nivel(nivel: int) -> int:
	return costo_combinar_base + aumento_costo_por_nivel * (maxi(nivel, 1) - 1)


func _escena_para_nivel(nivel: int) -> PackedScene:
	if escenas_combinado.is_empty():
		return subdito_combinado_scene
	return escenas_combinado[mini(nivel - 1, escenas_combinado.size() - 1)]


func _celda_libre(celda: BuildCell) -> bool:
	return celda.placed_tower == null and not celda.occupied


func _ocupar(celda: BuildCell, nodo: Node3D) -> void:
	celda.placed_tower = nodo
	celda.set_occupied(true)
	var tablero := celda.get_parent() as Board
	var en_campo := tablero != null and tablero.campo_de_batalla
	if nodo.has_method("set_en_combate"):
		nodo.set_en_combate(en_campo)


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
	_intentar_aparecer_combinado()
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


func _on_wave_changed(wave: int) -> void:
	if wave >= oleada_para_combinados and not _combinado_programado:
		_combinado_programado = true
		_programar_combinado()


func _programar_combinado() -> void:
	_combinado_pendiente = false
	_timer_combinado.start(randf_range(minutos_minimo, minutos_maximo) * 60.0)


func _on_timer_combinado_timeout() -> void:
	_combinado_pendiente = true
	_intentar_aparecer_combinado()


func _intentar_aparecer_combinado() -> void:
	if not _combinado_pendiente or _escena_para_nivel(1) == null:
		return
	if GameManager.game_over:
		return
	var celda := _buscar_celda_libre(slots)
	if celda == null:
		return
	if not ResourceManager.can_afford("sangre", costo_combinado_incubadora):
		return

	ResourceManager.spend("sangre", costo_combinado_incubadora)
	_crear_combinado_en(celda, 1)
	GameManager.status_changed.emit("¡Apareció un súbdito combinado!")
	_programar_combinado()


func _crear_combinado_en(celda: BuildCell, nivel: int) -> void:
	var combinado := _escena_para_nivel(nivel).instantiate() as SubditoCombinado
	celda.add_child(combinado)
	combinado.position = Vector3(0, 0.5, 0)
	combinado.set_nivel(nivel)
	_ocupar(celda, combinado)
	combinado.celda_actual = celda
	combinado.combinado_pressed.connect(_on_combinado_pressed)


func _on_slot_clicked(cell: BuildCell) -> void:
	pass


func _on_sacrificio_clicked(cell: BuildCell) -> void:
	pass


func _on_subdito_pressed(subdito: Subdito) -> void:
	if subdito_arrastrado != null or combinado_arrastrado != null:
		return

	subdito_arrastrado = subdito
	subdito.set_en_combate(false)
	celda_origen = subdito.celda_actual
	celda_origen.occupied = false
	celda_origen.placed_tower = null

	subdito.reparent(self, true)


func _on_combinado_pressed(combinado: SubditoCombinado) -> void:
	if combinado_arrastrado != null or subdito_arrastrado != null:
		return
	if combinado.celda_actual == null:
		return

	combinado_arrastrado = combinado
	combinado.set_en_combate(false)
	celda_origen_combinado = combinado.celda_actual
	celda_origen_combinado.occupied = false
	celda_origen_combinado.placed_tower = null

	combinado.reparent(self, true)


func _camara_activa() -> Camera3D:
	return get_viewport().get_camera_3d()


func _process(_delta: float) -> void:
	_refrescar_costo()

	var arrastrado: Node3D = subdito_arrastrado if subdito_arrastrado != null else combinado_arrastrado
	if arrastrado == null:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var camara := _camara_activa()
	var origen := camara.project_ray_origin(mouse_pos)
	var direccion := camara.project_ray_normal(mouse_pos)
	var plano := Plane(Vector3.UP, arrastrado.global_position.y)
	var punto = plano.intersects_ray(origen, direccion)

	if punto != null:
		arrastrado.global_position = punto


func _refrescar_costo() -> void:
	var pareja := _buscar_pareja()
	var nuevo := _costo_para_nivel(pareja["nivel"])
	if nuevo != costo_sangre_combinar:
		costo_sangre_combinar = nuevo
		_actualizar_resaltado_sacrificio(ResourceManager.get_amount("sangre"))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_Z:
		ResourceManager.add("sangre", 5)

	var soltar: bool = event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not soltar:
		return

	if subdito_arrastrado != null:
		_soltar_subdito()
	elif combinado_arrastrado != null:
		_soltar_combinado()


func _soltar_subdito() -> void:
	var celda_destino := _celda_bajo_mouse_cualquiera()

	if celda_destino == null:
		_devolver_a_origen()
	elif celda_destino.get_parent() == sacrificio:
		if _celda_libre(celda_destino):
			_colocar_en_celda(subdito_arrastrado, celda_destino)
		elif celda_destino.placed_tower is Subdito:
			_intentar_combinar(celda_destino)
		else:
			_devolver_a_origen()
	elif _celda_libre(celda_destino):
		_colocar_en_celda(subdito_arrastrado, celda_destino)
	else:
		_devolver_a_origen()

	subdito_arrastrado = null
	celda_origen = null


func _soltar_combinado() -> void:
	var celda := _celda_bajo_mouse_cualquiera()

	if celda != null and _celda_libre(celda):
		combinado_arrastrado.reparent(celda, true)
		combinado_arrastrado.position = Vector3(0, 0.5, 0)
		_ocupar(celda, combinado_arrastrado)
		combinado_arrastrado.celda_actual = celda
	else:
		_devolver_combinado_a_origen()

	combinado_arrastrado = null
	celda_origen_combinado = null


func _celda_bajo_mouse_cualquiera() -> BuildCell:
	var mouse_pos := get_viewport().get_mouse_position()
	var camara := _camara_activa()
	var origen := camara.project_ray_origin(mouse_pos)
	var direccion := camara.project_ray_normal(mouse_pos) * 100.0

	var espacio := get_world_3d().direct_space_state
	var consulta := PhysicsRayQueryParameters3D.create(origen, origen + direccion)
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false

	var resultado := espacio.intersect_ray(consulta)
	if resultado.is_empty():
		return null

	var celda = resultado["collider"].get_parent()
	if celda is BuildCell:
		return celda
	return null


func _celda_bajo_mouse(board: Board) -> BuildCell:
	var celda := _celda_bajo_mouse_cualquiera()
	if celda != null and celda.get_parent() == board:
		return celda
	return null


func _devolver_a_origen() -> void:
	subdito_arrastrado.reparent(celda_origen, true)
	subdito_arrastrado.position = Vector3(0, 0.5, 0)
	_ocupar(celda_origen, subdito_arrastrado)
	subdito_arrastrado.celda_actual = celda_origen


func _devolver_combinado_a_origen() -> void:
	combinado_arrastrado.reparent(celda_origen_combinado, true)
	combinado_arrastrado.position = Vector3(0, 0.5, 0)
	_ocupar(celda_origen_combinado, combinado_arrastrado)
	combinado_arrastrado.celda_actual = celda_origen_combinado


func _colocar_en_celda(subdito: Subdito, celda: BuildCell) -> void:
	subdito.reparent(celda, true)
	subdito.position = Vector3(0, 0.5, 0)
	_ocupar(celda, subdito)
	subdito.celda_actual = celda


func _intentar_combinar(celda: BuildCell) -> void:
	if not ResourceManager.spend("sangre", _costo_para_nivel(1)):
		_devolver_a_origen()
		return

	if _escena_para_nivel(1) == null:
		push_error("Falta asignar Subdito Combinado Scene en la Incubadora")
		_devolver_a_origen()
		return

	var subdito_existente := celda.placed_tower as Subdito
	subdito_existente.queue_free()
	subdito_arrastrado.queue_free()

	celda.placed_tower = null
	celda.set_occupied(false)

	_crear_combinado_en(celda, 1)


func _buscar_pareja() -> Dictionary:
	var subditos: Array = []
	var combinados: Dictionary = {}
	for hijo in sacrificio.get_children():
		var celda := hijo as BuildCell
		if celda == null:
			continue
		var torre = celda.placed_tower
		if torre is Subdito:
			subditos.append(celda)
		elif torre is SubditoCombinado:
			var nivel: int = torre.nivel
			if not combinados.has(nivel):
				combinados[nivel] = []
			combinados[nivel].append(celda)

	if subditos.size() >= 2:
		return {"pareja": [subditos[0], subditos[1]], "nivel": 1}

	var niveles: Array = combinados.keys()
	niveles.sort()
	for nivel in niveles:
		if combinados[nivel].size() >= 2:
			return {"pareja": [combinados[nivel][0], combinados[nivel][1]], "nivel": nivel + 1}

	return {"pareja": [], "nivel": 1}


func combinar_en_sacrificio() -> String:
	if _escena_para_nivel(1) == null:
		return "Falta la escena del combinado"

	var resultado := _buscar_pareja()
	var pareja: Array = resultado["pareja"]
	var nivel_resultado: int = resultado["nivel"]

	if pareja.is_empty():
		for hijo in sacrificio.get_children():
			var celda := hijo as BuildCell
			if celda != null and celda.placed_tower != null:
				print("Sacrificio: ", celda.name, " -> ", celda.placed_tower, " nivel ", celda.placed_tower.get("nivel"))
		return "Poné 2 iguales en el sacrificio"

	if not ResourceManager.spend("sangre", _costo_para_nivel(nivel_resultado)):
		return "Falta sangre"

	var celda_resultado: BuildCell = pareja[0]
	for celda in pareja:
		celda.placed_tower.queue_free()
		celda.placed_tower = null
		celda.set_occupied(false)

	_crear_combinado_en(celda_resultado, nivel_resultado)
	return ""


func _on_resource_changed(id: String, new_amount: int) -> void:
	if id == "sangre":
		_actualizar_resaltado_sacrificio(new_amount)


func _actualizar_resaltado_sacrificio(cantidad_sangre: int) -> void:
	var activo := cantidad_sangre >= costo_sangre_combinar
	for cell in sacrificio.get_children():
		if cell is BuildCell:
			cell.resaltar(activo)
