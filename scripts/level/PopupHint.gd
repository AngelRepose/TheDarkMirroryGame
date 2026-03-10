extends Node2D
## Компонент всплывающей подсказки с анимацией
class_name PopupHint

## Вызывается при входе игрока в зону
signal player_entered

## Вызывается при выходе игрока из зоны
signal player_exited

## Контейнер подсказки
@export var hint: Control

## Зона обнаружения игрока
@export var area: Area2D

## Настройки текста
@export var label_settings: LabelSettings

## Текст подсказки
@export_multiline var exp_text: String = ""

## Иконка для подсказки (опционально)
@export var hint_icon: Texture2D

## Смещение подсказки относительно позиции
@export var hint_offset: Vector2 = Vector2(0, -40)

## Длительность появления
@export var show_duration: float = 0.25

## Длительность скрытия
@export var hide_duration: float = 0.15

## Использоватьbounce эффект
@export var bounce_effect: bool = true

## Метка текста
@onready var _label: Label = $Hint/Label as Label

## Иконка в подсказке
@onready var _icon: TextureRect = $Hint/Icon as TextureRect

## Текст подсказки
var text: String = ""

## Находится ли игрок в зоне
var player_in_zone: bool = false

## Твин анимации
var tween: Tween

func set_text(hint_text: String) -> void:
	text = hint_text
	if _label:
		_label.text = text
		if label_settings:
			_label.label_settings = label_settings

func _ready() -> void:
	text = exp_text if exp_text 
