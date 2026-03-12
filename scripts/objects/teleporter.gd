extends ActivatableObject
## Телепортирует игрока в указанную точку при активации
class_name Teleporter

## Целевая позиция телепортации
@export var target_position: Vector2 = Vector2.ZERO

## Сохранять ли скорость при телепортации
@export var preserve_velocity: bool = false

## Эффект затемнения при телепортации
@export var fade_effect: bool = true

## Длительность затемнения
@export var fade_duration: float = 0.2

## Зона автоматической телепортации
@export var auto_trigger_zone: Area2D

## Работать только в определённом измерении
@export var dimension_specific: bool = false

## Измерение для работы (0 = DIM1, 1 = DIM2)
@export var active_dimension: int = 0

## Ссылка на уровень
@export var level: BaseLevel

## Игрок в зоне
var _player_in_zone: Player = null

## Кэшированный игрок
var _cached_player: Player = null

func _ready() -> void:
	super._ready()
	
	if auto_trigger_zone:
		auto_trigger_zone.body_entered.connect(_on_body_entered)
		auto_trigger_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_zone = body
		_try_teleport(body)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_zone = null

func _try_teleport(player: Player) -> void:
	if dimension_specific and level:
		if level.current_dimension != active_dimension:
			return
	
	_do_teleport(player)

func _activate(_activator: BaseActivator) -> void:
	var player := _get_player()
	if player:
		_do_teleport(player)

func _do_teleport(player: Player) -> void:
	if not is_instance_valid(player):
		return
	
	if fade_effect:
		await FadeManager.fade_out(fade_duration)
	
	var velocity := player.velocity
	player.global_position = target_position
	
	if preserve_velocity:
		player.velocity = velocity
	else:
		player.velocity = Vector2.ZERO
	
	if fade_effect:
		await FadeManager.fade_in(fade_duration)

func _get_player() -> Player:
	if _cached_player and is_instance_valid(_cached_player):
		return _cached_player
	
	var players := get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		return null
	
	_cached_player = players[0] as Player
	return _cached_player
