class_name Derrota
extends Control

static var escena_anterior: String = ""

@export_file("*.tscn") var escena_menu: String = ""


func _ready() -> void:
	get_tree().paused = false


func _reiniciar_estado() -> void:
	ResourceManager.reiniciar()
	for nombre in ["reset_game", "reset", "restart_game", "reiniciar"]:
		if GameManager.has_method(nombre):
			GameManager.call(nombre)
			break


func _on_reiniciar_button_pressed() -> void:
	_reiniciar_estado()
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _on_volver_button_pressed() -> void:
	get_tree().quit()
