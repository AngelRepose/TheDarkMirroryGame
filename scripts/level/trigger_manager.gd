extends Node

## Глобальный менеджер триггеров на уровне.
## Собирает и управляет всеми активаторами и активируемыми объектами.

class_name TriggerManager

## Вызывается при активации любого триггера
signal trigger_activated(trigger_id: String, activator: BaseActivator)

## Вызывается при деактивации любого триггера
signal trigger_deactivated(trigger_id: String, activator: BaseActivator)

## Префикс для логирования
var LOG_PREFIX: StringName = &"[TriggerManager] "

## Родительский уровень
@export var level: BaseLevel = null

## Все триггеры на уровне (id -> Array[BaseActivator])
var _triggers: Dictionary = {}

## Все активируемые объекты
var _activatables: Array[ActivatableObject] = []

## Все последовательности триггеров
var _sequences: Array[TriggerSequence] = []


func _ready() -> void:
	_collect_triggers()
	_connect_triggers()
	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен. Триггеров: {}, Активируемых: {} \n", 
		[str(_triggers.size()),
		_activatables.size(),
		]
	)
	


## Собирает все триггеры на уровне.
func _collect_triggers() -> void:
	if not level:
		return
	
	# Собираем все активаторы
	for child: Node in level.get_children():
		_collect_triggers_recursive(child)
	
	# Собираем последовательности
	for child: Node in level.get_children():
		if child is TriggerSequence:
			_sequences.append(child)
			child.sequence_completed.connect(_on_sequence_completed)
			child.sequence_failed.connect(_on_sequence_failed)


## Рекурсивно собирает триггеры.
## [param node] — узел для обхода
func _collect_triggers_recursive(node: Node) -> void:
	if node is BaseActivator:
		var activator: BaseActivator = node as BaseActivator
		var id: String = activator.trigger_id
		if not id.is_empty():
			if not _triggers.has(id):
				_triggers[id] = []
			_triggers[id].append(activator)
	
	if node is ActivatableObject:
		_activatables.append(node as ActivatableObject)
	
	for child: Node in node.get_children():
		_collect_triggers_recursive(child)


## Подключает сигналы триггеров.
func _connect_triggers() -> void:
	for id: String in _triggers:
		for activator: BaseActivator in _triggers[id]:
			activator.activated.connect(_on_trigger_activated)
			activator.deactivated.connect(_on_trigger_deactivated)


## Вызывается при активации триггера.
## [param activator] — активировавший объект
func _on_trigger_activated(activator: BaseActivator) -> void:
	trigger_activated.emit(activator.trigger_id, activator)


## Вызывается при деактивации триггера.
## [param activator] — деактивировавший объект
func _on_trigger_deactivated(activator: BaseActivator) -> void:
	trigger_deactivated.emit(activator.trigger_id, activator)


## Вызывается при завершении последовательности.
## [param sequence] — завершённая последовательность
func _on_sequence_completed(sequence: TriggerSequence) -> void:
	GameManager.debug(self.LOG_PREFIX\
	+ "Последовательность {} завершена\n", 
	[sequence.name]
	)


## Вызывается при провале последовательности.
## [param sequence] — проваленная последовательность
func _on_sequence_failed(sequence: TriggerSequence) -> void:
	GameManager.debug(self.LOG_PREFIX\
	+ "Последовательность {} провалена\n", 
	[sequence.name]
	)


## Получает триггеры по ID.
## [param trigger_id] — идентификатор триггера
## Возвращает массив активаторов.
func get_trigger_by_id(trigger_id: String) -> Array:
	return _triggers.get(trigger_id, [])


## Активирует триггер по ID.
## [param trigger_id] — идентификатор триггера
func activate_trigger(trigger_id: String) -> void:
	var triggers: Array = _triggers.get(trigger_id, [])
	for activator: BaseActivator in triggers:
		activator.activate()
	GameManager.debug(self.LOG_PREFIX\
	+ "Активирован триггер {}\n", 
	[trigger_id]
	)


## Деактивирует триггер по ID.
## [param trigger_id] — идентификатор триггера
func deactivate_trigger(trigger_id: String) -> void:
	var triggers: Array = _triggers.get(trigger_id, [])
	for activator: BaseActivator in triggers:
		activator.deactivate()
	GameManager.debug(self.LOG_PREFIX\
	+ "Деактивирован триггер {}\n", 
	[trigger_id]
	)


## Сбрасывает все последовательности.
func reset_all_sequences() -> void:
	for sequence: TriggerSequence in _sequences:
		sequence.reset_sequence()
	GameManager.debug(self.LOG_PREFIX\
	+ "Сброшены все последовательности\n")


## Получает прогресс последовательности.
## [param sequence_name] — имя последовательности
## Возвращает прогресс от 0.0 до 1.0.
func get_sequence_progress(sequence_name: String) -> float:
	for sequence: TriggerSequence in _sequences:
		if sequence.name == sequence_name:
			return sequence.get_progress()
	return 0.0
