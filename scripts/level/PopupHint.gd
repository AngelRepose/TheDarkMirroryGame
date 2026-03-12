extends Area2D
## Компонент всплывающей подсказки с анимацией
class_name PopupHint

## Вызывается когда игрок входит в зону
signal player_entered

## Вызывается когда игрок выходит из зоны
signal player_exited
@export var uid: StringName
## Контейнер подсказки
@export var hint: Control

## Настройки текста
@export var label_settings: LabelSettings

## Текст подсказки
@export_multiline var exp_text: String = ""

## Смещение подсказки относительно позиции
@export var hint_offset: Vector2 = Vector2(0, -40)

## Длительность появления
@export var show_duration: float = 0.25

## Длительность скрытия
@export var hide_duration: float = 0.15

## Тип анимации появления
@export_enum("scale", "slide_up", "fade") var animation_type: String = "scale"

## Показывать ли только в определённом измерении
@export var dimension_specific: bool = false

## Измерение для показа
@export var show_in_dimension: BaseLevel.Dimension = BaseLevel.Dimension.DIM1

## Метка текста
@onready var _label: Label = $Hint/Label as Label

## Текст подсказки
var text: String = ""

## Игрок в зоне
var player_in_zone: bool = false

## Текущий твин
var tween: Tween

## Ссылка на уровень
var _level: BaseLevel

func set_text(hint_text: String) -> void:
	text = hint_text
	if _label:
		_label.text = text
		if label_settings:
			_label.label_settings = label_settings

func _ready() -> void:
	if exp_text:
		text = exp_text
	set_text(text)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Начальное состояние
	if hint:
		hint.hide()
		hint.modulate.a = 0
		hint.scale = Vector2.ZERO
		hint.position = hint_offset

	_level = _find_level()

func _process(_delta: float) -> void:
	if dimension_specific and _level:
		var should_show: bool = _level.current_dimension == show_in_dimension
		if hint and hint.visible != should_show and player_in_zone:
			if should_show:
				_animate_show()
			else:
				_animate_hide()

func _on_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("Player"):
		player_in_zone = true
		_animate_show()
		player_entered.emit()

func _on_body_exited(body: Node2D) -> void:
	if body is Player or body.is_in_group("Player"):
		player_in_zone = false
		_animate_hide()
		player_exited.emit()

func _animate_show() -> void:
	if not hint:
		return
	
	if dimension_specific and _level:
		if _level.current_dimension != show_in_dimension:
			return
	
	if tween: 
		tween.kill()
	
	tween = create_tween()
	hint.show()
	
	match animation_type:
		"scale":
			tween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(hint, "modulate:a", 1.0, show_duration)
			tween.tween_property(hint, "scale", Vector2.ONE, show_duration)
		"slide_up":
			var target_pos := hint_offset
			hint.position = hint_offset + Vector2(0, 20)
			tween.set_parallel().set_ease(Tween.EASE_OUT)
			tween.tween_property(hint, "modulate:a", 1.0, show_duration)
			tween.tween_property(hint, "position", target_pos, show_duration)
		"fade":
			tween.tween_property(hint, "modulate:a", 1.0, show_duration)

func _animate_hide() -> void:
	if not hint:
		return
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel().set_ease(Tween.EASE_IN)
	tween.tween_property(hint, "modulate:a", 0.0, hide_duration)
	tween.tween_property(hint, "scale", Vector2.ZERO, hide_duration)
	
	await tween.finished
	hint.hide()

func _find_level() -> BaseLevel:
	var node := get_parent()
	while node:
		if node is BaseLevel:
			return node
		node = node.get_parent()
	return null
