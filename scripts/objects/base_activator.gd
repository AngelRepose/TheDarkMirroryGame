extends Node2D
## Базовый класс для объектов, которые можно активировать (рычаги, плиты, кнопки)
class_name BaseActivator

## Вызывается при активации
signal activated(activator: BaseActivator)

## Вызывается при деактивации
signal deactivated(activator: BaseActivator)

## Активен ли объект
@export var is_active: bool = false: set = set_active

## Уникальный идентификатор активатора для системы последовательностей
@export var trigger_id: String = ""

## Нужно ли визуальное обновление при смене состояния
@export var update_visuals_on_change: bool = true

func _ready() -> void:
	pass

func set_active(value: bool) -> void:
	if is_active == value:
		return
	is_active = value
	
	if update_visuals_on_change:
		_update_visuals()
	
	if is_active:
		activated.emit(self)
	else:
		deactivated.emit(self)

func activate() -> void:
	set_active(true)

func deactivate() -> void:
	set_active(false)

func toggle() -> void:
	set_active(not is_active)

func _update_visuals() -> void:
	pass
