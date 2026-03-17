extends StaticBody2D

## Базовый класс для объектов, которые можно активировать (рычаги, плиты, кнопки).
## Предоставляет сигналы активации и методы управления состоянием.

class_name BaseActivator

## Префикс для логирования
var LOG_PREFIX: StringName = &"[BaseActivator] "

## Вызывается при активации
signal activated(activator: BaseActivator)

## Вызывается при деактивации
signal deactivated(activator: BaseActivator)

## Активен ли объект
@export var is_active: bool = false: set = set_active

## Уникальный идентификатор для системы последовательностей
@export var trigger_id: String = ""

## Нужно ли визуальное обновление при смене состояния
@export var update_visuals_on_change: bool = true

@onready var _orig_collision_layer: int = self.collision_layer
@onready var _orig_collision_mask: int = self.collision_mask

func _ready() -> void:
	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен, trigger_id: {}\n", 
	[str(trigger_id) if trigger_id else "без id"]
	)


## Устанавливает состояние активности.
## [param value] — новое состояние
func set_active(value: bool) -> void:
	if is_active == value:
		return
	is_active = value
	
	if update_visuals_on_change:
		_update_visuals()
	
	if is_active:
		activated.emit(self)
		GameManager.debug(LOG_PREFIX+"Активирован. Trigger id: {}", [trigger_id])
	else:
		deactivated.emit(self)
		GameManager.debug(LOG_PREFIX+"Деактивирован. Trigger id: {}", [trigger_id])


func disable_collisions() -> void:
	self.collision_layer = 0
	self.collision_mask = 0
	
func enable_collisions() -> void:
	self.collision_layer = _orig_collision_layer
	self.collision_mask = _orig_collision_mask
	
func toggle_collisions() -> void:
	if self.collision_layer == 0 and self.collision_mask == 0:
		enable_collisions()
	else:
		disable_collisions()
		

## Активирует объект.
func activate(_j: Variant = null) -> void:
	set_active(true)


## Деактивирует объект.
func deactivate(_j: Variant = null) -> void:
	set_active(false)


## Переключает состояние.
func toggle() -> void:
	set_active(not is_active)


## Обновляет визуальное состояние. Переопределяется в наследниках.
func _update_visuals() -> void:
	pass
