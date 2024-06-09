extends Enemy

func _ready():
	super._ready()
	_set_max_health(100)
	_fill_health()
	_set_attack_power(15)
	_set_speed(50)
