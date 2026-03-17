extends Node

## Менеджер сохранений игры.
## Хранит только прогресс прохождения и разблокировки уровней.
## Автозагружается как SaveManager.
## Вызывается при завершении уровня
signal level_completed(level_uid: StringName)

## Вызывается при разблокировке уровня
signal level_unlocked(level_uid: StringName)

## Префикс для логирования
const LOG_PREFIX: StringName = &"[SaveManager] "

## Название директории сохранений
const SAVE_DIR_NAME: String = "TheDarkMirrory"

## Имя файла сохранения
const SAVE_FILE_NAME: String = "save.dat"

## Магическое число для валидации файла
const MAGIC_NUMBER: int = 0x54444D53

## Версия формата сохранения
const SAVE_VERSION: int = 2

## Интервал автосохранения в секундах
const AUTO_SAVE_INTERVAL: float = 300.0

## Максимальное количество уровней
const MAX_LEVELS: int = 10

## Путь к локальным файлам уровней
const LOCAL_LEVELS_PATH: StringName = &"res://scenes/levels/level_"

## Данные сохранения одного уровня (только статус)
class LevelSaveData:
	## Пройден ли уровень
	var completed: bool = false

	## Разблокирован ли уровень
	var unlocked: bool = false
	
	## Инициализирует данные уровня.
	## [param p_unlocked] — начальный статус разблокировки
	func _init(p_unlocked: bool = false) -> void:
		unlocked = p_unlocked

## UID текущего уровня
var current_level_uid: StringName = &"level_1"

## Словарь данных сохранения: StringName -> LevelSaveData
var _save_data: Dictionary = {}

## Путь к файлу сохранения
var _save_path: String = ""

## Флаг ожидающего сохранения
var _save_pending: bool = false

## Мьютекс для потокобезопасности
var _mutex: Mutex = null

## Таймер автосохранения
var _auto_save_timer: Timer = null

## Маппинг путей сцен к UID
var _scene_to_uid: Dictionary = {}

## Упорядоченный список UID уровней
var _level_order: Array[StringName] = []


func _ready() -> void:
	_setup_save_path()
	_setup_auto_save()
	_mutex = Mutex.new()
	_setup_scene_mapping()
	_initialize_levels()
	
	if not load_game():
		GameManager.debug(self.LOG_PREFIX\
		+ "Создаём новый файл сохранения\n", 
		[])
		save_game()
	load_game()
	GameManager.debug(self.LOG_PREFIX\
	+ "Успешно запущен\n", 
	[])


## Устанавливает путь к файлу сохранения.
func _setup_save_path() -> void:
	var documents_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	_save_path = documents_path.path_join(SAVE_DIR_NAME).path_join(SAVE_FILE_NAME)
	GameManager.debug(self.LOG_PREFIX\
	+ "Установлен путь сохранений: {}\n", 
	[_save_path]
	)


## Настраивает таймер автосохранения.
func _setup_auto_save() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_save_timer.timeout.connect(_on_auto_save_timeout)
	_auto_save_timer.autostart = true
	add_child(_auto_save_timer)
	GameManager.debug(self.LOG_PREFIX\
	+ "Установлено авто-сохранение с интервалом: {} сек.\n", 
	[AUTO_SAVE_INTERVAL]
	)


## Создаёт маппинг путей сцен к UID уровней.
func _setup_scene_mapping() -> void:
	GameManager.debug(self.LOG_PREFIX\
	+ "Установлен маппинг айди-путь\n", 
	[]
	)
	for i: int in range(1, MAX_LEVELS + 1):
		var index: String = str(i)
		var _uid: StringName = StringName("level_" + index)
		var _path: StringName = StringName(LOCAL_LEVELS_PATH + index)
		_scene_to_uid[_path] = _uid
		_level_order.append(_uid)
	


## Инициализирует данные уровней по умолчанию.
func _initialize_levels() -> void:
	for i: int in range(_level_order.size()):
		var level_uid: StringName = _level_order[i]
		var is_first: bool = (i == 0)
		
		if not _save_data.has(level_uid):
			_save_data[level_uid] = LevelSaveData.new(is_first)
		elif is_first:
			_save_data[level_uid].unlocked = true


## Загружает сохранение из файла.
## Возвращает true при успешной загрузке.
func load_game() -> bool:
	var file: FileAccess = FileAccess.open(_save_path, FileAccess.READ)
	if not file:
		return false
	
	var magic: int = file.get_32()
	if magic != MAGIC_NUMBER:
		return false
	
	var _version: int = file.get_32()

	_mutex.lock()
	_save_data.clear()
	
	var count: int = file.get_32()
	for _i: int in range(count):
		var level_uid: StringName = StringName(file.get_pascal_string())
		var data: LevelSaveData = LevelSaveData.new()
		
		data.completed = file.get_8() != 0
		data.unlocked = file.get_8() != 0
		
		_save_data[level_uid] = data
	
	_mutex.unlock()
	return true


## Сохраняет прогресс в файл.
## Возвращает true при успешном сохранении.
func save_game() -> bool:
	if _save_pending:
		return false
	_save_pending = true
	
	_mutex.lock()
	var data_copy: Dictionary = {}
	for key: StringName in _save_data:
		var original: LevelSaveData = _save_data[key]
		var copy: LevelSaveData = LevelSaveData.new()
		copy.completed = original.completed
		copy.unlocked = original.unlocked
		data_copy[key] = copy
	_mutex.unlock()
	
	var result: bool = _save_to_file(data_copy)
	_save_pending = false
	return result


## Записывает данные в файл.
## [param data] — словарь данных для сохранения
## Возвращает true при успешной записи.
func _save_to_file(data: Dictionary) -> bool:
	var dir_path: String = _save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	
	var file: FileAccess = FileAccess.open(_save_path, FileAccess.WRITE)
	if not file:
		return false

	file.store_32(MAGIC_NUMBER)
	file.store_32(SAVE_VERSION)
	file.store_32(data.size())
	
	for level_uid: StringName in data:
		var level_data: LevelSaveData = data[level_uid]
		file.store_pascal_string(String(level_uid))
		file.store_8(1 if level_data.completed else 0)
		file.store_8(1 if level_data.unlocked else 0)
	
	return true


## Вызывается по таймеру автосохранения.
func _on_auto_save_timeout() -> void:
	save_game()


## Отмечает уровень как пройденный и разблокирует следующий.
## [param level_uid] — уникальный идентификатор уровня
func complete_level(level_uid: StringName) -> void:
	_mutex.lock()
	if not _save_data.has(level_uid):
		_save_data[level_uid] = LevelSaveData.new()
	
	_save_data[level_uid].completed = true
	
	var next_level: StringName = get_next_level(level_uid)
	if next_level != &"":
		if not _save_data.has(next_level):
			_save_data[next_level] = LevelSaveData.new()
		if not _save_data[next_level].unlocked:
			_save_data[next_level].unlocked = true
			level_unlocked.emit(next_level)
	_mutex.unlock()
	
	level_completed.emit(level_uid)
	save_game()


## Возвращает UID следующего уровня.
## [param level_uid] — текущий уровень
## Возвращает пустую строку, если уровень последний.
func get_next_level(level_uid: StringName) -> StringName:
	var idx: int = _level_order.find(level_uid)
	if idx >= 0 and idx < _level_order.size() - 1:
		return _level_order[idx + 1]
	return &""


## Проверяет, разблокирован ли уровень.
## [param level_uid] — уникальный идентификатор уровня
func is_level_unlocked(level_uid: StringName) -> bool:
	GameManager.debug(self.LOG_PREFIX\
	+ "Проверка разблокировки {}: {}\n", 
	[level_uid, _save_data.has(level_uid) and _save_data[level_uid].unlocked]
	)
	return _save_data.has(level_uid) and _save_data[level_uid].unlocked


## Проверяет, пройден ли уровень.
## [param level_uid] — уникальный идентификатор уровня
func is_level_completed(level_uid: StringName) -> bool:
	return _save_data.has(level_uid) and _save_data[level_uid].completed


## Сбрасывает весь прогресс.
func reset_all_progress() -> void:
	_mutex.lock()
	_save_data.clear()
	_mutex.unlock()
	_initialize_levels()
	save_game()


## Возвращает UID уровня по пути к сцене.
## [param scene_path] — путь к файлу сцены
func get_level_uid_by_path(scene_path: String) -> StringName:
	if _scene_to_uid.has(scene_path):
		return _scene_to_uid[scene_path]
	return StringName(scene_path.get_file().get_basename().to_lower())


## Устанавливает текущий уровень.
## [param level_uid] — уникальный идентификатор уровня
func set_current_level(level_uid: StringName) -> void:
	GameManager.debug(self.LOG_PREFIX\
	+ "Установлен текущий уровень: {}\n", 
	[level_uid]
	)
	current_level_uid = level_uid


## Возвращает список всех UID уровней.
func get_all_levels() -> Array[StringName]:
	return _level_order.duplicate()
