extends CanvasLayer

## Меню паузы в игре.

class_name PauseMenu

## Префикс для логирования
const LOG_PREFIX: StringName = &"[PauseMenu] "

## Сцена главного меню для возврата при выходе
@onready var main_menu: PackedScene = preload("res://scenes/ui/menu.tscn") as PackedScene

## Родительский уровень для перезапуска
@onready var level: BaseLevel = get_parent() as BaseLevel

## Флаг разрешения на возобновление игры
## Используется для предотвращения мгновенного закрытия паузы при нажатии Escape
var can_resume: bool = false


func _ready() -> void:
	hide()
	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен\n", 
	[]
	)


func _process(_delta: float) -> void:
	if can_resume and Input.is_action_just_pressed("ui_cancel"):
		resume()
	elif not can_resume and Input.is_action_just_released("ui_cancel"):
		can_resume = true


## Возобновляет игру и скрывает меню паузы.
func resume() -> void:
	hide()
	get_tree().paused = false
	GameManager.debug(self.LOG_PREFIX\
	+ "Игра возобновлена\n", 
	[]
	)


## Ставит игру на паузу и показывает меню паузы.
func pause() -> void:
	show()
	can_resume = false
	get_tree().paused = true
	GameManager.debug(self.LOG_PREFIX\
	+ "Игра на паузе\n", 
	[]
	)


## Обрабатывает нажатие кнопки "Продолжить".
func _on_resume_pressed() -> void:
	resume()


## Обрабатывает нажатие кнопки "Перезапустить".
func _on_restart_pressed() -> void:
	resume()
	level._reload_scene()


## Обрабатывает нажатие кнопки "Выход в меню".
func _on_exit_pressed() -> void:
	resume()
	GameManager.to_choise_levels()
