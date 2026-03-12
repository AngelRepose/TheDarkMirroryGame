extends TileMapLayer
class_name BaseDimension

@export var uid: StringName
@export var background: TileMapLayer
@export var default_enabled: bool = true

func _ready() -> void:
	self.enabled = default_enabled

func toggle() -> void:
	self.enabled = !self.enabled
	self.background.enabled = !self.background.enabled
	self.visible = !self.visible
	self.background.visible = !self.background.visible

func disable() -> void:
	self.enabled = false
	self.background.enabled = false
	self.visible = false
	self.background.visible = false
	
func enable() -> void:
	self.enabled = true
	self.background.enabled = true
	self.visible = true
	self.background.visible = true
