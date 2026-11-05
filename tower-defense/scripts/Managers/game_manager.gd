extends Node

signal money_changed(amount: int)
signal blood_changed(amount: int)
signal wave_changed(wave: int)
signal status_changed(message: String)
signal game_finished(won: bool)

var starting_money: int = 150
var starting_blood: int = 10
var money: int = 150
var base_health: int = 10
var current_wave: int = 0
var game_over: bool = false
var paused: bool = false
var build_mode: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func reset_game() -> void:
	build_mode = true
	money = starting_money
	base_health = starting_blood
	current_wave = 0
	game_over = false
	paused = false

	get_tree().paused = false

	money_changed.emit(money)
	blood_changed.emit(base_health)
	wave_changed.emit(current_wave)
	status_changed.emit("Prepara tus defensas")


func can_afford(cost: int) -> bool:
	return not game_over and money >= cost


func spend_money(amount: int) -> bool:
	if amount < 0 or not can_afford(amount):
		return false

	money -= amount
	money_changed.emit(money)
	return true


func add_money(amount: int) -> void:
	if game_over or amount <= 0:
		return

	money += amount
	money_changed.emit(money)


func add_blood(amount: int) -> void:
	if game_over or amount <= 0:
		return

	base_health += amount
	blood_changed.emit(base_health)


func damage_base(amount: int) -> void:
	if game_over or amount <= 0:
		return

	base_health = max(0, base_health - amount)
	blood_changed.emit(base_health)

	if base_health <= 0:
		finish_game(false)


func set_wave(wave: int) -> void:
	current_wave = wave
	wave_changed.emit(current_wave)
	status_changed.emit("Oleada %d" % current_wave)


func finish_game(won: bool) -> void:
	if game_over:
		return

	game_over = true
	paused = false
	get_tree().paused = false

	if won:
		status_changed.emit("¡VICTORIA!")
	else:
		status_changed.emit("¡DERROTA!")

	game_finished.emit(won)


func toggle_pause() -> void:
	if game_over:
		return

	paused = not paused
	get_tree().paused = paused

	if paused:
		status_changed.emit("Partida pausada")
	else:
		status_changed.emit("Partida en curso")
