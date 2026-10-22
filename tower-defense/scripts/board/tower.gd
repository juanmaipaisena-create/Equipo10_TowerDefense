class_name Tower
extends Node3D

@export var max_health: float = 100.0
@export var damage: float = 10.0
@export var attack_range: float = 5.0
@export var attack_cooldown: float = 1.0

@export var kill_reward: int = 10

var current_health: float = 100.0
var _cooldown: float = 0.0
var _muerta: bool = false


func _ready() -> void:
	add_to_group("defensores")
	current_health = max_health
	_cooldown = 0.0


func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused or _muerta:
		return

	_cooldown -= delta

	if _cooldown > 0.0:
		return

	var target := _find_enemy()

	if target == null:
		return

	target.take_damage(damage)
	_cooldown = attack_cooldown


func _find_enemy() -> Enemy:
	var best_target: Enemy = null
	var best_distance: float = attack_range

	for node in get_tree().get_nodes_in_group("zombies"):
		var enemy := node as Enemy

		if enemy == null or enemy.is_dead():
			continue

		var distance := global_position.distance_to(enemy.global_position)

		# Solo atacamos enemigos aproximadamente a la misma altura.
		if abs(enemy.global_position.y - global_position.y) > 2.0:
			continue

		if distance <= best_distance:
			best_distance = distance
			best_target = enemy

	return best_target


func take_damage(amount: float) -> void:
	if _muerta:
		return

	current_health -= amount

	if current_health <= 0.0:
		die()


func die() -> void:
	if _muerta:
		return

	_muerta = true
	queue_free()
