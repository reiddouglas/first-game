extends Entity

class_name Enemy

@onready var detection_box = $DetectionBox

func _ready():
	super._ready()
