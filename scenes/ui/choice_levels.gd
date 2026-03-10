extends Control

@export_category("list of levels")
## индекс - номер уровня, сцена - уровень
@export var loaded_scenes : Array[PackedScene] = []
@export var levels_list_panel : PanelContainer
@export var levels_vbox_container : VBoxContainer
@export var button_reference : Button
@export var level_list_x_size : int = 3

func _ready():
	create_level_list()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")

func create_level_list():
	var now_list_x_size = level_list_x_size
	var last_horisontal_box : HBoxContainer
	var last_create_button : Button
	# для каждой сцены из списка уровней создаем кнопку, размещаем, настраиваем её и привязываем переключение на уровень
	for level_idx in range(loaded_scenes.size()):
		if now_list_x_size == level_list_x_size:
			last_horisontal_box = HBoxContainer.new()
			levels_vbox_container.add_child(last_horisontal_box)
			now_list_x_size = 0
		last_create_button = Button.new()
		# загружаем кпонке тему и размер
		last_create_button.theme = button_reference.theme
		last_create_button.custom_minimum_size = button_reference.custom_minimum_size
		# устанавливаем кнопке текст
		last_create_button.text = str(level_idx+1)
		# покдлючаем к кнопке функцию переключения с замороженным вставленным значением ввиде ссылки на сцену
		last_create_button.button_down.connect(open_level.bind(loaded_scenes[level_idx]))
		last_horisontal_box.add_child(last_create_button)
		now_list_x_size += 1
	if loaded_scenes.size() == 0:
		var label_of_notfoundlevels : Label = Label.new()
		label_of_notfoundlevels.text = "levels is not found or don't set in level list"
		levels_list_panel.add_child(label_of_notfoundlevels)
 
func open_level(level : PackedScene) -> void:
	get_tree().change_scene_to_packed(level)
