extends CanvasLayer

var main_node: Node3D
var gm: Node = null

@onready var money_label: Label = $Panel/VBox/MoneyLabel      
@onready var blood_label: Label = $Panel/VBox/BloodLabel    
@onready var wave_label: Label = $Panel/VBox/WaveLabel
@onready var status_label: Label = $Panel/VBox/StatusLabel

@onready var build_button: Button = $Panel/VBox/BuildButton
@onready var pause_button: Button = $Panel/VBox/PauseButton
@onready var restart_button: Button = $Panel/VBox/RestartButton

var _flash_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	gm = get_node_or_null("/root/GameManager")

	
	ResourceManager.resource_changed.connect(_on_resource_changed)
	ResourceManager.spend_failed.connect(_on_spend_failed)
	_on_resource_changed("sangre", ResourceManager.get_amount("sangre"))

	pause_button.pressed.connect(_on_pause_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	build_button.pressed.connect(_on_build_pressed)

	
	var hay_gm := gm != null
	blood_label.visible = hay_gm
	wave_label.visible = hay_gm
	status_label.visible = hay_gm
	build_button.visible = hay_gm

	if hay_gm:
		build_button.text = "Construcción: ACTIVADA"
		gm.blood_changed.connect(_on_base_changed)
		gm.wave_changed.connect(_on_wave_changed)
		gm.status_changed.connect(_on_status_changed)
		gm.game_finished.connect(_on_game_finished)
		_on_base_changed(gm.base_health)
		_on_wave_changed(gm.current_wave)



func _on_resource_changed(id: String, new_amount: int) -> void:
	if id == "sangre":
		money_label.text = "Sangre: %d" % new_amount


func _on_spend_failed(id: String, _required: int, _current: int) -> void:
	if id != "sangre":
		return
	if _flash_tween:
		_flash_tween.kill()
	money_label.modulate = Color.RED
	_flash_tween = create_tween()
	_flash_tween.tween_property(money_label, "modulate", Color.WHITE, 0.4)

func _on_build_pressed() -> void:
	if gm == null or gm.game_over:
		return
	gm.build_mode = not gm.build_mode
	if gm.build_mode:
		build_button.text = "Construcción: ACTIVADA"
		gm.status_changed.emit("Selecciona una celda libre")
	else:
		build_button.text = "Construcción: DESACTIVADA"
		gm.status_changed.emit("Construcción desactivada")


func _on_pause_pressed() -> void:
	var pausado: bool
	if gm != null:
		gm.toggle_pause()
		pausado = gm.paused
	else:
		get_tree().paused = not get_tree().paused
		pausado = get_tree().paused
	pause_button.text = "Continuar" if pausado else "Pausar"


func _on_restart_pressed() -> void:
	ResourceManager.reiniciar()
	if main_node != null and is_instance_valid(main_node):
		main_node.call("restart_game")
	else:
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_base_changed(amount: int) -> void:
	blood_label.text = "Base: %d" % amount


func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Oleada: %d / 3" % wave


func _on_status_changed(message: String) -> void:
	status_label.text = message


func _on_game_finished(won: bool) -> void:
	build_button.disabled = true
	pause_button.disabled = true
	status_label.text = "¡VICTORIA BIEN AHI!" if won else "¡DERROTA MAL AHI!"
