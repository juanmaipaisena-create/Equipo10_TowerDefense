class_name Subdito
extends CharacterBody3D

signal subdito_pressed(subdito: Subdito)
signal died                                   # avisa que desapareció

@export var nombre: String = "Subdito"
@export var max_health: float = 50.0          # vida máxima
@export var damage: float = 5.0               # daño que hace
@export var costo_sangre: int = 1             # sangre que cuesta
@export var sangre_al_sacrificar: int = 2     # sangre que da al sacrificarlo

var celda_actual: BuildCell = null
var current_health: float

# El AnimationPlayer del murciélago (si la escena no lo tiene, queda en null y no se rompe)
@onready var anim: AnimationPlayer = get_node_or_null("Murcielago2_0/AnimationPlayer")


func _ready() -> void:
	input_event.connect(_on_input_event)
	current_health = max_health
	if anim:
		anim.get_animation("Idle_mur").loop_mode = Animation.LOOP_LINEAR   # que se repita
		anim.play("Idle_mur")                                              # lanza la animación


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		subdito_pressed.emit(self)


func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0.0:
		die()


func die() -> void:
	_liberar_celda()
	died.emit()
	queue_free()


func sacrificar() -> void:
	ResourceManager.add("sangre", sangre_al_sacrificar)   # el HUD se actualiza solo
	_liberar_celda()
	died.emit()
	queue_free()


func _liberar_celda() -> void:
	if is_instance_valid(celda_actual):
		celda_actual.set_occupied(false)                  # la celda queda libre otra vez
