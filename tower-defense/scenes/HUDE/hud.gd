
extends CanvasLayer

var main_node: Node3D

@onready var money_label: Label = $Panel/VBox/MoneyLabel
@onready var blood_label: Label = $Panel/VBox/BloodLabel
@onready var wave_label: Label = $Panel/VBox/WaveLabel
@onready var status_label: Label = $Panel/VBox/StatusLabel

@onready var build_button: Button = $Panel/VBox/BuildButton
@onready var pause_button: Button = $Panel/VBox/PauseButton
@onready var restart_button: Button = $Panel/VBox/RestartButton


func _ready() -> void:
	build_button.text = "Construcción: ACTIVADA"
	process_mode = Node.PROCESS_MODE_ALWAYS

	build_button.pressed.connect(_on_build_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

	GameManager.money_changed.connect(_on_money_changed)
	GameManager.blood_changed.connect(_on_blood_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.status_changed.connect(_on_status_changed)
	GameManager.game_finished.connect(_on_game_finished)

	_on_money_changed(GameManager.money)
	_on_blood_changed(GameManager.base_health)
	_on_wave_changed(GameManager.current_wave)


func _on_build_pressed() -> void:
	if GameManager.game_over:
		return
	GameManager.build_mode = not GameManager.build_mode
	if GameManager.build_mode:
		build_button.text = "Construcción: ACTIVADA"
		GameManager.status_changed.emit(
			"Selecciona una celda libre"
		)
	else:
		build_button.text = "Construcción: DESACTIVADA"
		GameManager.status_changed.emit(
			"Construcción desactivada"
		)

func _on_pause_pressed() -> void:
	GameManager.toggle_pause()

	if GameManager.paused:
		pause_button.text = "Continuar"
	else:
		pause_button.text = "Pausar"


func _on_restart_pressed() -> void:
	if main_node != null and is_instance_valid(main_node):
		main_node.call("restart_game")


func _on_money_changed(amount: int) -> void:
	money_label.text = "Monedas: %d" % amount


func _on_blood_changed(amount: int) -> void:
	blood_label.text = "Base: %d" % amount


func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Oleada: %d / 3" % wave


func _on_status_changed(message: String) -> void:
	status_label.text = message


func _on_game_finished(won: bool) -> void:
	build_button.disabled = true
	pause_button.disabled = true

	if won:
		status_label.text = "¡VICTORIA BIEN AHI!"
	else:
		status_label.text = "¡DERROTA MAL AHI!"
