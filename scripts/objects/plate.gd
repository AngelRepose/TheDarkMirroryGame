extends BaseActivator
## Нажимная плита, активируемая игроком или толкаемыми объектами
class_name Plate

## Типы активаторов плиты
enum ActivatorType {PLAYER, PUSHABLE, BOTH}

@export_group("Настройки")
## Кто может активировать плиту
@export var activator_type: ActivatorType = ActivatorType.BOTH

## Время удержания для срабатывания
@export var press_time: float = 0.1

## Измерение, в котором работает плита (-1 = любое)
@export var dimension: int = -1

## Анимированный спрайт плиты
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

## Зона обнаружения объектов
@onready var _push_zone: Area2D = $PushZone

## Объекты, находящиеся в зоне плиты
var _objects_in_zone: Array[Node2D] = []

## Таймер удержания
var _press_timer: float = 0.0

## Ссылка на уровень
var _level: BaseLevel

func _ready() -> void:
	super._ready()
	_push_zone.body_entered.connect(_on_body_entered)
	_push_zone.body_exited.connect(_on_body_exited)
	_level = _find_level()

func _process(delta: float) -> void:
	if not _is_in_correct_dimension():
		return
	
	var has_valid_activator: bool = _check_for_activators()
	
	if has_valid_activator:
		_press_timer = minf(_press_timer + delta, press_time)
	else:
		_press_timer = maxf(_press_timer - delta, 0.0)
	
	var should_be_pressed: bool = _press_timer >= press_time
	if should_be_pressed != is_active:
		if should_be_pressed:
			activate()
			_play_animation("press")
		else:
			deactivate()
			_play_animation("release")

func _is_in_correct_dimension() -> bool:
	if dimension < 0 or not _level:
		return true
	return _level.current_dimension == dimension

func _check_for_activators() -> bool:
	for obj: Node2D in _objects_in_zone:
		if not is_instance_valid(obj):
			continue
		match activator_type:
			ActivatorType.PLAYER:
				if obj is Player:
					return true
			ActivatorType.PUSHABLE:
				if obj is PushableObject:
					return true
			ActivatorType.BOTH:
				if obj is Player or obj is PushableObject:
					return true
	return false

func _update_visuals() -> void:
	pass

func _play_animation(anim_name: String) -> void:
	if _sprite and _sprite.animation != anim_name:
		_sprite.play(anim_name)

func _on_body_entered(body: Node2D) -> void:
	if not _objects_in_zone.has(body):
		_objects_in_zone.append(body)

func _on_body_exited(body: Node2D) -> void:
	_objects_in_zone.erase(body)

func _find_level() -> BaseLevel:
	var node := get_parent()
	while node:
		if node is BaseLevel:
			return node
		node = node.get_parent()
	return null
