extends BaseActivator
## Рычаг с двумя режимами работы: переключаемый и моментальный
class_name Lever

## Типы рычага: TOGGLE — сохраняет состояние, MOMENTARY — активен пока игрок в зоне
enum LeverType {TOGGLE, MOMENTARY}

@export_group("Settings")
## Тип рычага
@export var type: LeverType = LeverType.TOGGLE

## Задержка перед повторным взаимодействием (в секундах)
@export var cooldown: float = 0.2

## Текст подсказки
@export var hint_text: String = "[E] Interact "

## Настройки метки подсказки
@export var label_settings: LabelSettings

## Измерение, в котором работает рычаг (-1 = любое)
@export var dimension: int = -1

## Анимированный спрайт рычага
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

## Компонент всплывающей подсказки
@onready var interaction_component: PopupHint = $PopupHint

## Можно ли взаимодействовать с рычагом
var can_interact: bool = true

## Ссылка на уровень
var _level: BaseLevel

func _ready() -> void:
	super._ready()
	interaction_component.label_settings = label_settings
	interaction_component.set_text(hint_text)
	interaction_component.player_exited.connect(_on_player_exited)
	_level = _find_level()
	_update_visuals()

func _on_player_exited() -> void:
	if type == LeverType.MOMENTARY:
		deactivate()

func _unhandled_input(event: InputEvent) -> void:
	if interaction_component.player_in_zone and can_interact:
		if event.is_action_pressed("interact"):
			_interact()

func _interact() -> void:
	if not _is_in_correct_dimension():
		return
	
	match type:
		LeverType.TOGGLE:
			toggle()
		LeverType.MOMENTARY:
			activate()
	
	_start_cooldown()

func _is_in_correct_dimension() -> bool:
	if dimension < 0 or not _level:
		return true
	return _level.current_dimension == dimension

func _update_visuals() -> void:
	if anim:
		anim.play("on" if is_active else "off")

func _start_cooldown() -> void:
	can_interact = false
	await get_tree().create_timer(cooldown).timeout
	can_interact = true

func _find_level() -> BaseLevel:
	var node := get_parent()
	while node:
		if node is BaseLevel:
			return node
		node = node.get_parent()
	return null
