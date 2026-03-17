extends Node2D

## Базовый класс уровня с поддержкой двух измерений.
## Управляет переключением измерений и логикой завершения.

class_name BaseLevel

## Вызывается при смене измерения
signal dimension_changed(dimension: int)

## Вызывается при завершении уровня
signal level_finished

## Префикс для логирования
var LOG_PREFIX: StringName = &"[BaseLevel] "

## Список измерений[br]
## [code]DIM1 = 0[/code]  Нормальное измерение[br]
## [code]DIM2 = 1[/code]  Альтернативное измерение
enum Dimension {
	DIM1 = 0, ## Нормальное измерение
	DIM2 = 1 ## Альтернативное измерение
}

## Уникальный идентификатор уровня для SaveManager
@export var level_uid: StringName = &"level_1"

## Измерение по умолчанию при старте уровня
@export var default_dimension: Dimension = Dimension.DIM1

## Нода 1 измерения
@export var dimension_1: BaseDimension = null

## Нода 2 измерения
@export var dimension_2: BaseDimension = null

## Список спавн-поинтов на уровне (индекс 0 = начало)
@export var spawn_points: Array[Marker2D] = []

## Перезапускать ли сцену при смерти игрока
@export var restart_on_player_died: bool = true

## Время затемнения при перезапуске
@export var restart_fade_out_time: float = 0.25

## Время появления при перезапуске
@export var restart_fade_in_time: float = 0.25

## Цвет затемнения при перезапуске
@export var restart_fade_color: Color = Color.BLACK

## Нода эффекта смены измерения
@export var swap_effect: ColorRect = null

## Длительность эффекта смены измерения
@export var swap_duration: float = 0.4

## Цвет вспышки при смене измерения
@export var swap_color: Color = Color(0.204, 0.0, 0.204, 1.0)

## Использовать прозрачный цвет для затухания
@export var swap_fade_to_transparent: bool = true

## Задержка перед сменой измерения
@export var swap_delay: float = 0.0

## Сцена игрока
@export var player: Player = null
@export var camera_limit_right: int = 100000000
## Меню завершения уровня
@export var finish_menu: FinishMenu = null

## Стартовый спавн-поинт (используется первый из списка или узел SpawnPoint)
@onready var spawn_point: Marker2D = get_node_or_null("SpawnPoint") as Marker2D

## Меню паузы
@onready var pause_menu: PauseMenu = get_node_or_null("PauseMenu") as PauseMenu

## Текущее активное измерение
var current_dimension: Dimension = default_dimension

## Менеджер триггеров
var trigger_manager: TriggerManager = null

## HUD
var hud: HUD = null

## Флаг перезапуска
var _is_restarting: bool = true

## Флаг паузы
var _is_paused: bool = false

## Флаг разрешения паузы
var _can_pause: bool = false


func _ready() -> void:
	_setup_pause_delay()
	add_to_group("Level")
	
	# Устанавливаем текущий уровень в SaveManager
	SaveManager.set_current_level(level_uid)
	
	if not _validate_nodes():
		return
	
	_update_dimensions(default_dimension)
	_setup_player_position()
	_connect_player_signals()
	_setup_hud()
	_setup_trigger_manager()
	
	FadeManager.default_color = restart_fade_color
	_is_restarting = false
	player.camera.limit_right = camera_limit_right
	GameManager.debug(self.LOG_PREFIX+"Уровень {} загружен\n", 
		[str(level_uid) if level_uid else "без uid"]
	)


func _input(event: InputEvent) -> void:
	if not _is_restarting:
		if event.is_action_pressed("ui_cancel") and _can_pause:
			_is_paused = not _is_paused
			if pause_menu:
				pause_menu.pause()

		if event.is_action_pressed("swap_dimension"):
			swap_dimension()


## Устанавливает начальную позицию игрока.
func _setup_player_position() -> void:
	var spawn_pos: Vector2 = Vector2.ZERO

	if spawn_point:
		spawn_pos = spawn_point.position
	else:
		spawn_pos = player.position

	player.position = spawn_pos
	GameManager.debug(self.LOG_PREFIX+"Спавн поинт уровня {} установлен на x: {} y: {}\n", 
		[str(level_uid) if level_uid else "без uid",
		player.position.x,
		player.position.y
		]
	)


## Настраивает задержку паузы.
func _setup_pause_delay() -> void:
	_can_pause = false
	var pause_timer: Timer = Timer.new()
	pause_timer.wait_time = 0.8
	pause_timer.one_shot = true
	pause_timer.timeout.connect(func(): _can_pause = true)
	add_child(pause_timer)
	pause_timer.start()


## Настраивает HUD.
func _setup_hud() -> void:
	hud = _find_child_by_type(HUD) as HUD
	if not hud:
		hud = HUD.new()
	hud.player = player
	hud.level = self


## Настраивает менеджер триггеров.
func _setup_trigger_manager() -> void:
	trigger_manager = _find_child_by_type(TriggerManager) as TriggerManager
	if not trigger_manager:
		trigger_manager = TriggerManager.new()
		trigger_manager.name = "TriggerManager"
		trigger_manager.level = self
		add_child(trigger_manager)


## Валидирует обязательные ноды.
## Возвращает true если все ноды на месте.
func _validate_nodes() -> bool:
	if not dimension_1 or not dimension_2:
		return false
	if not player:
		return false
	return true


## Подключает сигналы игрока.
func _connect_player_signals() -> void:
	player.died.connect(_on_player_died)


## Обновляет видимость измерений.
## [param dimension] — измерение для активации (null для переключения)
func _update_dimensions(dimension: Variant = null) -> void:
	if dimension != null:
		current_dimension = dimension
	else:
		current_dimension = Dimension.DIM1 if current_dimension == Dimension.DIM2 else Dimension.DIM2
	
	match current_dimension:
		Dimension.DIM1:
			dimension_1.enable()
			dimension_2.disable()
		Dimension.DIM2:
			dimension_2.enable()
			dimension_1.disable()
	GameManager.debug(self.LOG_PREFIX+"Измерение уровня {} изменено на {}\n", 
		[str(level_uid) if level_uid else "без uid",
		"нормальное" if current_dimension == Dimension.DIM1\
		else "альтернативное"]
	)
	dimension_changed.emit(current_dimension)


## Вызывается при смерти игрока.
func _on_player_died() -> void:
	restart_level()


## Перезагружает текущую сцену.
func _reload_scene() -> void:
	await FadeManager.fade_out(restart_fade_out_time)
	get_tree().reload_current_scene()
	await FadeManager.fade_in(restart_fade_in_time)


## Ищет дочерний узел по типу скрипта.
## [param type] — тип скрипта для поиска
## Возвращает найденный узел или null.
func _find_child_by_type(type: GDScript) -> Node:
	for child: Node in get_children():
		if is_instance_of(child, type):
			return child
	return null


## Вызывается при входе в зону смерти.
## [param body] — узел, вошедший в зону
func _on_death_zone_entered(body: Node2D) -> void:
	if body is Player:
		body.kill(true)


## Завершает уровень.
## [param _any] — неиспользуемый параметр для совместимости с сигналами
func _finish_level(_any: Variant = null) -> void:
	GameManager.debug(self.LOG_PREFIX+"Уровень {} завершен\n", 
		[str(level_uid) if level_uid else "без uid"]
	)

	SaveManager.complete_level(level_uid)

	level_finished.emit()
	get_tree().paused = true
	finish_menu.show()


## Перезапускает уровень (без сохранения состояния).
func restart_level() -> void:
	GameManager.debug(self.LOG_PREFIX+"Перезагрузка уровня {}\n", 
		[str(level_uid) if level_uid else "без uid"]
	)
	if _is_restarting:
		return
	_is_restarting = true
	_reload_scene()


## Переключает измерение.
func swap_dimension() -> void:
	var tween: Tween = create_tween()
	var fade_out_color: Color = Color.TRANSPARENT if swap_fade_to_transparent else Color(swap_color, 0)

	if swap_effect:
		tween.tween_property(swap_effect, "modulate", swap_color, swap_duration * 0.4)

	if swap_delay > 0:
		tween.tween_interval(swap_delay)

	tween.tween_callback(_update_dimensions)

	if swap_effect:
		tween.tween_property(swap_effect, "modulate", fade_out_color, swap_duration * 0.6)


## Возвращает менеджер триггеров.
func get_trigger_manager() -> TriggerManager:
	return trigger_manager
