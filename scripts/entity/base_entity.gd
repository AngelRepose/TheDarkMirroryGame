extends CharacterBody2D
## Базовый класс для всех сущностей с здоровьем и анимациями
class_name BaseEntity

## Вызывается при изменении здоровья
signal health_changed(current: int, max_hp: int)

## Вызывается при смерти (текущее здоровье <= 0)
signal died

@export_group("Здоровье")
## Максимальное здоровье сущности
@export var max_hp: int = 2

## Время неуязвимости после получения урона
@export var invuln_time: float = 1.0

## Ссылка на анимированный спрайт
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite as AnimatedSprite2D

## Ссылка на коллизию
@onready var _collision: CollisionShape2D = $Collision as CollisionShape2D

## Порог горизонтальной составляющей нормали для регистрации столкновения
const PUSH_NORMAL_THRESHOLD: float = 0.5

## Гравитация, получаемая из настроек проекта
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

## Текущее здоровье сущности
var _hp: int = 0

## Таймер неуязвимости
var _invuln_timer: float = 0.0

## Флаг смерти сущности
var _is_dead: bool = false

func _ready() -> void:
	add_to_group("Entity")
	_hp = clampi(max_hp, 1, 99)
	health_changed.emit(_hp, max_hp)

func _physics_process(delta: float) -> void:
	_update_invulnerability(delta)
	
	if _is_dead:
		return
	
	_process_movement(delta)
	_update_animation_state()

func _process_movement(_delta: float) -> void:
	pass

func is_invulnerable() -> bool:
	return _invuln_timer > 0.0

func is_dead() -> bool:
	return _is_dead
	
func can_take_damage() -> bool:
	return not (is_invulnerable() or is_dead())

func get_current_hp() -> int:
	return _hp

func kill(skip_anim: bool = true) -> void:
	if _is_dead:
		return
	health_changed.emit(0, max_hp)
	_die(skip_anim)

func damage(amount: int = 1) -> void:
	if _is_dead:
		return
	if _invuln_timer > 0.0:
		return

	_invuln_timer = invuln_time
	_hp = clampi(_hp - max(amount, 0), 0, max_hp)
	health_changed.emit(_hp, max_hp)

	if _hp <= 0:
		_die()

func _update_invulnerability(delta: float) -> void:
	if _invuln_timer > 0.0:
		_invuln_timer = maxf(_invuln_timer - delta, 0.0)
		
		var blink := sin(_invuln_timer * 4.0 * TAU)
		animated_sprite.modulate = Color(1.0, 1.0, 1.0, 0.6 + blink * 0.4)
	else:
		animated_sprite.modulate = Color.WHITE

func _update_animation_state() -> void:
	pass

func _play_animation(anim_name: String) -> void:
	if animated_sprite and animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _die(skip_anim: bool = false) -> void:
	if _is_dead:
		return

	_is_dead = true
	set_physics_process(false)

	if self is CollisionObject2D:
		call_deferred("set_collision_layer", 0)
		call_deferred("set_collision_mask", 0)

	if _collision != null:
		_collision.call_deferred("set_disabled", true)
	if not skip_anim and animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("die"):
		animated_sprite.play("die")
		await animated_sprite.animation_finished

	died.emit()
