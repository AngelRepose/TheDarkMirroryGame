extends Node
## Глобальный менеджер затемнения экрана (Autoload)

## Цвет фона по умолчанию
@export var default_color: Color = Color.BLACK

## Длительность эффекта по умолчанию
@export var default_duration: float = 0.25

## Текущий слой затемнения
var _current_layer: CanvasLayer

## Текущий прямоугольник затемнения
var _current_rect: ColorRect

func fade_out(duration: float = default_duration) -> void:
	await _create_fade(1.0, duration)

func fade_in(duration: float = default_duration) -> void:
	await _create_fade(0.0, duration)

func fade_out_and_in(
	out_duration: float = default_duration,
	in_duration: float = default_duration,
	delay: float = 0.0,
	command: Callable = Callable()
) -> void:
	await fade_out(out_duration)
	
	if command.is_valid():
		await command.call()
	
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	
	await fade_in(in_duration)

func _create_fade(target_alpha: float, duration: float) -> void:
	if not _current_layer:
		_current_layer = CanvasLayer.new()
		_current_layer.layer = 128
		get_tree().root.add_child(_current_layer)
		
		_current_rect = ColorRect.new()
		_current_rect.color = default_color
		_current_rect.anchor_right = 1.0
		_current_rect.anchor_bottom = 1.0
		_current_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		_current_layer.add_child(_current_rect)
	
	if duration > 0.0:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_current_rect, "modulate:a", target_alpha, duration)
		await tween.finished
	else:
		_current_rect.modulate.a = target_alpha
	
	if target_alpha == 0.0:
		_current_layer.queue_free()
		_current_layer = null
		_current_rect = null
