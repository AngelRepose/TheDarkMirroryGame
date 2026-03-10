extends StaticBody2D
class_name Lever

signal toggled(active: bool)

enum LeverType {TOGGLE, MOMENTARY}

@export_group("Settings")
@export var type: LeverType = LeverType.TOGGLE
@export var is_active: bool = false: set = set_active
@export var cooldown: float = 0.2
@export var hint_text: String = "[E] Interact "
@export var label_settings: LabelSettings

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_component: PopupHint = $PopupHint

var can_interact: bool = true

func _ready() -> void:
	interaction_component.label_settings = label_settings
	interaction_component.set_text(hint_text)
	interaction_component.player_exited.connect(func():
		if type == LeverType.MOMENTARY:
			is_active = false
	)
	_update_visuals()

func _unhandled_input(event: InputEvent) -> void:
	if interaction_component.player_in_zone and can_interact:
		if event.is_action_pressed("interact"):
			_interact()

func _interact() -> void:
	match type:
		LeverType.TOGGLE:
			set_active(!is_active)
		LeverType.MOMENTARY:
			set_active(true)
	
	_start_cooldown()

func set_active(value: bool) -> void:
	if is_active == value: return
	is_active = value
	if is_inside_tree():
		_update_visuals()
		toggled.emit(is_active)

func _update_visuals() -> void:
	anim.play("on" if is_active else "off")

func _start_cooldown() -> void:
	can_interact = false
	await get_tree().create_timer(cooldown).timeout
	can_interact = true
