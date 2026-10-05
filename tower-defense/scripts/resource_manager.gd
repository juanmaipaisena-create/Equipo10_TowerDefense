extends Node
signal resource_changed(resource_id: String, new_amount: int)

signal spend_failed(resource_id: String, required: int, current: int)

#Agregá o cambiá los que necesite el juego.
var _resources: Dictionary = {
	"sangre": 0,
	"subditos": 0,
}


func _ready() -> void:
	#Emite el valor inicial para que los contadores arranquen con el número correcto.
	for id in _resources:
		resource_changed.emit(id, _resources[id])


#Devuelve la cantidad actual de un recurso (0 si no existe).
func get_amount(resource_id: String) -> int:
	return _resources.get(resource_id, 0)


#alcanza para pagar este costo?
func can_afford(resource_id: String, cost: int) -> bool:
	return get_amount(resource_id) >= cost


#Suma recursos, ignora cantidades negativas o cero.
func add(resource_id: String, amount: int) -> void:
	if amount <= 0:
		return
	_set_amount(resource_id, get_amount(resource_id) + amount)


#borrarecursos, devuelve true si pudo pagar, false si no alcanzaba.
func spend(resource_id: String, cost: int) -> bool:
	if cost <= 0:
		return true
	var current := get_amount(resource_id)
	if current < cost:
		spend_failed.emit(resource_id, cost, current)
		return false
	_set_amount(resource_id, current - cost)
	return true


## Descuenta varios recursos a la vez, todo o nada.
## costs = {"sangre": 1, "subditos": 2}. Si falta alguno, no descuenta ninguno y devuelve false.
func spend_many(costs: Dictionary) -> bool:
	for id in costs:
		if get_amount(id) < costs[id]:
			spend_failed.emit(id, costs[id], get_amount(id))
			return false
	for id in costs:
		_set_amount(id, get_amount(id) - costs[id])
	return true


func _set_amount(resource_id: String, value: int) -> void:
	_resources[resource_id] = maxi(value, 0)  # validación: nunca menor a 0
	resource_changed.emit(resource_id, _resources[resource_id])
