extends Node2D
class_name PopupHint
signal player_entered
signal player_exited

@export var hint: Control
@export var area: Area2D
@export var label_settings: LabelSettings
@onready var _label: Label = $Hint/Label as Label
@export_multiline  var exp_text: String 
var text: String = ""

var player_in_zone: bool = false
var tween: Tween

func set_text(hint_text: String) -> void:
	text = hint_text
	_label.text = text
	_label.label_settings = label_settings

func _ready() -> void:
	text = exp_text if exp_text else text
	set_text(text)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	# Начальное состояние
	if hint:
		hint.hide()
		hint.modulate.a = 0
		hint.scale = Vector2.ZERO

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body is Player: # Убедись, что у игрока есть группа или имя
		player_in_zone = true
		_toggle_hint(true)
		player_entered.emit()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body is Player:
		player_in_zone = false
		_toggle_hint(false)
		player_exited.emit()

func _toggle_hint(show: bool) -> void:
	if not hint: return
	
	if tween: 
		tween.kill()
		tween = null
	
	tween = create_tween()
	
	if show:
		tween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		hint.show()
		tween.tween_property(hint, "modulate:a", 1.0, 0.2)
		tween.tween_property(hint, "scale", Vector2.ONE, 0.2)
	else:
		tween.set_parallel()
		tween.tween_property(hint, "modulate:a", 0.0, 0.1)
		tween.tween_property(hint, "scale", Vector2.ZERO, 0.1)
		await tween.finished
		hint.hide()
