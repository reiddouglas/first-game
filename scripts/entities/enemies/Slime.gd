extends Enemy

func _ready():
	super._ready()
	
	#physics stats
	set_max_horizontal_velocity(250)
	set_max_vertical_velocity(500)
	set_friction(1000)
	set_air_resistance(500)
	set_jump_acceleration(Constants.GRAVITY + 500 * 60)
	
	#player stats
	set_max_health(200)
	set_speed(50)
	set_attack_power(15)
	set_invuln_time(2)
	set_stun_time(1)
	
	#set timers
	invuln_timer.wait_time = get_invuln_time()
	hitstun_timer.wait_time = get_stun_time()

	fill_health()

func _physics_process(delta):
	
	if not attacking:
		animation_tree.set("parameters/attacking_state/transition_request","not_attacking")
	
	apply_gravity(delta)
	move_and_slide()

func _attack():
	super._attack()
	#set attack in the animation tree
	animation_tree.set("parameters/attacking_state/transition_request","attacking")


