extends Node

const SAVE_PATH = "user://game_metrics.json"
const CSV_PATH = "user://match_metrics.csv"

var _active_metrics: Dictionary[String, Variant] = {}
var _metric_list: Array[MetricItem] = []
var _current_session: int = 0

var _pending_sessions: Array[Dictionary] = []
var _has_active_session: bool = false


## Este método debe ser llamado por única vez al comenzar el juego.
## Recibe el recurso MetricsResource y lo almacena en el script para utilizar los metric_id y los tipos de datos esperados.
## El llamado a este método resetea la variable interna active_metrics, dejando inicializada cada métrica en su valor por defecto.
## E inicia una nueva sesión
func register_metrics(metrics_definition: MetricsResource) -> void:
	_metric_list = metrics_definition.metrics
	_load_persistent_data()

	var last_csv_session := _get_last_session_from_csv()
	if last_csv_session >= 0:
		_current_session = last_csv_session

	_reset_active_metrics()
	print("Metrics Registered: ", ",".join(_metric_list.map(func (m): return m.metric_id)))
	start_new_session()
	

## Este método permite  resetear la variable interna de métricas y aumenta el contador de sesión en 1.
## Ejemplo de uso:
## register_metrics(resource)
## record_set("salto")
## record_set("otra_metrica")
## record_add("salto")
## ..
## ..
## Vamos a comenzar una nueva sesión entonces
## start_new_session()
func start_new_session():
	if _has_active_session:
		_save_current_session()
	_current_session += 1
	_reset_active_metrics()
	_has_active_session = true
	_save_persistent_data()
	print("New session started: ", _current_session)

## Escribe el valor recibido en el metric_id
## Ejemplo:
## record_set("checkpoint_alcanzado", "zona C")  ->  checkpoint_alcanzado = "zona C"
## record_set("checkpoint_alcanzado", "zona Z")  ->  checkpoint_alcanzado = "zona Z"
func record_set(metric_id: String, value: Variant) -> void:
	if _metric_list.size() == 0 or !_active_metrics.has(metric_id):
		print("Error setting metric: ", metric_id, "metric not initialized")
		return
	_active_metrics[metric_id]["value"] = value
	print("Metric Set: ", metric_id, _active_metrics[metric_id]["value"])

## Suma el valor recibido al valor ya escrito en el metric_id. Si no existe previamente, funciona como el set.
## Ejemplo:
## record_add("contador_salto", 1)  ->  contador_salto = 1
## record_add("contador_salto", 1)  ->  contador_salto = 2
## record_add("contador_salto", 5)  ->  contador_salto = 7
func record_add(metric_id: String, value: Variant) -> void:
	if _metric_list.size() == 0 or !_active_metrics.has(metric_id):
		print("Error adding metric: ", metric_id, "metric not initialized")
		return
	var data_type = _active_metrics[metric_id]["type"]
	if data_type == MetricItem.DataType.INT or data_type == MetricItem.DataType.FLOAT or data_type == MetricItem.DataType.VECTOR2 or data_type == MetricItem.DataType.VECTOR3:
		_active_metrics[metric_id]["value"] += value
	elif data_type == MetricItem.DataType.ARRAY:
		(_active_metrics[metric_id]["value"] as Array).append(value)
	else:
		record_set(metric_id, value)
	print("Metric Added: ", metric_id, _active_metrics[metric_id]["value"])
	

## Método para resetear un valor específico de métrica a su valor por defecto.
## Útil en el caso de necesitar reiniciar un valor concreto o un contador, por ejemplo
func record_reset(metric_id: String) -> void:
	if _metric_list.size() == 0 or !_active_metrics.has(metric_id):
		print("Error resetting metrics: ", "metric not initialized")
		return
	var metric_item_index = _metric_list.find_custom(func (m: MetricItem): m.metric_id == metric_id)
	if metric_item_index != -1:
		_active_metrics[metric_id]["value"] = _metric_list[metric_item_index].value
	print("Metrics Reseted")

func export_to_csv(file_path: String = CSV_PATH) -> Error:
	# Agregamos la sesión actual a las pendientes antes de exportar.
	if _has_active_session:
		_save_current_session()
		_has_active_session = false

	if _pending_sessions.is_empty():
		print("No hay sesiones pendientes de exportar.")
		return OK

	var file_exists := FileAccess.file_exists(file_path)
	var is_empty := true

	if file_exists:
		var temp_file := FileAccess.open(file_path, FileAccess.READ)

		if temp_file == null:
			return FileAccess.get_open_error()

		is_empty = temp_file.get_length() == 0
		temp_file.close()

	var file: FileAccess

	if file_exists and not is_empty:
		file = FileAccess.open(file_path, FileAccess.READ_WRITE)

		if file == null:
			return FileAccess.get_open_error()

		file.seek_end()
	else:
		file = FileAccess.open(file_path, FileAccess.WRITE)

		if file == null:
			return FileAccess.get_open_error()

		var header: Array[String] = ["session"]
		header.append_array(
			_metric_list.map(func(m): return m.metric_id)
		)
		file.store_line(";".join(header))

	for session_data in _pending_sessions:
		var metrics: Dictionary = session_data.get("metrics", {})
		var values: Array[String] = [
			str(session_data.get("session", ""))
		]

		for metric in _metric_list:
			var metric_id: String = metric.metric_id

			if metrics.has(metric_id):
				values.append(str(metrics[metric_id]))
			else:
				values.append("-")

		file.store_line(";".join(values))

	file.flush()

	var write_error: Error = file.get_error()
	file.close()

	if write_error != OK:
		push_error("Error al escribir el CSV: " + str(write_error))
		return write_error

	# Solo se vacía la cola después de escribir todas las filas.
	var previous_pending := _pending_sessions.duplicate(true)
	_pending_sessions.clear()

	var save_error := _save_persistent_data()

	if save_error != OK:
		_pending_sessions = previous_pending
		return save_error

	print("Metrics exported: ", ProjectSettings.globalize_path(file_path))
	return OK


# ---

func _get_last_session_from_csv(file_path: String = CSV_PATH) -> int:
	if not FileAccess.file_exists(file_path):
		return -1

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return -1

	var lines := file.get_as_text().split("\n")
	file.close()

	if lines.is_empty():
		return -1

	# Validamos que el header corresponda con las métricas actuales.
	var expected_header: Array[String] = ["session"]
	expected_header.append_array(
		_metric_list.map(func(m): return m.metric_id)
	)

	if lines[0].strip_edges() != ";".join(expected_header):
		return -1

	# Buscamos la última fila registrada, ignorando líneas vacías.
	for i in range(lines.size() - 1, 0, -1):
		var line: String = lines[i].strip_edges()

		if line.is_empty():
			continue

		var values := line.split(";")

		if values.size() > 0 and values[0].is_valid_int():
			return int(values[0])

	# El header es válido, pero todavía no hay sesiones registradas.
	return 0
	
func _reset_active_metrics():
	_active_metrics.clear()
	for metric in _metric_list:
		_active_metrics[metric.metric_id] = { "value": metric.value, "type": metric.data_type }
		
func _save_current_session() -> void:
	var metrics_snapshot: Dictionary = {}

	for metric in _metric_list:
		var metric_id: String = metric.metric_id

		if _active_metrics.has(metric_id):
			metrics_snapshot[metric_id] = \
				_active_metrics[metric_id]["value"]

	_pending_sessions.append({
		"session": _current_session,
		"metrics": metrics_snapshot
	})

	_save_persistent_data()
	
func _save_persistent_data() -> Error:
	var data: Dictionary = {
		"current_session": _current_session,
		"pending_sessions": _pending_sessions
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("No se pudo guardar el JSON: " + SAVE_PATH)
		return FileAccess.get_open_error()

	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	return OK

func _load_persistent_data() -> void:
	_pending_sessions.clear()
	_current_session = 0

	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		push_error("No se pudo leer el JSON: " + SAVE_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if not parsed is Dictionary:
		push_error("El archivo de métricas no contiene un objeto JSON válido.")
		return

	_current_session = int(parsed.get("current_session", 0))

	var pending = parsed.get("pending_sessions", [])

	if pending is Array:
		for session in pending:
			if session is Dictionary:
				_pending_sessions.append(session)
