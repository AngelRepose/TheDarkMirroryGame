extends Node
## Менеджер последовательности активации триггеров
class_name TriggerSequence

## Вызывается при успешном выполнении последовательности
signal sequence_completed()

## Вызывается при нарушении последовательности
signal sequence_failed()

## Вызывается при прогрессе последовательности
signal sequence_progress(current_index: int, total: int)

## Требуется ли строгая последовательность активации
@export var require_sequence: bool = true

## Список идентификаторов триггеров в нужном порядке
@export var trigger_sequence: Array[String] = []

## Можно ли сбросить последовательность при ошибке
@export var reset_on_fail: bool = true

## Задержка перед сбросом при ошибке (в секундах)
@export var reset_delay: float = 0.5

## Время на выполнение всей последовательности (0 = без ограничения)
@export var time_limit: float = 0.0

## Текущий индекс в последовательности
var current_index: int = 0

## Таймер ограничения времени
var _time_timer: float = 0.0

## Активирована ли последовательность
var _is_active: bool = false

## Завершена ли последовательность
var _is_completed: bool = false

func _ready() -> void:
	_connect_to_triggers()

func _process(delta: float) -> void:
	if _is_active and time_limit > 0.0:
		_time_timer += delta
		if _time_timer >= time_limit:
			_fail_sequence()

func _connect_to_triggers() -> void:
	var parent := get_parent()
	if not parent:
		return
	
	for child in parent.get_children():
		if child is BaseActivator:
			var activator: BaseActivator = child as BaseActivator
			activator.activated.connect(_on_trigger_activated.bind(activator))

func _on_trigger_activated(activator: BaseActivator) -> void:
	if _is_completed:
		return
	
	if trigger_sequence.is_empty():
		return
	
	var trigger_id := activator.trigger_id
	if trigger_id.is_empty():
		push_warning("TriggerSequence: activator has no trigger_id")
		return
	
	if require_sequence:
		_handle_sequential_trigger(trigger_id)
	else:
		_handle_any_order_trigger(trigger_id)

func _handle_sequential_trigger(trigger_id: String) -> void:
	var expected_id := trigger_sequence[current_index]
	
	if trigger_id == expected_id:
		_progress_sequence()
	else:
		_fail_sequence()

func _handle_any_order_trigger(trigger_id: String) -> void:
	if trigger_id in trigger_sequence:
		_progress_sequence()

func _progress_sequence() -> void:
	current_index += 1
	_is_active = true
	
	sequence_progress.emit(current_index, trigger_sequence.size())
	
	if current_index >= trigger_sequence.size():
		_complete_sequence()

func _complete_sequence() -> void:
	_is_completed = true
	_is_active = false
	sequence_completed.emit()

func _fail_sequence() -> void:
	sequence_failed.emit()
	
	if reset_on_fail:
		if reset_delay > 0.0:
			await get_tree().create_timer(reset_delay).timeout
		reset_sequence()

func reset_sequence() -> void:
	current_index = 0
	_time_timer = 0.0
	_is_active = false
	_is_completed = false

func get_progress() -> float:
	if trigger_sequence.is_empty():
		return 0.0
	return float(current_index) / float(trigger_sequence.size())

func is_completed() -> bool:
	return _is_completed
