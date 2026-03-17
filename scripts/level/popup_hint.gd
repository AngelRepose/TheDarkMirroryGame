extends Area2D

## Компонент всплывающей подсказки с анимацией.
## Показывает текст при входе игрока в зону.

class_name PopupHint

## Вызывается когда игрок входит в зону
signal player_entered

## Вызывается когда игрок выходит из зоны
signal player_exited

## Префикс для логирования
var LOG_PREFIX: StringName = &"[PopupHint] "

## Уникальный идентификатор
@export var uid: StringName = &""

## Контейнер подсказки
@export var hint: Control = null

## Настройки текста
@export var label_settings: LabelSettings = null

## Текст подсказки
@export_multiline var exp_text: String = ""

## Смещение подсказки относительно позиции
@export var hint_offset: Vector2 = Vector2(0, -40)

## Длительность появления в секундах
@export var show_duration: float = 0.25

## Длительность скрытия в секундах
@export var hide_duration: float = 0.15

## Тип анимации появления
@export_enum("scale", "slide_up", "fade") var animation_type: String = "scale"

## Показывать ли только в определённом измерении
@export var dimension_specific: bool = false

## Измерение для показа
@export var show_in_dimension: int = 0

## Метка текста
@onready var _label: Label = $Hint/Label as Label

## Текст подсказки
var text: String = ""

## Игрок в зоне
var player_in_zone: bool = false

## Текущий твин
var tween: Tween = null

## Ссылка на уровень
var _level: BaseLevel = null


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
	GameManager.debug(self.LOG_PREFIX+"Подсказка {} загружена\n", 
		[str(uid) if uid else "без uid"]
	)


func _process(_delta: float) -> void:
	if dimension_specific and _level:
		var should_show: bool = _level.current_dimension == show_in_dimension
		if hint and hint.visible != should_show and player_in_zone:
			if should_show:
				_animate_show()
			else:
				_animate_hide()


## Устанавливает текст подсказки.
## [param hint_text] — текст для отображения
func set_text(hint_text: String) -> void:
	text = hint_text
	if _label:
		_label.text = text
		if label_settings:
			_label.label_settings = label_settings
	GameManager.debug(self.LOG_PREFIX+"Подсказке {} установлен новый текст: {}\n", 
		[str(uid) if uid else "без uid",
		text]
	)


## Вызывается при входе тела в зону.
## [param body] — вошедший узел
func _on_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("Player"):
		player_in_zone = true
		_animate_show()
		player_entered.emit()


## Вызывается при выходе тела из зоны.
## [param body] — вышедший узел
func _on_body_exited(body: Node2D) -> void:
	if body is Player or body.is_in_group("Player"):
		player_in_zone = false
		_animate_hide()
		player_exited.emit()


## Показывает подсказку с анимацией.
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
	GameManager.debug(self.LOG_PREFIX+"Подсказка {} появилась с анимацией {}\n", 
		[str(uid) if uid else "без uid", animation_type]
	)
	
	match animation_type:
		"scale":
			tween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(hint, "modulate:a", 1.0, show_duration)
			tween.tween_property(hint, "scale", Vector2.ONE, show_duration)
		"slide_up":
			var target_pos: Vector2 = hint_offset
			hint.position = hint_offset + Vector2(0, 20)
			tween.set_parallel().set_ease(Tween.EASE_OUT)
			tween.tween_property(hint, "modulate:a", 1.0, show_duration)
			tween.tween_property(hint, "position", target_pos, show_duration)
		"fade":
			tween.tween_property(hint, "modulate:a", 1.0, show_duration)


## Скрывает подсказку с анимацией.
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


## Находит родительский уровень.
## Возвращает найденный уровень или null.
func _find_level() -> BaseLevel:
	var node: Node = get_parent()
	while node:
		if node is BaseLevel:
			return node
		node = node.get_parent()
	return null
