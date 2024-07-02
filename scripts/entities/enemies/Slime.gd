extends Enemy

func _ready():
	super._ready()
	
	#triggers
	attack_box.area_entered.connect(_on_attack_box_area_entered)
	
	print("signal go")
	
	#physics
	_set_max_horizontal_velocity(1000)
	_set_max_vertical_velocity(1000)
	
	#stats
	_set_max_health(100)
	_fill_health()
	_set_attack_power(15)
	_set_speed(50)
	

func _physics_process(delta):
	
	if not attacking:
		animation_tree.set("parameters/attacking_state/transition_request","not_attacking")
	
	apply_gravity(delta)
	move_and_slide()

func _attack():
	attacking = true
	#set attack in the animation tree
	animation_tree.set("parameters/attacking_state/transition_request","attacking")

func _on_attack_box_area_entered(_hitbox: Area2D):
	print("Trigger")
	_attack()
