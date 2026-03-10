extends Node2D
## Базовый класс для объектов, которые реагируют на активацию
class_name ActivatableObject

## Список идентификаторов активаторов, на которые реагирует этот объект
@export var activator_ids: Array[String] = []

## Задержка перед срабатыванием (в секундах)
@export var activation_delay: float = 0.0

## Нужно ли активировать только один раз
@export var one_shot: bool = false

## Активирован ли объект
var is_activated: bool = false

## Была ли уже активация (для one_shot)
var _has_been_activated: bool = false

func _ready() -> void:
	_connect_to_activators()

func _connect_to_activators() -> void:
	var parent := get_parent()
	if not parent:
		return
	
	for child in parent.get_children():
		if child is BaseActivator:
			var activator: BaseActivator = child
			if activator_ids.is_empty() or activator.trigger_id in activator_ids:
				activator.activated.connect(_on_activator_activated.bind(activator))
				activator.deactivated.connect(_on_activator_deactivated.bind(activator))

func _on_activator_activated(activator: BaseActivator) -> void:
	if one_shot and _has_been_activated:
		return
	
	if activation_delay > 0.0:
		await get_tree().create_timer(activation_delay).timeout
	
	_activate(activator)
	is_activated = true
	_has_been_activated = true

func _on_activator_deactivated(activator: BaseActivator) -> void:
	if one_shot:
		return
	
	_deactivate(activator)
	is_activated = false

func _activate(_activator: BaseActivator) -> void:
	pass

func _deactivate(_activator: BaseActivator) -> void:
	pass
