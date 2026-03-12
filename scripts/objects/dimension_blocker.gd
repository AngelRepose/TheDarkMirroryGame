extends ActivatableObject
## Невидимый блок, который появляется только в определённом измерении
## Предотвращает прохождение головоломки "не тем путём"
class_name DimensionBlocker

## Измерение, в котором блок активен (0 = DIM1, 1 = DIM2)
@export var active_in_dimension: int = 0

## Размер блока в клетках
@export var block_size: Vector2 = Vector2(1, 1)

## Ссылка на уровень
@export var level: BaseLevel

## Показывать ли отладочную визуализацию
@export var show_debug: bool = false

## Статический блок для коллизии
var _static_body: StaticBody2D

## Форма коллизии
var _collision_shape: CollisionShape2D

## Отладочный прямоугольник
var _debug_rect: ColorRect

## Предыдущее состояние видимости
var _was_visible: bool = false

func _ready() -> void:
	super._ready()
	_create_block()
	_update_visibility()
	
	if level:
		level.dimension_changed.connect(_on_dimension_changed)
	else:
		level = _find_level()
		if level:
			level.dimension_changed.connect(_on_dimension_changed)

func _create_block() -> void:
	_static_body = StaticBody2D.new()
	_static_body.name = "DimensionBlockerBody"
	add_child(_static_body)
	
	_collision_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = block_size * 16.0
	_collision_shape.shape = rect
	_collision_shape.position = block_size * 8.0
	_static_body.add_child(_collision_shape)
	
	if show_debug:
		_debug_rect = ColorRect.new()
		_debug_rect.color = Color(1.0, 0.0, 0.0, 0.3)
		_debug_rect.size = block_size * 16.0
		_static_body.add_child(_debug_rect)

func _on_dimension_changed(_dimension: BaseLevel.Dimension) -> void:
	_update_visibility()

func _update_visibility() -> void:
	if not _static_body or not level:
		return
	
	var should_be_visible: bool = level.current_dimension == active_in_dimension
	
	# Оптимизация: обновляем только при изменении
	if should_be_visible == _was_visible:
		return
	
	_was_visible = should_be_visible
	_static_body.visible = should_be_visible
	_collision_shape.disabled = not should_be_visible

func _find_level() -> BaseLevel:
	var node := get_parent()
	while node:
		if node is BaseLevel:
			return node
		node = node.get_parent()
	return null
