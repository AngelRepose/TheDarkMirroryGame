extends StaticBody2D

## Шипы, наносящие периодический урон игроку при касании.

class_name Spike

## Префикс для логирования
var LOG_PREFIX: StringName = &"[Spike] "

## Количество урона
@export var damage_amount: int = 1

## Интервал между нанесением урона
@export var damage_interval: float = 0.5

## Зона обнаружения
@onready var death_zone: Area2D = $DeathZone as Area2D

## Игрок в зоне
var player_in_zone: Player = null

## Таймер урона
var damage_timer: Timer = null

@onready var _orig_collision_layer: int = self.collision_layer
@onready var _orig_collision_mask: int = self.collision_mask

func disable_collisions() -> void:
	self.collision_layer = 0
	self.collision_mask = 0
	self.death_zone.monitoring = false
	
func enable_collisions() -> void:
	self.collision_layer = _orig_collision_layer
	self.collision_mask = _orig_collision_mask
	self.death_zone.monitoring = true
	
func toggle_collisions() -> void:
	if self.collision_layer == 0 and self.collision_mask == 0:
		enable_collisions()
	else:
		disable_collisions()

func _ready() -> void:
	damage_timer = Timer.new()
	damage_timer.wait_time = damage_interval
	damage_timer.one_shot = false
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(damage_timer)

	if death_zone:
		death_zone.body_entered.connect(_on_body_entered)
		death_zone.body_exited.connect(_on_body_exited)

	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен, damage: {}\n", 
	[damage_amount]
	)


## Вызывается при входе тела в зону.
## [param body] — вошедший узел
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_zone = body
		_damage_player()
		if damage_timer.is_stopped():
			damage_timer.start()


## Вызывается при выходе тела из зоны.
## [param body] — вышедший узел
func _on_body_exited(body: Node2D) -> void:
	if body is Player and body == player_in_zone:
		player_in_zone = null
		if not damage_timer.is_stopped():
			damage_timer.stop()


## Вызывается по таймеру урона.
func _on_damage_timer_timeout() -> void:
	_damage_player()


## Наносит урон игроку.
func _damage_player() -> void:
	if player_in_zone and is_instance_valid(player_in_zone):
		if player_in_zone.can_take_damage():
			player_in_zone.damage(damage_amount)
