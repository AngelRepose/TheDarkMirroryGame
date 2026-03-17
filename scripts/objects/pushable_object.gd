extends CharacterBody2D

## Физический объект, который можно толкать.
## Поддерживает сохранение позиции и вращения.

class_name PushableObject

## Префикс для логирования
var LOG_PREFIX: StringName = &"[PushableObject] "

## Состояния объекта
enum State {IDLE, PUSHED, SLIDING, AIR}

## Константы физики
const AIR_ROTATION_SPEED: float = 5.0
const FLOOR_STICKY_FORCE: float = 10.0
const PUSH_NORMAL_THRESHOLD: float = 0.5

## Уникальный идентификатор для сохранения
@export var uid: StringName = &""

## Максимальная скорость толкания
@export var max_push_speed: float = 140.0

## Ускорение при толкании
@export var push_accel: float = 900.0

## Сила трения
@export var friction: float = 1200.0

## Максимальный угол стабильности в градусах
@export var max_stable_angle: float = 25.0

## Скорость адаптации вращения
@export var rotation_speed: float = 8.0

## Гравитация из настроек проекта
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

## Текущее состояние
var current_state: State = State.IDLE

## Направление толчка
var _push_dir: float = 0.0

## Текущий угол поворота
var _current_rotation: float = 0.0

## Целевой угол поворота
var _target_rotation: float = 0.0

## Начальная позиция
var _initial_position: Vector2 = Vector2.ZERO

## Ссылка на уровень
var _level: BaseLevel = null


func _ready() -> void:
	add_to_group("Pushable")
	floor_max_angle = deg_to_rad(46)
	floor_snap_length = 10.0
	floor_constant_speed = true

	_initial_position = position
	_level = _find_level()
	
	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен, uid: {}\n", 
	[str(uid) if uid else "без uid"]
	)


func _physics_process(delta: float) -> void:
	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = FLOOR_STICKY_FORCE

	var normal: Vector2 = get_floor_normal() if is_on_floor() else Vector2.UP
	var slope_angle: float = rad_to_deg(acos(normal.dot(Vector2.UP)))
	
	# Определяем состояние
	if not is_on_floor():
		current_state = State.AIR
	elif _push_dir != 0:
		current_state = State.PUSHED
	elif slope_angle > max_stable_angle:
		current_state = State.SLIDING
	else:
		current_state = State.IDLE
	
	# Обрабатываем состояние
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.PUSHED:
			_state_pushed(delta)
		State.SLIDING:
			_state_sliding(normal, delta)
		State.AIR:
			_state_air(delta)
	
	# Вращение
	if is_on_floor():
		_target_rotation = normal.angle() + PI / 2.0
		_current_rotation = lerp_angle(_current_rotation, _target_rotation, rotation_speed * delta)
	else:
		_current_rotation = lerp_angle(_current_rotation, 0.0, AIR_ROTATION_SPEED * delta)
	
	rotation = _current_rotation
	
	move_and_slide()
	_propagate_push()
	_push_dir = 0.0


## Сбрасывает в начальное положение.
func reset_position() -> void:
	position = _initial_position
	_current_rotation = 0.0
	rotation = 0.0
	velocity = Vector2.ZERO


## Применяет толчок к объекту.
## [param dir] — направление толчка (-1, 0, 1)
func apply_push(dir: float) -> void:
	_push_dir = dir


## Обрабатывает состояние покоя.
## [param delta] — время между кадрами
func _state_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)


## Обрабатывает состояние толкания.
## [param delta] — время между кадрами
func _state_pushed(delta: float) -> void:
	velocity.x = move_toward(velocity.x, _push_dir * max_push_speed, push_accel * delta)


## Обрабатывает состояние скольжения.
## [param normal] — нормаль поверхности
## [param delta] — время между кадрами
func _state_sliding(normal: Vector2, delta: float) -> void:
	var slide_dir: float = sign(normal.x)
	velocity.x = move_toward(velocity.x, slide_dir * max_push_speed, 700.0 * delta)


## Обрабатывает состояние в воздухе.
## [param delta] — время между кадрами
func _state_air(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * 0.1 * delta)


## Передаёт толчок другим объектам.
func _propagate_push() -> void:
	var push_direction: float = 0.0

	if _push_dir != 0:
		push_direction = sign(_push_dir)
	elif abs(velocity.x) > 1.0:
		push_direction = sign(velocity.x)

	if push_direction == 0:
		return

	for i: int in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		
		if collider and collider.is_in_group("Pushable"):
			var collision_normal: Vector2 = collision.get_normal()
			
			if abs(collision_normal.x) > PUSH_NORMAL_THRESHOLD:
				if (push_direction > 0 and collision_normal.x < 0) or \
						(push_direction < 0 and collision_normal.x > 0):
					if collider.has_method("apply_push"):
						collider.apply_push(push_direction)


## Находит родительский уровень.
## Возвращает найденный уровень или null.
func _find_level() -> BaseLevel:
	var node: Node = get_parent()
	while node:
		if node is BaseLevel:
			return node
		node = node.get_parent()
	return null
