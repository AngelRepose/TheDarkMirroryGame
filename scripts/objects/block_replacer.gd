extends ActivatableObject
## Заменяет одни тайлы на другие при активации
class_name BlockReplacer

## Целевой TileMapLayer для замены
@export var target_layer: TileMapLayer

## Координаты тайлов для замены
@export var tile_positions: Array[Vector2i] = []

## Исходный ID тайла (что заменяем)
@export var source_tile_id: int = -1

## Целевой ID тайла (на что заменяем)
@export var target_tile_id: int = 0

## Атлас для исходного тайла
@export var source_atlas_coords: Vector2i = Vector2i(0, 0)

## Атлас для целевого тайла
@export var target_atlas_coords: Vector2i = Vector2i(0, 0)

## Восстанавливать ли тайлы при деактивации
@export var restore_on_deactivate: bool = true

## Сохранённые тайлы для восстановления
var _saved_tiles: Dictionary = {}

func _activate(_activator: BaseActivator) -> void:
	if not target_layer:
		push_warning("BlockReplacer: target_layer is not set")
		return
	
	_saved_tiles.clear()
	
	for pos in tile_positions:
		# Сохраняем текущий тайл
		var current_data := target_layer.get_cell_tile_data(pos)
		if current_data:
			_saved_tiles[pos] = {
				"tile_id": target_layer.get_cell_source_id(pos),
				"atlas": target_layer.get_cell_atlas_coords(pos),
				"alternative": target_layer.get_cell_alternative_tile(pos)
			}
		
		# Устанавливаем новый тайл
		if target_tile_id >= 0:
			target_layer.set_cell(pos, target_tile_id, target_atlas_coords)

func _deactivate(_activator: BaseActivator) -> void:
	if not restore_on_deactivate or not target_layer:
		return
	
	# Восстанавливаем тайлы
	for pos in _saved_tiles:
		var data: Dictionary = _saved_tiles[pos]
		target_layer.set_cell(pos, data.tile_id, data.atlas, data.alternative)
	
	# Или удаляем, если не было сохранено
	for pos in tile_positions:
		if pos not in _saved_tiles:
			target_layer.erase_cell(pos)
