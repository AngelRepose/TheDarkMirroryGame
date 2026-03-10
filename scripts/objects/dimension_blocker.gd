extends ActivatableObject
## Невидимый блок, который появляется только в определённом измерении
## Предотвращает прохождение головоломки "не тем путём"
class_name DimensionBlocker

## Измерение, в котором блок активен (0 = DIM1, 1 = DIM2)
@export var active_in_dimension: int = 0

## Размер блока в клетках
@export var block_size: Vector2 = Vector2.ONE

## Ссылка на уровень (автоопределение если пусто)
@export var level: BaseLevel

## Показывать ли отладочную визуализацию
@export var show_debug: bool = false

## Статический блок для коллизии
var _static_body: StaticBody2D

## Форма коллизии
var _collision_shape: CollisionShape2D

func _ready() -> void:
	super._ready()
	_create_block()
	_connect_level()
	_update_visibility()
	
func _create_block() -> void:
	_static_body = StaticBody2D.new()
	add_child(_static_body)
	
	_collision_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = block_size * 16.0
	_collision_shape.shape = shape
	_collision_shape.position = block_size * 8.0
	_static_body.add_child(_collision_shape)
	
	if show_debug:
		var debug := ColorRect.new()
		debug.color = Color(1.0, 0.0, 0.0, 0.3)
		debug.size = block_size * 16.0
		_static_body.add_child(debug)

func _connect_level() -> void:
	if level:
		level.dimension_changed.connect(_on_dimension_changed)
		return
	
	var parent := get_parent()
	while parent:
		if parent is BaseLevel:
			level = parent
			level.dimension_changed.connect(_on_dimension_changed)
			return
		parent = parent.get_parent()

func _on_dimension_changed(_dimension: BaseLevel.Dimension) -> void:
	_update_visibility()

func _update_visibility() -> void:
	if not _static_body or not level:
		return
	
	var is_active: bool = level.current_dimension == active_in_dimension
	_static_body.visible = is_active
	_collision_shape.disabled = not is_active
