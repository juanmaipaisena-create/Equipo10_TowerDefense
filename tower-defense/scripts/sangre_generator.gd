extends Node
signal sangre_generada(cantidad: int)

@export var resource_id: String = "subditos"
@export var intervalo: float = 5.0
@export var cantidad_por_tick: int = 1
@export var iniciar_automaticamente: bool = true

var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = intervalo
	_timer.one_shot = false
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)
	if iniciar_automaticamente:
		_timer.start()


func _on_timeout() -> void:
	ResourceManager.add(resource_id, cantidad_por_tick)
	sangre_generada.emit(cantidad_por_tick)


#Segundos que faltan para la próxima moneda (sirve para una barra o cuenta regresiva en el HUD).
func tiempo_restante() -> float:
	return _timer.time_left


#Pausar/reanudar la generación (ejemplo, al abrir un menú de pausa).
func pausar() -> void:
	_timer.paused = true


func reanudar() -> void:
	_timer.paused = false
