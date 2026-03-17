extends Control

## Анимированное сердце для отображения здоровья в HUD.

class_name Heart

## Префикс для логирования
const LOG_PREFIX: StringName = &"[Heart] "

## Спрайтфреймы для 1 измерения (нормальное измерение)
@export var frames1: SpriteFrames = null

## Спрайтфреймы для 2 измерения (альтернативное измерение)
@export var frames2: SpriteFrames = null

## Анимированный спрайт для отображения сердец
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D as AnimatedSprite2D

## Текущее состояние сердца
var _current_state: StringName = &"full"

## Флаг инициализации
var _initialized: bool = false


func _ready() -> void:
	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен\n", 
	[]
	)


## Устанавливает измерение для сердца.
## [param dimension] — измерение (0 или 1)
func set_dimension(dimension: BaseLevel.Dimension) -> void:
	var target_frames: SpriteFrames = frames2 if dimension == 1 else frames1
	
	if _sprite.sprite_frames == target_frames:
		return
		
	_sprite.sprite_frames = target_frames
	_play_current()


## Показывает полное сердце (состояние "full").
func show_full() -> void:
	_current_state = &"full"
	_play_current()


## Показывает пустое сердце (состояние "empty").
func show_empty() -> void:
	_current_state = &"empty"
	_play_current()


## Воспроизводит анимацию добавления сердца.
func play_add() -> void:
	if _current_state == &"full" or _current_state == &"add":
		return
		
	_current_state = &"add"
	_play_current()
	
	if not _sprite.animation_finished.is_connected(_on_animation_finished):
		_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


## Воспроизводит анимацию потери сердца.
func play_lose() -> void:
	_current_state = &"lose"
	_play_current()
	
	if not _sprite.animation_finished.is_connected(_on_animation_finished):
		_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


## Обрабатывает завершение анимации add или lose.
func _on_animation_finished() -> void:
	match _current_state:
		&"add":
			show_full()
		&"lose":
			show_empty()


## Воспроизводит текущую анимацию в зависимости от _current_state.
func _play_current() -> void:
	if not _sprite or not _sprite.sprite_frames:
		return
		
	if not _sprite.sprite_frames.has_animation(_current_state):
		push_warning(LOG_PREFIX + "Анимация %s не найдена" % _current_state)
		return
		
	_sprite.play(_current_state)
