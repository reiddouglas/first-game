extends Enemy

@onready var ray_cast_front = $RayCastFront
@onready var ray_cast_below = $RayCastBelow

@export var max_distance = 300
var distance_travelled = 0

func _ready():
	direction = Vector2.RIGHT
	super._ready()
	
	#physics stats
	set_max_horizontal_velocity(250)
	set_max_vertical_velocity(500)
	set_friction(1000)
	set_air_resistance(500)
	set_jump_acceleration(Constants.GRAVITY + 500 * 60)
	
	#entity stats
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
	
	print(distance_travelled)
	
	if not attacking:
		if (ray_cast_front.is_colliding() or not ray_cast_below.is_colliding()) or distance_travelled >= max_distance:
			scale.x *= -1
			direction.x *= -1
			distance_travelled = 0
		position += direction * speed * delta
		distance_travelled += speed * delta
	
	apply_gravity(delta)
	move_and_slide()
