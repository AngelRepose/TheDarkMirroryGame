extends Node2D
## Базовый класс уровня с поддержкой двух измерений
class_name BaseLevel

## Вызывается при смене измерения
signal dimension_changed(dimension: Dimension)

## Перечисление измерений
enum Dimension {DIM1 = 0, DIM2 = 1}

## Сцена игрока
@export var player: Player
@export var spawn_point: Node2D

@export_group("Измерения")
## Измерение по умолчанию при старте уровня
@export var default_dimension: Dimension = Dimension.DIM1
## Сдвиг при телепортации меж измерениями (по X вправо) в пикселях. В блоках - *32
@export var dimension_offset: float = 1000*32
## Нода 1 измерения
@export var dimension_1: TileMapLayer
## 
@export var dimension_1_bg: TileMapLayer

## Нода 2 измерения
@export var dimension_2: TileMapLayer
@export var dimension_2_bg: TileMapLayer

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
@export var swap_color: Color = Color.WHITE

## Использовать прозрачный цвет для затухания
@export var swap_fade_to_transparent: bool = true

## Задержка перед сменой измерения (после вспышки)
@export var swap_delay: float = 0.0

## Текущее активное измерение
var current_dimension: Dimension = default_dimension

## Флаг процесса перезапуска уровня
var _is_restarting: bool = false

## Менеджер триггеров
var trigger_manager: TriggerManager

func _ready() -> void:
	add_to_group("Level")
	if not _validate_nodes():
		return
	if spawn_point:
		player.position = spawn_point.position
	_apply_dimension_swap(default_dimension)
	_connect_player_signals()
	_setup_trigger_manager()
	FadeManager.default_color = restart_fade_color

func _setup_trigger_manager() -> void:
	# Ищем существующий TriggerManager или создаём новый
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
	tween.tween_callback(_apply_dimension_swap)
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

func _apply_dimension_swap(dimension: Variant = null) -> void:
	if dimension != null:
		current_dimension = dimension
	else:
		current_dimension = Dimension.DIM1 if current_dimension == Dimension.DIM2 else Dimension.DIM2
	
	_update_dimensions()
	dimension_changed.emit(current_dimension)
	
func _update_dimensions() -> void:
	var is_dim2 := current_dimension
	
	dimension_1.enabled = not is_dim2
	dimension_1.visible = not is_dim2
	dimension_1_bg.visible = not is_dim2
	dimension_2.enabled = is_dim2
	dimension_2.visible = is_dim2
	dimension_2_bg.visible = is_dim2

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
