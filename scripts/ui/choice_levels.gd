extends Control

## Меню выбора уровня с динамической загрузкой уровней.

class_name ChoiceLevels

## Префикс для логирования
const LOG_PREFIX: StringName = &"[ChoiceLevels] "

## Шаблон кнопки для создания элементов уровня
@export var button_reference: Button = null

## Цвет разблокированного уровня
@export var unlocked_color: Color = Color(0.3, 0.7, 0.3)

## Цвет заблокированного уровня
@export var locked_color: Color = Color(0.5, 0.5, 0.5)

## Цвет пройденного уровня
@export var completed_color: Color = Color(0.2, 0.5, 0.8)

## Сетка-контейнер для размещения кнопок уровней
@export var grid_container: GridContainer


func _ready() -> void:
	create_level_list()


## Возвращает пользователя в главное меню.
func _on_back_pressed() -> void:
	GameManager.to_main_menu()


## Создаёт список кнопок уровней на основе данных из GameManager.
func create_level_list() -> void:
	GameManager.debug(self.LOG_PREFIX\
	+ "Создание списка уровней\n", 
	[]
	)
	
	var last_create_button: Button = null
	
	for level_idx: int in range(1, GameManager.levels.size() + 1):
		var level_scene: PackedScene = GameManager.get_level_by_index(level_idx)
		var level_uid: StringName = level_scene.instantiate().level_uid
		var is_unlocked: bool = SaveManager.is_level_unlocked(level_uid)
		var is_completed: bool = SaveManager.is_level_completed(level_uid)
		
		GameManager.debug(self.LOG_PREFIX\
		+ "Создание уровня {}. Пройден: {}. Разблокирован: {}\n", 
		[level_uid, is_completed, is_unlocked]
		)
		
		last_create_button = button_reference.duplicate() as Button
		
		if is_completed:
			last_create_button.modulate = completed_color
			if last_create_button.has_node("Lock"):
				last_create_button.get_node("Lock").hide()
		elif is_unlocked:
			last_create_button.modulate = unlocked_color
			last_create_button.disabled = false
			if last_create_button.has_node("Lock"):
				last_create_button.get_node("Lock").hide()
		else:
			last_create_button.modulate = locked_color
			last_create_button.disabled = true
			if last_create_button.has_node("Lock"):
				last_create_button.get_node("Lock").show()
		
		last_create_button.text = str(level_idx)
		
		if is_unlocked:
			last_create_button.button_down.connect(GameManager.open_level.bind(level_uid))
		
		grid_container.add_child(last_create_button)
	
	if GameManager.levels.is_empty():
		GameManager.debug(self.LOG_PREFIX\
		+ "Уровни не найдены или не настроены\n", 
		[]
		)
		var label: Label = Label.new()
		label.text = "Уровни не найдены или не настроены"
		grid_container.add_child(label)
