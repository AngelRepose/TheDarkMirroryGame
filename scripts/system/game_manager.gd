extends Node

## Глобальный менеджер игры.
## Управляет уровнями, переходами между сценами и состоянием игры.
## Автозагружается как GameManager.

## Префикс для логирования
const LOG_PREFIX: StringName = &"[GameManager] "

## Включён ли режим отладки
const DEBUG: bool = true
## Словарь уровней: uid -> PackedScene
var levels: Dictionary[StringName, PackedScene] = {
	&"level_1": preload("res://scenes/levels/level_1.tscn") as PackedScene,
	&"level_2": preload("res://scenes/levels/level_2.tscn") as PackedScene,
	&"level_3": preload("res://scenes/levels/level_3.tscn") as PackedScene,
	#&"level_4": preload("res://scenes/levels/level_4.tscn") as PackedScene,
}

## Ссылка на игрока
var player: Player = null

## Ссылка на текущий уровень
var level: BaseLevel = null

## Ссылка на HUD
var hud: HUD = null

## Ссылка на эффект смены измерения
var swap_effect: ColorRect = null


func _ready() -> void:
	GameManager.debug(self.LOG_PREFIX\
	+ "Успешно запущен!\n", 
	[]
	)
		

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func debug(text: String, values: Array = []) -> void:
	if DEBUG: print(text.format(values, "{}") if values else text)

## Возвращает ссылку на игрока.
func get_player() -> Player:
	return player


## Возвращает ссылку на текущий уровень.
func get_level() -> BaseLevel:
	return level


## Возвращает ссылку на HUD.
func get_hud() -> HUD:
	return hud


## Возвращает ссылку на эффект смены измерения.
func get_swap_effect() -> ColorRect:
	return swap_effect


## Возвращает уровень по его UID.
## [param uid] — уникальный идентификатор уровня
func get_level_by_uid(uid: StringName) -> PackedScene:
	return levels.get(uid, null)


## Возвращает уровень по пути к сцене.
## [param path] — путь к файлу сцены
func get_level_by_path(path: String) -> PackedScene:
	return levels.find_key(path)
	

## Возвращает уровень по его индексу.
## [param index] — порядковый номер уровня (начиная с 1)
func get_level_by_index(index: int) -> PackedScene:
	return levels.get(StringName("level_" + str(index)))


## Переходит к экрану выбора уровней.
func to_choise_levels() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/choice_levels.tscn")


## Переходит к главному меню.
func to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")


## Открывает уровень по его UID.
## [param level_uid] — уникальный идентификатор уровня
func open_level(level_uid: StringName) -> void:
	SaveManager.set_current_level(level_uid)
	var _level: PackedScene = get_level_by_uid(level_uid)
	if not _level: 
		to_main_menu()
		return
	GameManager.debug(self.LOG_PREFIX\
	+ "Загрузка уровня {}\n", 
	[_level.resource_path]
	)
	get_tree().change_scene_to_packed(_level)


## Завершает игру с сохранением прогресса.
func exit_game() -> void:
	GameManager.debug(self.LOG_PREFIX\
	+ "Bye!\n", 
	[]
	)
	SaveManager.save_game()
	get_tree().quit()
