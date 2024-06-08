extends Area2D

@onready var timer = $Timer

func _on_body_entered(body):
	timer.start()
	print("You Win!")
	#add level end animation and such


func _on_timer_timeout():
	get_tree().reload_current_scene()
