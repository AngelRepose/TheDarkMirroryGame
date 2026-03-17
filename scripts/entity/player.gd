extends BaseEntity

## Контроллер игрока с системой движения, прыжков и анимаций.
## Обрабатывает ввод, физику и взаимодействие с объектами.

class_name Player

## Префикс для логирования


## Скорость ходьбы
@export var walk_speed: float = 200.0

## Сила прыжка
@export var jump_velocity: float = -400.0

## Время coyote time (можно прыгнуть после схода с платформы)
@export var coyote_time: float = 0.1

## Время буферизации нажатия прыжка
@export var jump_buffer_time: float = 0.05

## Камера игрока
@onready var camera: Camera2D = $Camera as Camera2D

## Таймер coyote time
var _coyote_timer: float = 0.0

## Таймер буфера прыжка
var _jump_buffer_timer: float = 0.0

## Текущее направление движения (-1, 0, 1)
var _direction: float = 0.0

## Предыдущее состояние нахождения на земле
var _was_on_floor: bool = false


func _ready() -> void:
	super._ready()
	LOG_PREFIX = &"[Player] "
	add_to_group("Player")
	_was_on_floor = is_on_floor()
	GameManager.debug(LOG_PREFIX+"Игрок {} загружен\n", [str(uid) if uid else "без uid"])


## Обрабатывает движение и физику игрока.
## [param delta] — время между кадрами
func _process_movement(delta: float) -> void:
	_jump_buffer_timer -= delta
	
	# Обновляем coyote timer
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	# Получаем направление движения
	_direction = Input.get_axis("move_left", "move_right")
	
	# Буферизируем нажатие прыжка
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Проверяем возможность прыжка
	var can_jump: bool = _jump_buffer_timer > 0.0 and (is_on_floor() or _coyote_timer > 0.0)
	
	if can_jump:
		_perform_jump()
	elif not is_on_floor():
		_process_air_logic()
	else:
		_process_ground_logic()
	
	move_and_slide()
	_handle_push_logic()
	
	_was_on_floor = is_on_floor()


## Обновляет состояние анимации.
func _update_animation_state() -> void:
	if _is_dead:
		return
	
	# Поворот спрайта
	if _direction != 0:
		animated_sprite.flip_h = _direction < 0
	
	# Выбор анимации
	if not is_on_floor():
		if velocity.y < 0:
			_play_animation("jump")
		else:
			_play_animation("fall")
	else:
		if _direction != 0:
			_play_animation("walk")
		else:
			_play_animation("idle")


## Выполняет прыжок.
func _perform_jump() -> void:
	velocity.y = jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


## Логика движения в воздухе.
func _process_air_logic() -> void:
	velocity.x = _direction * walk_speed


## Логика движения на земле.
func _process_ground_logic() -> void:
	if _direction != 0:
		velocity.x = _direction * walk_speed
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)


## Обрабатывает толкание объектов.
func _handle_push_logic() -> void:
	for i: int in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		
		if not (collider and collider.is_in_group("Pushable")):
			continue
		
		var normal: Vector2 = collision.get_normal()
		
		if abs(normal.x) > PUSH_NORMAL_THRESHOLD:
			if (_direction > 0 and normal.x < -PUSH_NORMAL_THRESHOLD) or \
					(_direction < 0 and normal.x > PUSH_NORMAL_THRESHOLD):
				if collider.has_method("apply_push"):
					collider.apply_push(_direction)
