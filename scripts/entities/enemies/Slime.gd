extends Enemy

func _ready():
	super._ready()
	#physics
	_set_max_horizontal_velocity(1000)
	_set_max_vertical_velocity(1000)
	
	_set_max_health(100)
	_fill_health()
	_set_attack_power(15)
	_set_speed(50)

func _physics_process(delta):
	apply_gravity(delta)
	move_and_slide()
