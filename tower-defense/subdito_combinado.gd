class_name SubditoCombinado
extends CharacterBody3D

signal combinado_pressed(combinado: SubditoCombinado)
signal died

@export var nombre: String = "Subdito Combinado"
@export var max_health: float = 18.0
@export var damage: float = 3.0
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 1.0

var celda_actual: BuildCell = null
var current_health: float
var en_combate: bool = false
var _cooldown: float = 0.0


func _ready() -> void:
	input_event.connect(_on_input_event)
	current_health = max_health


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		combinado_pressed.emit(self)


func set_en_combate(valor: bool) -> void:
	en_combate = valor
	if valor:
		add_to_group("defensores")
	else:
		remove_from_group("defensores")


func _physics_process(delta: float) -> void:
	if not en_combate:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return

	var zombie := _zombie_en_rango()
	if zombie != null:
		zombie.take_damage(damage)
		_cooldown = attack_cooldown


func _zombie_en_rango() -> Enemy:
	var mejor: Enemy = null
	var mejor_dx := attack_range
	for z in get_tree().get_nodes_in_group("zombies"):
		var zombie := z as Enemy
		if zombie == null:
			continue
		if abs(zombie.global_position.z - global_position.z) > 0.6:
			continue
		var dx := zombie.global_position.x - global_position.x
		if dx >= -0.3 and dx <= mejor_dx:
			mejor = zombie
			mejor_dx = dx
	return mejor


func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0.0:
		die()


func die() -> void:
	if is_instance_valid(celda_actual):
		celda_actual.placed_tower = null
		celda_actual.set_occupied(false)
	died.emit()
	queue_free()
