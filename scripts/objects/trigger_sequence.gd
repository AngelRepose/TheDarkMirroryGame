extends Node

## Менеджер последовательности активации триггеров.
## Требует активации триггеров в определённом порядке.

class_name TriggerSequence

## Вызывается при успешном выполнении
signal sequence_completed(sequence: TriggerSequence)

## Вызывается при нарушении последовательности
signal sequence_failed(sequence: TriggerSequence)

## Вызывается при прогрессе
signal sequence_progress(current_index: int, total: int)

## Префикс для логирования
const LOG_PREFIX: StringName = &"[TriggerSequence] "

## Требуется ли строгая последовательность
@export var require_sequence: bool = true

## Список идентификаторов триггеров в порядке
@export var trigger_sequence: Array[String] = []

## Можно ли сбросить при ошибке
@export var reset_on_fail: bool = true

## Задержка перед сбросом
@export var reset_delay: float = 0.5

## Ограничение времени (0 = без ограничения)
@export var time_limit: float = 0.0

## Текущий индекс
var current_index: int = 0

## Таймер времени
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


## Подключается к триггерам.
func _connect_to_triggers() -> void:
	var parent: Node = get_parent()
	if not parent:
		return
	
	for child: Node in parent.get_children():
		if child is BaseActivator:
			var activator: BaseActivator = child as BaseActivator
			activator.activated.connect(_on_trigger_activated)
		
		for grandchild: Node in child.get_children():
			if grandchild is BaseActivator:
				var activator: BaseActivator = grandchild as BaseActivator
				activator.activated.connect(_on_trigger_activated)


## Вызывается при активации триггера.
## [param activator] — активировавший объект
func _on_trigger_activated(activator: BaseActivator) -> void:
	if _is_completed:
		return
	
	if trigger_sequence.is_empty():
		return
	
	var trigger_id: String = activator.trigger_id
	if trigger_id.is_empty():
		push_warning(LOG_PREFIX + "Активатор без trigger_id")
		return
	
	if require_sequence:
		_handle_sequential_trigger(trigger_id)
	else:
		_handle_any_order_trigger(trigger_id)


## Обрабатывает триггер в последовательном режиме.
## [param trigger_id] — идентификатор триггера
func _handle_sequential_trigger(trigger_id: String) -> void:
	var expected_id: String = trigger_sequence[current_index]
	
	if trigger_id == expected_id:
		_progress_sequence()
	else:
		_fail_sequence()


## Обрабатывает триггер в произвольном порядке.
## [param trigger_id] — идентификатор триггера
func _handle_any_order_trigger(trigger_id: String) -> void:
	if trigger_id in trigger_sequence:
		_progress_sequence()


## Продвигает последовательность.
func _progress_sequence() -> void:
	current_index += 1
	_is_active = true
	
	sequence_progress.emit(current_index, trigger_sequence.size())
	
	GameManager.debug(self.LOG_PREFIX\
	+ "Прогресс: {}/{}\n", 
	[current_index, trigger_sequence.size()]
	)

	if current_index >= trigger_sequence.size():
		_complete_sequence()


## Завершает последовательность.
func _complete_sequence() -> void:
	_is_completed = true
	_is_active = false
	GameManager.debug(self.LOG_PREFIX\
	+ "Последовательность завершена\n", 
	[]
	)
	sequence_completed.emit(self)


## Проваливает последовательность.
func _fail_sequence() -> void:
	GameManager.debug(self.LOG_PREFIX\
	+ "Последовательность провалена\n", 
	[]
	)
	sequence_failed.emit(self)
	
	if reset_on_fail:
		if reset_delay > 0.0:
			await get_tree().create_timer(reset_delay).timeout
		reset_sequence()


## Сбрасывает последовательность.
func reset_sequence() -> void:
	current_index = 0
	_time_timer = 0.0
	_is_active = false
	_is_completed = false


## Получает прогресс (0.0 - 1.0).
func get_progress() -> float:
	if trigger_sequence.is_empty():
		return 0.0
	return float(current_index) / float(trigger_sequence.size())


## Проверяет, завершена ли последовательность.
func is_completed() -> bool:
	return _is_completed
