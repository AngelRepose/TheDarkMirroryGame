extends Node2D

## Базовый класс уровня с поддержкой двух измерений
class_name BaseLevel

## Вызывается при смене измерения
signal dimension_changed(dimension: Dimension)

## Перечисление измерений
enum Dimension {DIM1 = 0, DIM2 = 1}

## Сцена игрока
@export var player: Player

@export_group("Измерения")
## Измерение по умолчанию при старте уровня
@export var default_dimension: Dimension = Dimension.DIM1
## Нода 1 измерения
@export var dimension_1: BaseDimension

## Нода 2 измерения
@export var dimension_2: BaseDimension

@export_group("Перезапуск")
## Перезапускать ли сцену при смерти игрока
@export var restart_on_player_died: bool = true

## Время от прозрачного фона до полного затухания
@export var restart_fade_out_time: float = 0.25

## Время от полного затухания до прозрачного фона
@export var restart_fade_in_time: float = 0.25

## Цвет, которым затемняется экран
@export var restart_fade_color: Color = Color.BLACK

@export_group("Эффекты")
@export_subgroup("Смена измерения")
## Нода эффекта смены измерения
@export var swap_effect: ColorRect

## Длительность эффекта смены измерения (в секундах)
@export var swap_duration: float = 0.4

## Цвет вспышки при смене измерения
@export var swap_color: Color = Color(0.204, 0.0, 0.204, 1.0)

## Использовать прозрачный цвет для затухания
@export var swap_fade_to_transparent: bool = true

## Задержка перед сменой измерения (после вспышки)
@export var swap_delay: float = 0.0

@onready var spawn_point: SpawnPoint = get_node("SpawnPoint")
@onready var pause_menu: CanvasLayer = get_node("PauseMenu")
## Текущее активное измерение
var current_dimension: Dimension = default_dimension

var _is_restarting: bool = true
var _is_paused: bool = false
var _can_pause: bool = false  # Флаг разрешения на паузу
var hud: HUD

## Менеджер триггеров
var trigger_manager: TriggerManager

func _ready() -> void:
	_setup_pause_delay()
	add_to_group("Level")
	if not _validate_nodes():
		return
	_update_dimensions(default_dimension)
	if spawn_point:
		player.position = spawn_point.position
	_connect_player_signals()
	_setup_hud()
	_setup_trigger_manager()
	FadeManager.default_color = restart_fade_color
	_is_restarting = false
	player.camera.limit_right = 1152

func _finish_level(any = null) -> void:
	print("level finished")
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")

func _setup_pause_delay() -> void:
	_can_pause = false
	
	# Создаем и запускаем таймер
	var pause_timer := Timer.new()
	pause_timer.name = "PauseDelayTimer"
	pause_timer.wait_time = 0.8
	pause_timer.one_shot = true
	pause_timer.timeout.connect(_on_pause_delay_timeout)
	add_child(pause_timer)
	pause_timer.start()

func _on_pause_delay_timeout() -> void:
	_can_pause = true

func _input(event: InputEvent) -> void:
	if not _is_restarting:
		if event.is_action_pressed("ui_cancel") and _can_pause:
			_is_paused = not _is_paused
			pause_menu.pause()
	if event.is_action_pressed("swap_dimension"):
		swap_dimension()
		

func _on_death_zone_entered(body: Node2D) -> void:
	if not body is Player:
		return
	body.kill(true)
	

func _setup_hud() -> void:
	hud = _find_child_by_type(HUD) as HUD
	if not hud:
		hud = HUD.new()
	hud.player = player
	hud.level = self

func _setup_trigger_manager() -> void:
	trigger_manager = _find_child_by_type(TriggerManager) as TriggerManager
	if not trigger_manager:
		trigger_manager = TriggerManager.new()
		trigger_manager.name = "TriggerManager"
		trigger_manager.level = self
		add_child(trigger_manager)
	

func restart_level() -> void:
	if _is_restarting:
		return
	_is_restarting = true
	await _reload_scene()

func swap_dimension() -> void:
	var tween := create_tween()
	var fade_out_color := Color.TRANSPARENT if swap_fade_to_transparent else Color(swap_color, 0)
	tween.tween_property(swap_effect, "modulate", swap_color, swap_duration * 0.4)
	
	if swap_delay > 0:
		tween.tween_interval(swap_delay)
	tween.tween_callback(_update_dimensions)
	tween.tween_property(swap_effect, "modulate", fade_out_color, swap_duration * 0.6)

func _validate_nodes() -> bool:
	if not dimension_1 or not dimension_2:
		print_debug("Измерения не загружены на уровень!")
		return false
	
	if not player:
		print_debug("Сцена игрока не загружена в уровень!")
		return false
		
	return true

func _connect_player_signals() -> void:
	if not player.has_signal("died"):
		return
		
	print_debug("Сигнал игрока {player} died подключен к {func_name}".format({
		"player": player.name,
		"func_name": "_on_player_died"
	}))
	player.died.connect(_on_player_died)

func _update_dimensions(dimension: Variant = null) -> void:
	if dimension != null:
		current_dimension = dimension
	else:
		current_dimension = Dimension.DIM1 if current_dimension == Dimension.DIM2 else Dimension.DIM2
	
	match current_dimension:
		Dimension.DIM1: dimension_1.enable(); dimension_2.disable()
		Dimension.DIM2: dimension_2.enable(); dimension_1.disable()
	dimension_changed.emit(current_dimension)

func _on_player_died() -> void:
	restart_level()
	
func _reload_scene() -> void:
	await FadeManager.fade_out(restart_fade_out_time)
	get_tree().reload_current_scene()
	await FadeManager.fade_in(restart_fade_in_time)

func _find_child_by_type(type: GDScript) -> Node:
	for child in get_children():
		if is_instance_of(child, type):
			return child
	return null

func get_trigger_manager() -> TriggerManager:
	return trigger_manager
