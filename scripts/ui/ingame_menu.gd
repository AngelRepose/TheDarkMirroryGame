extends CanvasLayer

@onready var main_menu: PackedScene = preload("res://scenes/ui/menu.tscn")
@onready var level: BaseLevel = get_parent()

func _ready() -> void:
	hide()
var can_resume: bool = false

func _process(delta: float) -> void:
	if can_resume && Input.is_action_just_pressed("ui_cancel"):
		resume()
	elif !can_resume && Input.is_action_just_released("ui_cancel"):
		can_resume = true

func resume() -> void:
	hide()
	level._is_paused = false
	get_tree().paused = false

func pause() -> void:
	show()
	can_resume = false
	level._is_paused = true
	get_tree().paused = true

func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	resume()
	level._reload_scene()

func _on_exit_pressed() -> void:
	#todo save
	resume()
	get_tree().change_scene_to_packed(main_menu)
