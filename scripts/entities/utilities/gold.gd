extends Node2D

@onready var hit_box = $Area2D

signal gold_collected

# Called when the node enters the scene tree for the first time.
func _ready():
	#Attach signal function for entering coin body
	hit_box.area_entered.connect(_on_hit_box_area_entered)
	
func _on_hit_box_area_entered(area: Area2D):
	gold_collected.emit()
	queue_free()
