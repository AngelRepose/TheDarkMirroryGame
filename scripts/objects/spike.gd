extends StaticBody2D
## Шипы, наносящие периодический урон игроку при касании
class_name Spike

## Количество урона, который получает игрок при касании
@export var damage_amount: int = 1

## Интервал между нанесением урона (в секундах)
@export var damage_interval: float = 0.5

## Зона обнаружения игрока
@onready var death_zone: Area2D = $DeathZone as Area2D

## Ссылка на игрока в зоне шипов
var player_in_zone: Player = null

## Таймер периодического урона
var damage_timer: Timer

func _ready() -> void:
	damage_timer = Timer.new()
	damage_timer.wait_time = damage_interval
	damage_timer.one_shot = false
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(damage_timer)

	if death_zone:
		death_zone.body_entered.connect(_on_body_entered)
		death_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_zone = body
		_damage_player()
		if damage_timer.is_stopped():
			damage_timer.start()

func _on_body_exited(body: Node2D) -> void:
	if body is Player and body == player_in_zone:
		player_in_zone = null
		if not damage_timer.is_stopped():
			damage_timer.stop()

func _on_damage_timer_timeout() -> void:
	_damage_player()

func _damage_player() -> void:
	if player_in_zone and is_instance_valid(player_in_zone):
		if player_in_zone.can_take_damage():
			player_in_zone.damage(damage_amount)
