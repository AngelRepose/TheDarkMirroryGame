extends Area2D

## Чекпоинт - точка сохранения прогресса на уровне.
## При активации устанавливает новый спавн-поинт.

class_name Checkpoint

## Сигнал активации
signal activated

## Префикс для логирования
var LOG_PREFIX: StringName = &"[Checkpoint] "

## Индекс спавн-поинта
@export var spawn_index: int = 1

## Можно ли активировать повторно
@export var one_shot: bool = true

## Анимированный спрайт
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D as AnimatedSprite2D

## Эффект частиц
@onready var particles: GPUParticles2D = $GPUParticles2D as GPUParticles2D

## Свет
@onready var light: PointLight2D = $PointLight2D as PointLight2D

## Флаг активации
var _is_activated: bool = false

## Ссылка на уровень
var _level: BaseLevel = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_level = _find_level()
	
	_load_state()
	_update_visuals()


## Вызывается при входе тела в зону.
## [param body] — вошедший узел
func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	
	if _is_activated and one_shot:
		return
	
	_activate()


## Активирует чекпоинт.
func _activate() -> void:
	_is_activated = true
	
	if _level:
		_level.set_checkpoint(spawn_index)
	
	_update_visuals()
	activated.emit()
	
	GameManager.debug(self.LOG_PREFIX\
	+ "Активирован, spawn_index: {}\n", 
	[spawn_index]
	)

	# Воспроизводим эффект
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("activate"):
		anim.play("activate")
	
	if particles:
		particles.emitting = true


## Обновляет визуальное состояние.
func _update_visuals() -> void:
	if anim:
		if _is_activated:
			if anim.sprite_frames and anim.sprite_frames.has_animation("active"):
				anim.play("active")
		else:
			if anim.sprite_frames and anim.sprite_frames.has_animation("inactive"):
				anim.play("inactive")
	
	if light:
		light.enabled = _is_activated


## Загружает состояние из уровня.
func _load_state() -> void:
	if _level and _level.get_current_spawn_index() >= spawn_index:
		_is_activated = true
		_update_visuals()


## Находит родительский уровень.
## Возвращает найденный уровень или null.
func _find_level() -> BaseLevel:
	var node: Node = get_parent()
	while node:
		if node is BaseLevel:
			return node
		node = node.get_parent()
	return null
