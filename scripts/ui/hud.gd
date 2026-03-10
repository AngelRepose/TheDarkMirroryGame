extends CanvasLayer
## HUD для отображения здоровья и текущего измерения
class_name HUD

## Ссылка на игрока
@export var player: Player

## Ссылка на уровень
@export var level: BaseLevel

## Массив сердец для отображения здоровья
@export var hearts: Array[Heart]

## Предыдущее значение здоровья
var _last_hp: int = 0

func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)
	level.dimension_changed.connect(_on_dimension_changed)
	_last_hp = player.get_current_hp()
	_update_health_display(_last_hp, player.max_hp)
	_update_health_dimension(level.current_dimension)

func _on_dimension_changed(dimension: BaseLevel.Dimension) -> void:
	_update_health_dimension(dimension)

func _on_player_health_changed(current: int, max_hp: int) -> void:
	_update_health_display(current, max_hp)
	_last_hp = current

func _update_health_display(current_hp: int, _max_hp: int) -> void:
	for i: int in hearts.size():
		var heart: Heart = hearts[i]
		if heart == null:
			continue
			
		# Логика: если индекс сердца МЕНЬШЕ текущего здоровья — оно должно быть полным
		# Если индекс БОЛЬШЕ ИЛИ РАВЕН — оно должно быть пустым
		if i < current_hp:
			heart.show_full()
		else:
			# Если сердце БЫЛО полным (i < _last_hp), запускаем анимацию потери
			if i < _last_hp:
				heart.play_lose()
			else:
				heart.show_empty()

func _update_health_dimension(dimension: BaseLevel.Dimension) -> void:
	for heart: Heart in hearts:
		heart.set_dimension(dimension)
