extends ActivatableObject

## Телепортирует игрока в указанную точку при активации.

class_name Teleporter

## Целевая позиция
@export var target_position: Vector2 = Vector2.ZERO

## Сохранять ли скорость
@export var preserve_velocity: bool = false

## Эффект затемнения
@export var fade_effect: bool = true

## Длительность затемнения
@export var fade_duration: float = 0.2

## Зона автоматической телепортации
@export var auto_trigger_zone: Area2D = null

## Работать только в определённом измерении
@export var dimension_specific: bool = false

## Измерение для работы
@export var active_dimension: int = 0

## Ссылка на уровень
@export var level: BaseLevel = null

## Игрок в зоне
var _player_in_zone: Player = null

## Кэшированный игрок
var _cached_player: Player = null


func _ready() -> void:
	super._ready()
	LOG_PREFIX = &"[Teleporter] "
	if auto_trigger_zone:
		auto_trigger_zone.body_entered.connect(_on_body_entered)
		auto_trigger_zone.body_exited.connect(_on_body_exited)

	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен, target: {}\n", 
	[target_position]
	)


## Вызывается при входе тела в зону.
## [param body] — вошедший узел
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_zone = body
		_try_teleport(body)


## Вызывается при выходе тела из зоны.
## [param body] — вышедший узел
func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_zone = null


## Пытается телепортировать игрока.
## [param player] — игрок для телепортации
func _try_teleport(player: Player) -> void:
	if dimension_specific and level:
		if level.current_dimension != active_dimension:
			return
	
	_do_teleport(player)


## Активирует телепорт.
## [param _activator] — активировавший объект
func _activate(_activator: BaseActivator) -> void:
	var player_node: Player = _get_player()
	if player_node:
		_do_teleport(player_node)


## Выполняет телепортацию.
## [param player_node] — игрок для телепортации
func _do_teleport(player_node: Player) -> void:
	if not is_instance_valid(player_node):
		return
	
	if fade_effect:
		await FadeManager.fade_out(fade_duration)
	
	var velocity_cache: Vector2 = player_node.velocity
	player_node.global_position = target_position
	
	if preserve_velocity:
		player_node.velocity = velocity_cache
	else:
		player_node.velocity = Vector2.ZERO
	
	if fade_effect:
		await FadeManager.fade_in(fade_duration)


## Получает игрока.
## Возвращает найденного игрока или null.
func _get_player() -> Player:
	if _cached_player and is_instance_valid(_cached_player):
		return _cached_player
	
	var players: Array[Node] = get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		return null
	
	_cached_player = players[0] as Player
	return _cached_player
