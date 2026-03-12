extends BaseEntity
## Контроллер игрока с системой движения, прыжков и анимаций
class_name Player

@export_group("Движение")
## Скорость движения игрока
@export var walk_speed: float = 200.0

## Сила прыжка игрока
@export var jump_velocity: float = -400.0

@export_group("Дополнительные настройки")
## Время, в течении которого игрок все еще может прыгнуть
@export var coyote_time: float = 0.1

## Время, в течении которого после приземления буфферизуется нажатие прыжка
@export var jump_buffer_time: float = 0.05

@onready var camera: Camera2D = $Camera

## Таймер coyote time для прыжка после схода с платформы
var _coyote_timer: float = 0.0

## Таймер буфера прыжка
var _jump_buffer_timer: float = 0.0

## Текущее направление движения (-1, 0, 1)
var _direction: float = 0.0

## Предыдущее состояние нахождения на земле
var _was_on_floor: bool = false

func _ready() -> void:
	super._ready()
	add_to_group("Player")
	_was_on_floor = is_on_floor()

func _process_movement(delta: float) -> void:
	_jump_buffer_timer -= delta
	
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	_direction = Input.get_axis("move_left", "move_right")
	
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var can_jump := _jump_buffer_timer > 0.0 and (is_on_floor() or _coyote_timer > 0.0)
	
	if can_jump:
		_perform_jump()
	elif not is_on_floor():
		_process_air_logic()
	else:
		_process_ground_logic()
	
	move_and_slide()
	_handle_push_logic()
	
	_was_on_floor = is_on_floor()

func _update_animation_state() -> void:
	if _is_dead:
		return
	
	if _direction != 0:
		animated_sprite.flip_h = _direction < 0
	
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

func _perform_jump() -> void:
	velocity.y = jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0

func _process_air_logic() -> void:
	velocity.x = _direction * walk_speed

func _process_ground_logic() -> void:
	if _direction != 0:
		velocity.x = _direction * walk_speed
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)

func _handle_push_logic() -> void:
	for i: int in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		
		if not (collider and collider.is_in_group("Pushable")):
			continue
			
		var normal := collision.get_normal()
		
		if abs(normal.x) > PUSH_NORMAL_THRESHOLD:
			if (_direction > 0 and normal.x < -PUSH_NORMAL_THRESHOLD) or \
					(_direction < 0 and normal.x > PUSH_NORMAL_THRESHOLD):
				if collider.has_method("apply_push"):
					collider.apply_push(_direction)
