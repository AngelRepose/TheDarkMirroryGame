extends ActivatableObject
## Спавнер ящиков — создаёт новый ящик при активации
class_name BoxSpawner

## Сцена ящика для спавна
@export var box_scene: PackedScene

## Максимальное количество ящиков (0 = без лимита)
@export var max_boxes: int = 1

## Задержка между спавнами
@export var spawn_cooldown: float = 1.0

## Смещение позиции спавна
@export var spawn_offset: Vector2 = Vector2.ZERO

## Удалять ли ящики при деактивации
@export var despawn_on_deactivate: bool = false

## Заспавненные ящики
var _spawned_boxes: Array[PushableObject] = []

## Можно ли спавнить
var _can_spawn: bool = true

func _activate(_activator: BaseActivator) -> void:
	if not _can_spawn:
		return
	
	if max_boxes > 0 and _spawned_boxes.size() >= max_boxes:
		# Удаляем старый ящик
		var old_box: PushableObject = _spawned_boxes.pop_front()
		if is_instance_valid(old_box):
			old_box.queue_free()
	
	_spawn_box()
	_start_cooldown()

func _deactivate(_activator: BaseActivator) -> void:
	if not despawn_on_deactivate:
		return
	
	for box: PushableObject in _spawned_boxes:
		if is_instance_valid(box):
			box.queue_free()
	
	_spawned_boxes.clear()

func _spawn_box() -> void:
	if not box_scene:
		push_warning("BoxSpawner: box_scene is not set")
		return
	
	var box: PushableObject = box_scene.instantiate() as PushableObject
	if not box:
		push_warning("BoxSpawner: box_scene is not a PushableObject")
		return
	
	get_parent().add_child(box)
	box.global_position = global_position + spawn_offset
	_spawned_boxes.append(box)

func _start_cooldown() -> void:
	_can_spawn = false
	await get_tree().create_timer(spawn_cooldown).timeout
	_can_spawn = true

func get_spawned_count() -> int:
	return _spawned_boxes.size()

func clear_all_boxes() -> void:
	for box: PushableObject in _spawned_boxes:
		if is_instance_valid(box):
			box.queue_free()
	_spawned_boxes.clear()
