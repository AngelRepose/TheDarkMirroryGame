extends Area2D

## Зона завершения уровня.
## При входе игрока помечает уровень как пройденный.

class_name FinishLevel

## Префикс для логирования
var LOG_PREFIX: StringName = &"[FinishLevel] "

## Задержка перед завершением
@export var finish_delay: float = 0.5

## Показывать ли эффект
@export var show_effect: bool = true

## Ссылка на уровень
var _level: BaseLevel = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_level = _find_level()
	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен\n", 
	[]
	)


## Вызывается при входе тела в зону.
## [param body] — вошедший узел
func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	
	_finish_level()


## Завершает уровень.
func _finish_level() -> void:
	if show_effect:
		await FadeManager.fade_out_and_in(0.3, 0.3, finish_delay)
	
	if _level:
		_level._finish_level()


## Находит родительский уровень.
## Возвращает найденный уровень или null.
func _find_level() -> BaseLevel:
	var node: Node = get_parent()
	while node:
		if node is BaseLevel:
			return node
		node = node.get_parent()
	return null
