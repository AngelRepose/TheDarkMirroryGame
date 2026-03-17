extends CanvasLayer

## HUD для отображения здоровья и текущего измерения игрока.

class_name HUD

## Префикс для логирования
const LOG_PREFIX: StringName = &"[HUD] "

## Ссылка на игрока для отслеживания здоровья
@export var player: Player = null

## Ссылка на уровень для отслеживания измерения
@export var level: BaseLevel = null

## Массив сердец для отображения здоровья
@export var hearts: Array[Heart] = []

## Предыдущее значение здоровья для определения потери
var _last_hp: int = 0


func _ready() -> void:
	_connect_player_and_level()
	_connect_signals()
	_initialize_display()
	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен\n", 
	[]
	)


## Обновляет отображение при изменении измерения.
## [param dimension] — новое измерение (0 или 1)
func _on_dimension_changed(dimension: int) -> void:
	_update_health_dimension(dimension)


## Обновляет отображение при изменении здоровья игрока.
## [param current] — текущее здоровье
## [param max_hp] — максимальное здоровье
func _on_player_health_changed(current: int, max_hp: int) -> void:
	_update_health_display(current, max_hp)
	_last_hp = current


## Находит игрока и уровень, если они не были заданы через экспорт.
func _connect_player_and_level() -> void:
	if not player:
		player = get_parent().get_node("Player") as Player
	
	if not level:
		level = get_parent() as BaseLevel


## Подключает сигналы к игроку и уровню.
func _connect_signals() -> void:
	if player:
		player.health_changed.connect(_on_player_health_changed)
		_last_hp = player.get_current_hp()
	
	if level:
		level.dimension_changed.connect(_on_dimension_changed)


## Инициализирует отображение здоровья при старте.
func _initialize_display() -> void:
	if player:
		_update_health_display(player.get_current_hp(), player.max_hp)
	
	if level:
		_update_health_dimension(level.current_dimension)


## Обновляет отображение здоровья.
## [param current_hp] — текущее количество сердец
## [param _max_hp] — максимальное количество сердец (не используется)
func _update_health_display(current_hp: int, _max_hp: int) -> void:
	for i: int in hearts.size():
		var heart: Heart = hearts[i]

		if heart == null:
			continue

		if i < current_hp:
			heart.show_full()
		else:
			if i < _last_hp:
				heart.play_lose()
			else:
				heart.show_empty()


## Обновляет измерение для всех сердец.
## [param dimension] — новое измерение
func _update_health_dimension(dimension: BaseLevel.Dimension) -> void:
	for heart: Heart in hearts:
		heart.set_dimension(dimension)
