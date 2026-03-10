extends Control
## Анимированное сердце для отображения здоровья в HUD
class_name Heart

## Спрайтфреймы для 1 измерения
@export var frames1: SpriteFrames

## Спрайтфреймы для 2 измерения
@export var frames2: SpriteFrames

## Анимированный спрайт сердца
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

## Текущее состояние анимации
var _current_state: StringName = &"full"

func set_dimension(dimension: BaseLevel.Dimension) -> void:
	var target_frames: SpriteFrames = frames2 if dimension == BaseLevel.Dimension.DIM2 else frames1
	if _sprite.sprite_frames == target_frames:
		return
	_sprite.sprite_frames = target_frames
	_play_current()

func show_full() -> void:
	_current_state = &"full"
	_play_current()

func show_empty() -> void:
	_current_state = &"empty"
	_play_current()

func play_add() -> void:
	if _current_state == &"full" or _current_state == &"add":
		return
	_current_state = &"add"
	_play_current()
	if not _sprite.animation_finished.is_connected(_on_animation_finished):
		_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)

func play_lose() -> void:
	_current_state = &"lose"
	_play_current()
	if not _sprite.animation_finished.is_connected(_on_animation_finished):
		_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)

func _on_animation_finished() -> void:
	match _current_state:
		&"add":
			show_full()
		&"lose":
			show_empty()

func _play_current() -> void:
	if not _sprite or not _sprite.sprite_frames:
		return
	if not _sprite.sprite_frames.has_animation(_current_state):
		push_warning("Animation %s not found in SpriteFrames" % _current_state)
		return
	_sprite.play(_current_state)
