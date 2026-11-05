class_name Tower
extends Node3D


@export var max_health: float = 100.0
@export var damage: float = 10.0
@export var attack_range: float = 5.0
@export var attack_cooldown: float = 1.0


var current_health: float


func _ready() -> void:
	current_health = max_health
	
func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0.0:
		die()

func die() -> void:
	queue_free()
