extends ActivatableObject
## Телепортирует игрока в указанную точку при активации
class_name Teleporter

## Целевая позиция телепортации
@export var target_position: Vector2 = Vector2.ZERO

## Нужно ли сохранять скорость при телепортации
@export var preserve_velocity: bool = false

## Эффект при телепортации (через FadeManager)
@export var fade_effect: bool = true

## Длительность эффекта затемнения
@export var fade_duration: float = 0.2

## Зона телепортации (автоматическая активация при входе игрока)
@export var auto_trigger_zone: Area2D

## Телепортировать только в определённом измерении
@export var dimension_specific: bool = false

## Измерение, в котором работает телепорт (если dimension_specific = true)
@export var active_dimension: int = 0

## Ссылка на уровень
@export var level: BaseLevel

## Игрок в зоне телепортации
var _player_in_zone: Player = null

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
	# Найти игрока на уровне
	var player := _find_player()
	if player:
		_do_teleport(player)

func _do_teleport(player: Player) -> void:
	if not player or not is_instance_valid(player):
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

func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		return null
	return players[0] as Player
