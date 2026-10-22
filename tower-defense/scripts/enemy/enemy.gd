
class_name Enemy
extends CharacterBody3D

signal died
signal reached_base

@export var move_speed: float = 0.5
@export var target_position: Vector3 = Vector3.ZERO
@export var stopping_distance: float = 0.2
@export var max_health: float = 30.0
@export var damage: float = 5.0
@export var base_damage: int = 1
@export var attack_range: float = 1.2
@export var attack_cooldown: float = 1.0
@export var sangre_al_morir: int = 2

var current_health: float = 30.0
var _cooldown: float = 0.0
var _muerto: bool = false
var _llego_a_base: bool = false

@onready var anim: AnimationPlayer = find_child(
	"AnimationPlayer", true, false
)


func _ready() -> void:
	add_to_group("zombies")
	add_to_group("enemies")

	current_health = max_health

	if anim:
		if anim.has_animation("caminar-esqueleto"):
			anim.get_animation("caminar-esqueleto").loop_mode = Animation.LOOP_LINEAR

		if anim.has_animation("idle_esqueleto"):
			anim.get_animation("idle_esqueleto").loop_mode = Animation.LOOP_LINEAR

		_reproducir("caminar-esqueleto")


func _physics_process(delta: float) -> void:
	if _muerto or _llego_a_base:
		return

	if GameManager.game_over or GameManager.paused:
		velocity = Vector3.ZERO
		return

	_cooldown -= delta

	# Primero comprobamos si hay una torre que atacar.
	var objetivo := _defensor_en_rango()

	if objetivo != null:
		velocity = Vector3.ZERO
		move_and_slide()
		_reproducir("idle_esqueleto")

		if _cooldown <= 0.0 and is_instance_valid(objetivo):
			if objetivo.has_method("take_damage"):
				objetivo.take_damage(damage)

			_cooldown = attack_cooldown

		return

	# Nos desplazamos hacia el destino.
	var direction: Vector3 = target_position - global_position
	direction.y = 0.0

	var distance: float = direction.length()

	if distance <= stopping_distance:
		velocity = Vector3.ZERO
		move_and_slide()
		_reproducir("idle_esqueleto")
		_llegada_a_base()
		return

	look_at(global_position + direction.normalized(), Vector3.UP)

	velocity = direction.normalized() * move_speed
	move_and_slide()

	_reproducir("caminar-esqueleto")


func _defensor_en_rango() -> Node3D:
	var mejor: Node3D = null
	var mejor_distancia: float = attack_range

	for node in get_tree().get_nodes_in_group("defensores"):
		var defensor := node as Node3D

		if defensor == null or not is_instance_valid(defensor):
			continue

		# El enemigo ataca solo defensores aproximadamente en su fila.
		if abs(defensor.global_position.z - global_position.z) > 0.6:
			continue

		# El defensor debe estar delante del enemigo.
		var dx: float = global_position.x - defensor.global_position.x

		if dx < -0.3:
			continue

		var distancia: float = global_position.distance_to(
			defensor.global_position
		)

		if distancia <= mejor_distancia:
			mejor = defensor
			mejor_distancia = distancia

	return mejor


func _llegada_a_base() -> void:
	if _llego_a_base or _muerto:
		return

	_llego_a_base = true
	reached_base.emit()

	GameManager.damage_base(base_damage)

	queue_free()


func _reproducir(nombre: String) -> void:
	if anim and anim.has_animation(nombre):
		if anim.current_animation != nombre:
			anim.play(nombre)


func take_damage(amount: float) -> void:
	if _muerto or amount <= 0.0:
		return

	current_health -= amount

	if current_health <= 0.0:
		die()


func is_dead() -> bool:
	return _muerto or _llego_a_base


func die() -> void:
	if _muerto or _llego_a_base:
		return

	_muerto = true

	GameManager.add_money(10)
	died.emit()

	queue_free()
