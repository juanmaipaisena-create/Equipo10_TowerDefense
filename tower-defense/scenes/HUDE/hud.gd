extends CanvasLayer

var main_node: Node3D

@onready var money_label: Label = $Panel/VBox/MoneyLabel
@onready var blood_label: Label = $Panel/VBox/BloodLabel
@onready var wave_label: Label = $Panel/VBox/WaveLabel
@onready var status_label: Label = $Panel/VBox/StatusLabel

@onready var pause_button: Button = $Panel/VBox/PauseButton
@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var guide_button: Button = $Panel/VBox/GuideButton

@onready var guide_panel: PanelContainer = $GuidePanel
@onready var guide_text: Label = $GuidePanel/VBox/GuideText
@onready var close_button: Button = $GuidePanel/VBox/CloseButton

func _ready() -> void:
	#build_button.text = "Construcción: ACTIVADA"
	process_mode = Node.PROCESS_MODE_ALWAYS
	# La construcción queda siempre habilitada.
	GameManager.build_mode = true
	# Ocultar la guía al iniciar.
	guide_panel.hide()

	#build_button.pressed.connect(_on_build_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	guide_button.pressed.connect(_on_guide_pressed)
	close_button.pressed.connect(_on_close_guide_pressed)

	ResourceManager.resource_changed.connect(_on_resource_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.status_changed.connect(_on_status_changed)
	GameManager.game_finished.connect(_on_game_finished)
	
	# Texto de la guía.
	guide_text.text = """1. TABLERO DE COMBATE
Coloca tus unidades en las celdas libres haciendo clic o arrastrándolas desde la incubadora. Puedes tener un máximo de 6 unidades en el tablero.

2. INCUBADORA
Aquí aparecen nuevos súbditos con el paso del tiempo. Selecciónalos y arrástralos al tablero de combate.

3. SACRIFICIO Y COMBINACIONES
Coloca dos súbditos compatibles en la zona de sacrificio para crear una unidad combinada. Las combinaciones pueden mejorar sus capacidades.

4. RECURSOS
Administra tu sangre para comprar unidades y realizar combinaciones. Elimina zombis para conseguir más recursos.

5. OLEADAS
Defiende tu base de los zombis. Cada oleada será un nuevo desafío.

6. PAUSA Y REINICIO
Puedes pausar la partida o reiniciarla desde los botones del HUD.
¡Buena suerte defendiendo la base!"""

	_on_resource_changed("monedas", ResourceManager.get_amount("monedas"))
	_on_resource_changed("sangre", ResourceManager.get_amount("sangre"))
	_on_wave_changed(GameManager.current_wave)


func _on_build_pressed() -> void:
	if GameManager.game_over:
		return
	GameManager.build_mode = not GameManager.build_mode
	if GameManager.build_mode:
		#build_button.text = "Construcción: ACTIVADA"
		GameManager.status_changed.emit(
			"Selecciona una celda libre"
		)
	else:
		#build_button.text = "Construcción: DESACTIVADA"
		GameManager.status_changed.emit(
			"Construcción desactivada"
		)

func _on_guide_pressed() -> void:
	guide_panel.show()

func _on_close_guide_pressed() -> void:
	guide_panel.hide()
	
func _on_pause_pressed() -> void:
	GameManager.toggle_pause()

	if GameManager.paused:
		pause_button.text = "Continuar"
	else:
		pause_button.text = "Pausar"


func _on_restart_pressed() -> void:
	if main_node != null and is_instance_valid(main_node):
		main_node.call("restart_game")


func _on_resource_changed(id: String, amount: int) -> void:
	match id:

		"sangre":
			blood_label.text = "Sangre: %d" % amount


func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Oleada: %d / 3" % wave


func _on_status_changed(message: String) -> void:
	status_label.text = message


func _on_game_finished(won: bool) -> void:
	#build_button.disabled = true
	pause_button.disabled = true

	if won:
		status_label.text = "¡VICTORIA BIEN AHI!"
	else:
		status_label.text = "¡DERROTA MAL AHI!"
		
		
func _on_money_changed(amount: int) -> void:
	money_label.text = "Sangre: %d" % amount
