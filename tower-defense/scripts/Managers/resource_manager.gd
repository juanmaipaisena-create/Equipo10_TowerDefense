extends Node
signal resource_changed(resource_id: String, new_amount: int)

signal spend_failed(resource_id: String, required: int, current: int)


var _resources: Dictionary = {
	"sangre": 0,
	"subditos": 0,
}


func _ready() -> void:
	
	for id in _resources:
		resource_changed.emit(id, _resources[id])



func get_amount(resource_id: String) -> int:
	return _resources.get(resource_id, 0)



func can_afford(resource_id: String, cost: int) -> bool:
	return get_amount(resource_id) >= cost



func add(resource_id: String, amount: int) -> void:
	if amount <= 0:
		return
	_set_amount(resource_id, get_amount(resource_id) + amount)



func spend(resource_id: String, cost: int) -> bool:
	if cost <= 0:
		return true
	var current := get_amount(resource_id)
	if current < cost:
		spend_failed.emit(resource_id, cost, current)
		return false
	_set_amount(resource_id, current - cost)
	return true



func spend_many(costs: Dictionary) -> bool:
	for id in costs:
		if get_amount(id) < costs[id]:
			spend_failed.emit(id, costs[id], get_amount(id))
			return false
	for id in costs:
		_set_amount(id, get_amount(id) - costs[id])
	return true


func _set_amount(resource_id: String, value: int) -> void:
	_resources[resource_id] = maxi(value, 0) 
	resource_changed.emit(resource_id, _resources[resource_id])
