extends Button

@export var resource_id: String = "sangre"
@export var costo_por_defecto: int = 10
@export var color_vacio: Color = Color.WHITE
@export var color_lleno: Color = Color(0.85, 0.1, 0.1)
@export var texto_oscuro: Color = Color(0.12, 0.12, 0.14)

var _estilo := StyleBoxFlat.new()
var _costo: int = 10
var _progreso: float = 0.0
var _ultima_cantidad: int = -1
var _tween: Tween
var _incubadora: Node = null
var _mensaje_activo: bool = false


func _ready() -> void:
	_incubadora = get_tree().get_first_node_in_group("incubadora")
	if _incubadora != null:
		_costo = maxi(_incubadora.costo_sangre_combinar, 1)
	else:
		_costo = maxi(costo_por_defecto, 1)

	_estilo.set_corner_radius_all(8)
	for estado in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(estado, _estilo)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	pressed.connect(_on_pressed)

	_ultima_cantidad = ResourceManager.get_amount(resource_id)
	_actualizar(_ultima_cantidad, false)


func _process(_delta: float) -> void:
	var cantidad := ResourceManager.get_amount(resource_id)
	if cantidad != _ultima_cantidad:
		_ultima_cantidad = cantidad
		_actualizar(cantidad, true)


func _actualizar(cantidad: int, animar: bool) -> void:
	var objetivo := clampf(float(cantidad) / float(_costo), 0.0, 1.0)
	if not _mensaje_activo:
		text = "Sacrificio %d/%d" % [mini(cantidad, _costo), _costo]
	disabled = cantidad < _costo

	if _tween:
		_tween.kill()
	if animar:
		_tween = create_tween()
		_tween.tween_method(_pintar, _progreso, objetivo, 0.3)
	else:
		_pintar(objetivo)


func _pintar(valor: float) -> void:
	_progreso = valor
	_estilo.bg_color = color_vacio.lerp(color_lleno, valor)
	var color_texto := texto_oscuro.lerp(Color.WHITE, valor)
	for nombre in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		add_theme_color_override(nombre, color_texto)


func _on_pressed() -> void:
	_gelatina()
	if _incubadora == null:
		return
	var error: String = _incubadora.combinar_en_sacrificio()
	if error != "":
		_mostrar_mensaje(error)


func _mostrar_mensaje(mensaje: String) -> void:
	_mensaje_activo = true
	text = mensaje
	await get_tree().create_timer(1.5).timeout
	_mensaje_activo = false
	_actualizar(ResourceManager.get_amount(resource_id), false)


func _gelatina() -> void:
	pivot_offset = size / 2.0
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 0.85), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
