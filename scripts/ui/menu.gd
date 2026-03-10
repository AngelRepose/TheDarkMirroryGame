extends Control

@onready var play_button: Button = $MarginContainer/VBoxContainer/PlayMargin/PlayContainer/PlayButton
@onready var exit_button: Button = $MarginContainer/VBoxContainer/ExitMargin/ExitContainer/ExitButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/choice_levels.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
