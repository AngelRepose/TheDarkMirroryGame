extends BaseLevel
## Тестовый уровень для проверки механик игры
class_name TestLevel

func _ready() -> void:
	super._ready()
	_update_dimensions()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("swap_dimension"):
		swap_dimension()

func _lever_1(state: bool) -> void:
	if state:
		dimension_2.set_cell(Vector2i(10, 18),1, Vector2i(2, 0))
		dimension_2.set_cell(Vector2i(10, 19),1, Vector2i(2, 0))
	else:
		dimension_2.set_cell(Vector2i(10, 18),1, Vector2i(3, 0))
		dimension_2.set_cell(Vector2i(10, 19),1, Vector2i(3, 0))

func _lever_2(state: bool) -> void:
	if state:
		dimension_1.set_cell(Vector2i(20, 18),1, Vector2i(2, 4))
		dimension_1.set_cell(Vector2i(20, 19),1, Vector2i(2, 4))
	else:
		dimension_1.set_cell(Vector2i(20, 18),1, Vector2i(3, 4))
		dimension_1.set_cell(Vector2i(20, 19),1, Vector2i(3, 4))
