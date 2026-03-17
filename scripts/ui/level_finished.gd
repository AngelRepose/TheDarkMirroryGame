extends CanvasLayer

## Панель завершения уровня.

class_name FinishMenu

## Префикс для логирования
const LOG_PREFIX: StringName = &"[FinishMenu] "

## Кнопка перехода к следующему уровню
@export var next_button: Button

## Кнопка выхода в меню выбора уровней
@export var exit_button: Button


func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	hide()
	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен\n", 
	[]
	)


## Обрабатывает нажатие кнопки "Следующий уровень".
func _on_next_pressed() -> void:
	var level_uid: StringName = SaveManager.get_next_level(SaveManager.current_level_uid)
	GameManager.debug(self.LOG_PREFIX\
	+ "Переход на следующий уровень: {}\n", 
	[level_uid]
	)
	get_tree().paused = false
	GameManager.open_level(level_uid)


## Обрабатывает нажатие кнопки "Выход".
func _on_exit_pressed() -> void:
	GameManager.debug(self.LOG_PREFIX\
	+ "Выход в меню выбора уровней\n", 
	[]
	)
	get_tree().paused = false
	GameManager.to_choise_levels()
