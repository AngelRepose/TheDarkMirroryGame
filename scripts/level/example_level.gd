extends BaseLevel
## Пример уровня с демонстрацией всех механик и объектов
class_name ExampleLevel

## UI с подсказками
@export var tutorial_label: RichTextLabel

## Все демонстрационные объекты
@onready var lever_demo: Lever = $Objects/LeverDemo
@onready var plate_demo: Plate = $Objects/PlateDemo
@onready var spike_demo: Spike = $Objects/SpikeDemo
@onready var pushable_demo: PushableObject = $Objects/PushableDemo
@onready var box_spawner_demo: BoxSpawner = $Objects/BoxSpawnerDemo
@onready var teleporter_demo: Teleporter = $Objects/TeleporterDemo
@onready var dimension_blocker_demo: DimensionBlocker = $Objects/DimensionBlockerDemo
@onready var sequence_demo: TriggerSequence = $Objects/SequenceDemo

## Счётчик активаций для демонстрации
var _lever_count: int = 0
var _plate_count: int = 0

func _ready() -> void:
	super._ready()
	_setup_demonstrations()
	_show_tutorial("Добро пожаловать в Example Level!\n\nНажмите [Q] для смены измерения\nНажмите [E] для взаимодействия")

func _setup_demonstrations() -> void:
	# Рычаг — открывает дверь
	if lever_demo:
		lever_demo.trigger_id = "demo_lever"
		lever_demo.toggled.connect(_on_lever_toggled)
	
	# Плита — активируется при нажатии
	if plate_demo:
		plate_demo.trigger_id = "demo_plate"
		plate_demo.activated.connect(_on_plate_activated)
		plate_demo.deactivated.connect(_on_plate_deactivated)
	
	# Последовательность плит
	if sequence_demo:
		sequence_demo.sequence_completed.connect(_on_sequence_completed)
		sequence_demo.sequence_failed.connect(_on_sequence_failed)

func _on_lever_toggled(is_active: bool) -> void:
	_lever_count += 1
	_show_tutorial("Рычаг %s!\nАктиваций: %d" % ["включён" if is_active else "выключен", _lever_count])

func _on_plate_activated(_activator: BaseActivator) -> void:
	_plate_count += 1
	_show_tutorial("Плита нажата!\nНажатий: %d" % _plate_count)

func _on_plate_deactivated(_activator: BaseActivator) -> void:
	_show_tutorial("Плита освобождена!")

func _on_sequence_completed() -> void:
	_show_tutorial("Последовательность выполнена!\nСекрет открыт!")

func _on_sequence_failed() -> void:
	_show_tutorial("Неверный порядок!\nПопробуйте снова.")

func _show_tutorial(text: String) -> void:
	if tutorial_label:
		tutorial_label.text = text

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("swap_dimension"):
		swap_dimension()
