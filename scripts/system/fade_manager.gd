extends Node

## Глобальный менеджер затемнения экрана.
## Используется для плавных переходов между сценами и эффектов.
## Автозагружается как FadeManager.

## Префикс для логирования
const LOG_PREFIX: StringName = &"[FadeManager] "

## Цвет фона по умолчанию
@export var default_color: Color = Color.BLACK

## Длительность эффекта по умолчанию в секундах
@export var default_duration: float = 0.25

## Текущий слой затемнения
var _current_layer: CanvasLayer = null

## Текущий прямоугольник затемнения
var _current_rect: ColorRect = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен\n", 
	[]
	)


## Затемняет экран до полной непрозрачности.
## [param duration] — длительность эффекта в секундах
func fade_out(duration: float = default_duration) -> void:
	await _create_fade(1.0, duration)


## Плавно убирает затемнение.
## [param duration] — длительность эффекта в секундах
func fade_in(duration: float = default_duration) -> void:
	await _create_fade(0.0, duration)


## Комбинированный эффект: затемнение, выполнение команды, появление.
## [param out_duration] — длительность затемнения
## [param in_duration] — длительность появления
## [param delay] — задержка между эффектами
## [param command] — функция для выполнения во время затемнения
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


## Создаёт и анимирует слой затемнения.
## [param target_alpha] — целевая прозрачность (0.0 - 1.0)
## [param duration] — длительность анимации
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
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_current_rect, "modulate:a", target_alpha, duration)
		await tween.finished
	else:
		_current_rect.modulate.a = target_alpha
	
	# Удаляем слой при полном исчезновении
	if target_alpha == 0.0:
		_current_layer.queue_free()
		_current_layer = null
		_current_rect = null
