extends Button

@onready var escala_original: Vector2 = scale

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_mouse_entered() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(escala_original.x * 1.15, escala_original.y * 0.85), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var tween_back = create_tween()
	tween_back.tween_property(self, "scale", escala_original, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(0.12)

func _on_mouse_exited() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", escala_original, 0.2)

func _on_button_down() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(escala_original.x * 0.85, escala_original.y * 1.15), 0.1)

func _on_button_up() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(escala_original.x * 1.1, escala_original.y * 0.9), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", escala_original, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
