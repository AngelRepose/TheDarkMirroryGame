extends TileMapLayer

## Базовый класс измерения уровня.
## Управляет видимостью и активностью тайлов и фона.

class_name BaseDimension

## Префикс для логирования
var LOG_PREFIX: StringName = &"[BaseDimension] "

## Уникальный идентификатор измерения
@export var uid: StringName = &""

## Ссылка на фоновый слой
@export var background: TileMapLayer = null

## Включено ли измерение по умолчанию
@export var default_enabled: bool = true


func _ready() -> void:
	self.enabled = default_enabled
	GameManager.debug(LOG_PREFIX+"Измерение {} загружено. Включено: {}\n", 
		[str(uid) if uid else "без uid", self.enabled]
	)
	

## Переключает состояние измерения.
func toggle() -> void:
	if self.enabled:
		disable()
	else:
		enable()



## Отключает измерение.
func disable() -> void:
	self.visible = false
	self.background.visible = false
	self.enabled = false
	self.background.enabled = false
	for child: Node2D in get_children():
		var object: Node2D = child as Node2D
		if object.has_method("disable_collisions"): object.disable_collisions()
	GameManager.debug(LOG_PREFIX+"Измерение {} выключено\n", 
		[str(uid) if uid else "без uid"]
	)


## Включает измерение.
func enable() -> void:
	self.visible = true
	self.background.visible = true
	self.enabled = true
	self.background.enabled = true
	for child: Node2D in get_children():
		var object: Node2D = child as Node2D
		if object.has_method("enable_collisions"): object.enable_collisions()
	GameManager.debug(LOG_PREFIX+"Состояние измерения {} включено\n", 
			[str(uid) if uid else "без uid"]
	)
