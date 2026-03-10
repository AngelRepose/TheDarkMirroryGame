extends Node
## Глобальный менеджер триггеров на уровне
class_name TriggerManager

## Вызывается при активации любого триггера
signal trigger_activated(trigger_id: String, activator: BaseActivator)

## Вызывается при деактивации любого триггера
signal trigger_deactivated(trigger_id: String, activator: BaseActivator)

## Родительский уровень
@export var level: BaseLevel

## Все триггеры на уровне
var _triggers: Dictionary = {}

## Все активируемые объекты
var _activatables: Array[ActivatableObject] = []

## Все последовательности триггеров
var _sequences: Array[TriggerSequence] = []

func _ready() -> void:
	_collect_triggers()
	_connect_triggers()

func _collect_triggers() -> void:
	if not level:
		return
	
	# Собираем все активаторы
	for child in level.get_children():
		_collect_triggers_recursive(child)
	
	# Собираем последовательности
	for child in level.get_children():
		if child is TriggerSequence:
			_sequences.append(child)
			child.sequence_completed.connect(_on_sequence_completed.bind(child))
			child.sequence_failed.connect(_on_sequence_failed.bind(child))

func _collect_triggers_recursive(node: Node) -> void:
	if node is BaseActivator:
		var activator: BaseActivator = node as BaseActivator
		var id := activator.trigger_id
		if not id.is_empty():
			if not _triggers.has(id):
				_triggers[id] = []
			_triggers[id].append(activator)
	
	if node is ActivatableObject:
		_activatables.append(node as ActivatableObject)
	
	for child in node.get_children():
		_collect_triggers_recursive(child)

func _connect_triggers() -> void:
	for id: String in _triggers:
		for activator: BaseActivator in _triggers[id]:
			activator.activated.connect(_on_trigger_activated.bind(activator))
			activator.deactivated.connect(_on_trigger_deactivated.bind(activator))

func _on_trigger_activated(activator: BaseActivator) -> void:
	trigger_activated.emit(activator.trigger_id, activator)

func _on_trigger_deactivated(activator: BaseActivator) -> void:
	trigger_deactivated.emit(activator.trigger_id, activator)

func _on_sequence_completed(sequence: TriggerSequence) -> void:
	print_debug("TriggerSequence completed: ", sequence.name)

func _on_sequence_failed(sequence: TriggerSequence) -> void:
	print_debug("TriggerSequence failed: ", sequence.name)

func get_trigger_by_id(trigger_id: String) -> Array:
	return _triggers.get(trigger_id, [])

func activate_trigger(trigger_id: String) -> void:
	var triggers: Array = _triggers.get(trigger_id, [])
	for activator: BaseActivator in triggers:
		activator.activate()

func deactivate_trigger(trigger_id: String) -> void:
	var triggers: Array = _triggers.get(trigger_id, [])
	for activator: BaseActivator in triggers:
		activator.deactivate()

func reset_all_sequences() -> void:
	for sequence: TriggerSequence in _sequences:
		sequence.reset_sequence()

func get_sequence_progress(sequence_name: String) -> float:
	for sequence: TriggerSequence in _sequences:
		if sequence.name == sequence_name:
			return sequence.get_progress()
	return 0.0
