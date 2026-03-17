extends Control

## Главное меню игры.

class_name MainMenu

## Префикс для логирования
const LOG_PREFIX: StringName = &"[MainMenu] "

## Кнопка для перехода к выбору уровней
@onready var play_button: Button = \
$MarginContainer/VBoxContainer/PlayMargin/PlayContainer/PlayButton as Button

## Кнопка для выхода из игры
@onready var exit_button: Button = \
$MarginContainer/VBoxContainer/ExitMargin/ExitContainer/ExitButton as Button

## Кнопка "Сбросить прогресс" внизу
@onready var reset_all_button: Button = \
$MarginContainer/VBoxContainer/ResetMargin/ResetContainer/ResetButton as Button

## Меню подтвреждения
@onready var confirm_menu: Control = \
$CanvasLayer/Control as Control

## Кнопка "Да" в меню подтверждения
@onready var confirm_button: Button = \
$CanvasLayer/Control/MarginContainer/Panel/VBoxContainer/HBoxContainer/ConfirmButton as Button

## Кнопка "Нет" в меню подтверждения
@onready var discard_button: Button = \
$CanvasLayer/Control/MarginContainer/Panel/VBoxContainer/HBoxContainer/DiscardButton as Button

func _ready() -> void:
	self.play_button.pressed.connect(self._on_play_pressed)
	self.exit_button.pressed.connect(self._on_exit_pressed)
	self.reset_all_button.pressed.connect(self._on_reset_pressed)
	self.confirm_button.pressed.connect(self._on_confirm_reset_pressed)
	self.discard_button.pressed.connect(self._on_discard_reset_pressed)
	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен\n", 
	[]
	)


## Обрабатывает нажатие кнопки "Играть".
## Выполняет переход на сцену выбора уровней.
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/choice_levels.tscn")


## Обрабатывает нажатие кнопки "Выход".
## Завершает работу приложения.
func _on_exit_pressed() -> void:
	GameManager.exit_game()


func _on_reset_pressed() -> void:
	confirm_menu.show()
	
func _on_confirm_reset_pressed() -> void:
	SaveManager.reset_all_progress()
	get_tree().reload_current_scene()

func _on_discard_reset_pressed() -> void:
	confirm_menu.hide()
