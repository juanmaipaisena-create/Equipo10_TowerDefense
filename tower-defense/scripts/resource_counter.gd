extends Label
@export var resource_id: String = "sangre"
@export var prefix: String = "Sangre: "

var _flash_tween: Tween


func _ready() -> void:
	ResourceManager.resource_changed.connect(_on_resource_changed)
	ResourceManager.spend_failed.connect(_on_spend_failed)
	_refresh(ResourceManager.get_amount(resource_id))


func _on_resource_changed(id: String, new_amount: int) -> void:
	if id == resource_id:
		_refresh(new_amount)


func _refresh(amount: int) -> void:
	text = "%s%d" % [prefix, amount]


#respuestq visual cuando no alcanza el recurso: el texto parpadea en rojo.
func _on_spend_failed(id: String, _required: int, _current: int) -> void:
	if id != resource_id:
		return
	if _flash_tween:
		_flash_tween.kill()
	modulate = Color.RED
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.4)
