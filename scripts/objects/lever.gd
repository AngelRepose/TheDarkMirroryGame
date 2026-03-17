extends BaseActivator

## Рычаг с двумя режимами работы: переключаемый и моментальный.
## Поддерживает сохранение состояния.

class_name Lever

## Префикс для логирования


## Типы рычага
enum LeverType {TOGGLE, MOMENTARY}

## Тип рычага
@export var type: LeverType = LeverType.TOGGLE

## Задержка перед повторным взаимодействием
@export var cooldown: float = 0.2

## Текст подсказки
@export var hint_text: String = "[F] Использовать"

## Настройки метки
@export var label_settings: LabelSettings = null

## Работать только в определённом измерении
@export var dimension_specific: bool = false

## Измерение для работы
@export var show_in_dimension: int = 0

## Уникальный идентификатор
@export var uid: StringName = &""

## Анимированный спрайт
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D as AnimatedSprite2D

## Компонент подсказки
@onready var interaction_component: PopupHint = $PopupHint as PopupHint

## Можно ли взаимодействовать
var can_interact: bool = true

## Ссылка на уровень
var _level: BaseLevel = null



func _ready() -> void:
	super._ready()
	LOG_PREFIX = &"[Lever] "
	interaction_component.label_settings = label_settings
	interaction_component.set_text(hint_text)
	interaction_component.player_exited.connect(_on_player_exited)
	_level = _find_level()
	
	_update_visuals()
	GameManager.debug(LOG_PREFIX\
	+ "Рычаг {} загружен, состояние: {}\n", 
	[str(self.uid) if self.uid else "без uid", self.is_active]
	)


func _unhandled_input(event: InputEvent) -> void:
	if interaction_component.player_in_zone and can_interact:
		if event.is_action_pressed("interact"):
			_interact()

## Вызывается при выходе игрока из зоны.
func _on_player_exited() -> void:
	if type == LeverType.MOMENTARY:
		deactivate()


## Выполняет взаимодействие с рычагом.
func _interact() -> void:
	if not _is_in_correct_dimension():
		return

	match type:
		LeverType.TOGGLE:
			toggle()
		LeverType.MOMENTARY:
			activate()
	
	GameManager.debug(LOG_PREFIX\
	+ "Рычаг {} активирован, состояние: {}\n", 
	[str(self.uid) if self.uid else "без uid", self.is_active]
	)

	_start_cooldown()


## Проверяет, находится ли рычаг в правильном измерении.
func _is_in_correct_dimension() -> bool:
	if not dimension_specific or not _level:
		return true
	return _level.current_dimension == show_in_dimension


## Обновляет визуальное состояние.
func _update_visuals() -> void:
	if anim:
		anim.play("on" if is_active else "off")


## Запускает задержку перед повторным взаимодействием.
func _start_cooldown() -> void:
	can_interact = false
	if is_inside_tree():
		await get_tree().create_timer(cooldown).timeout
	can_interact = true


## Находит родительский уровень.
## Возвращает найденный уровень или null.
func _find_level() -> BaseLevel:
	var node: Node = get_parent()
	while node:
		if node is BaseLevel:
			return node
		node = node.get_parent()
	return null
