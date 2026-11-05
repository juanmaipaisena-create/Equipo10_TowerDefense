class_name Enemy
extends CharacterBody3D

signal died

@export var move_speed: float = 0.5
@export var target_position: Vector3 = Vector3.ZERO
@export var stopping_distance: float = 0.2
@export var max_health: float = 9.0
@export var damage: float = 3.0
@export var attack_range: float = 1.2
@export var attack_cooldown: float = 1.0
@export var sangre_al_morir: int = 2

var current_health: float
var _cooldown: float = 0.0
var _muerto: bool = false

@onready var anim: AnimationPlayer = find_child("AnimationPlayer", true, false)


func _ready() -> void:
	add_to_group("zombies")
	current_health = max_health
	if anim:
		anim.get_animation("caminar-esqueleto").loop_mode = Animation.LOOP_LINEAR
		anim.get_animation("idle_esqueleto").loop_mode = Animation.LOOP_LINEAR
		anim.play("caminar-esqueleto")


func _physics_process(delta: float) -> void:
	_cooldown -= delta

	
	var objetivo := _defensor_en_rango()
	if objetivo != null:
		velocity = Vector3.ZERO
		move_and_slide()
		_reproducir("idle_esqueleto")
		if _cooldown <= 0.0:
			objetivo.take_damage(damage)
			_cooldown = attack_cooldown
		return

	
	var direction: Vector3 = target_position - global_position
	var distance: float = direction.length()
	direction.y = 0.0

	if distance <= stopping_distance:
		velocity = Vector3.ZERO
		move_and_slide()
		_reproducir("idle_esqueleto")
		return

	look_at(global_position + direction, Vector3.UP)
	velocity = direction.normalized() * move_speed
	move_and_slide()
	_reproducir("caminar-esqueleto")



func _defensor_en_rango() -> Node3D:
	var mejor: Node3D = null
	var mejor_dx := attack_range
	for d in get_tree().get_nodes_in_group("defensores"):
		var defensor := d as Node3D
		if defensor == null:
			continue
		if abs(defensor.global_position.z - global_position.z) > 0.6:
			continue
		var dx := global_position.x - defensor.global_position.x
		if dx >= -0.3 and dx <= mejor_dx:
			mejor = defensor
			mejor_dx = dx
	return mejor


func _reproducir(nombre: String) -> void:
	if anim and anim.current_animation != nombre:
		anim.play(nombre)


func take_damage(amount: float) -> void:
	if _muerto:
		return
	current_health -= amount
	if current_health <= 0.0:
		die()


func die() -> void:
	_muerto = true
	ResourceManager.add("sangre", sangre_al_morir)
	died.emit()
	queue_free()
