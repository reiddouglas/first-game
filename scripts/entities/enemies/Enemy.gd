extends Entity

class_name Enemy

@onready var detection_box = $DetectionBox
@onready var attack_box = $AttackBox
@onready var attack_timer = $AttackBox/AttackTimer

func _ready():
	super._ready()
		
	#triggers
	attack_box.area_entered.connect(_on_attack_box_area_entered)
	animation_tree.animation_finished.connect(_on_animation_finished)
	attack_timer.timeout.connect(_on_attack_timer_timeout)

func _on_animation_finished(anim_name: StringName):
	print(name + " has finished animation \'" + anim_name + "\'")
	if anim_name.contains("attack"):
		attacking = false
		#disable attack for a few seconds after an attack finishes
		_attack_enabled(false)
		attack_timer.start()

func _on_attack_timer_timeout():
	#Enable all CollisionShape2D nodes in AttackBox
	_attack_enabled(true)
	
func _on_attack_box_area_entered(_hitbox: Area2D):
	print(name + " triggers an attack.")
	_attack()

func _attack():
	attacking = true

func _attack_enabled(input: bool):
	for child in attack_box.get_children():
		if child.is_class("CollisionShape2D"):
				child.disabled = !input
