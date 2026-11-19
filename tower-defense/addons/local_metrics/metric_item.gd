@tool
class_name MetricItem
extends Resource

enum DataType {
	INT,
	FLOAT,
	STRING,
	BOOL,
	VECTOR2,
	VECTOR3,
	ARRAY,
}

@export var name: String = "Metric visual name"
@export var metric_id: String = "ID"

@export var data_type: DataType = DataType.INT:
	set(new_type):
		if data_type != new_type:
			data_type = new_type
			_reset_value_to_default()
			notify_property_list_changed()

var value: Variant = 0

func _init() -> void:
	# _init se ejecuta al crear el recurso
	_reset_value_to_default()

func _reset_value_to_default() -> void:
	match data_type:
		DataType.INT: value = 0
		DataType.FLOAT: value = 0.0
		DataType.STRING: value = ""
		DataType.BOOL: value = false
		DataType.VECTOR2: value = Vector2.ZERO
		DataType.VECTOR3: value = Vector3.ZERO
		DataType.ARRAY: value = []


# =====================================================================
# Propiedades dinámicas en el Inspector (requiere @tool)
# =====================================================================

func _get_property_list() -> Array:
	var properties = []
	var type_hint = TYPE_INT
	
	match data_type:
		DataType.INT: type_hint = TYPE_INT
		DataType.FLOAT: type_hint = TYPE_FLOAT
		DataType.STRING: type_hint = TYPE_STRING
		DataType.BOOL: type_hint = TYPE_BOOL
		DataType.VECTOR2: type_hint = TYPE_VECTOR2
		DataType.VECTOR3: type_hint = TYPE_VECTOR3
		DataType.ARRAY: type_hint = TYPE_ARRAY

	properties.append({
		"name": &"value",
		"type": type_hint,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""
	})
	
	return properties

func _get(property: StringName):
	if property == &"value":
		return value
	return null

func _set(property: StringName, val: Variant) -> bool:
	if property == &"value":
		value = val
		return true
	return false
