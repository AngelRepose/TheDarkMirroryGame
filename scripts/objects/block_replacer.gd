extends ActivatableObject

## Заменяет одни тайлы на другие при активации.

class_name BlockReplacer

## Целевой слой тайлов
@export var target_layer: TileMapLayer = null

## Координаты тайлов для замены
@export var tile_positions: Array[Vector2i] = []

## ID тайла для замены
@export var target_tile_id: int = 0

## Координаты атласа целевого тайла
@export var target_atlas_coords: Vector2i = Vector2i(0, 0)

## Восстанавливать ли тайлы при деактивации
@export var restore_on_deactivate: bool = true

## Сохранённые тайлы
var _saved_tiles: Dictionary = {}


func _ready() -> void:
	LOG_PREFIX = &"[BlockReplacer] "
	GameManager.debug(self.LOG_PREFIX\
	+ "Загружен\n", 
	[]
	)
	

## Активирует замену тайлов.
## [param _activator] — активировавший объект
func _activate(_activator: BaseActivator) -> void:
	if not target_layer:
		push_warning(LOG_PREFIX + "target_layer не установлен")
		return
	
	GameManager.debug(self.LOG_PREFIX\
	+ "Замена тайлов: {} позиций\n", 
	[tile_positions.size()]
	)

	_saved_tiles.clear()
	
	for pos: Vector2i in tile_positions:
		# Сохраняем текущий тайл
		var current_data: TileData = target_layer.get_cell_tile_data(pos)
		if current_data:
			_saved_tiles[pos] = {
				"tile_id": target_layer.get_cell_source_id(pos),
				"atlas": target_layer.get_cell_atlas_coords(pos),
				"alternative": target_layer.get_cell_alternative_tile(pos)
			}
		
		# Устанавливаем новый тайл
		if target_tile_id >= 0:
			target_layer.set_cell(pos, target_tile_id, target_atlas_coords)


## Деактивирует замену тайлов.
## [param _activator] — деактивировавший объект
func _deactivate(_activator: BaseActivator) -> void:
	if not restore_on_deactivate or not target_layer:
		return
	
	GameManager.debug(self.LOG_PREFIX\
	+ "Восстановление тайлов: {} позиций\n", 
	[_saved_tiles.size()]
	)

	# Восстанавливаем тайлы
	for pos: Vector2i in _saved_tiles:
		var data: Dictionary = _saved_tiles[pos]
		target_layer.set_cell(pos, data.tile_id, data.atlas, data.alternative)
	
	# Удаляем несохранённые
	for pos: Vector2i in tile_positions:
		if pos not in _saved_tiles:
			target_layer.erase_cell(pos)
