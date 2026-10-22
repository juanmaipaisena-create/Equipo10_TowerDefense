
extends Node3D

@export var wave_sizes: Array[int] = [5, 8, 12]
@export var spawn_interval: float = 1.5
@export var time_between_waves: float = 4.0
@onready var board: Board = $Board
@onready var hud: CanvasLayer = $HUD

var wave_active: bool = false
var enemies_to_spawn: int = 0
var spawn_timer: float = 0.0
var intermission_timer: float = 0.0
var paused: bool = false

func _ready() -> void:
	GameManager.reset_game()
	hud.set("main_node", self)
	start_wave(0)

func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused:
		return
	if not wave_active:
		if intermission_timer > 0.0:
			intermission_timer -= delta
			if intermission_timer <= 0.0:
				start_wave(GameManager.current_wave)
		return
	if enemies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			var enemy: Enemy = board.spawn_zombie()
			if enemy == null:
				GameManager.status_changed.emit(
                    "Error al generar un enemigo"
				)
				return
			enemies_to_spawn -= 1
			spawn_timer = spawn_interval
	if (
		enemies_to_spawn == 0
		and get_tree().get_nodes_in_group("zombies").is_empty()
	):
		wave_active = false
		if GameManager.current_wave >= wave_sizes.size():
			GameManager.finish_game(true)
			return
		intermission_timer = time_between_waves
		GameManager.status_changed.emit("Oleada completada")

func start_wave(index: int) -> void:
	if GameManager.game_over:
		return
	if index >= wave_sizes.size():
		GameManager.finish_game(true)
		return
	GameManager.set_wave(index + 1)
	enemies_to_spawn = wave_sizes[index]
	spawn_timer = 0.5
	wave_active = true
	intermission_timer = 0.0
	GameManager.status_changed.emit(
		"Oleada %d: ¡defiende la base!" % (index + 1)
	)

func toggle_pause() -> void:
	GameManager.toggle_pause()

func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
