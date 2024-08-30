extends Enemy

@onready var ray_cast_front = $RayCastFront
@onready var ray_cast_below = $RayCastBelow

@export var max_distance = 300
var distance_travelled = 0

func _ready():
	direction = Vector2.RIGHT
	super._ready()
	
	#physics stats
	set_max_horizontal_speed(100)
	set_max_vertical_speed(500)
	set_friction(100)
	set_air_resistance(500)
	set_jump_accel(Constants.GRAVITY + 500 * 60)

	#enemy stats
	set_max_health(500)
	set_accel(200)
	set_attack_power(15)
	set_knock_power(1000)
	set_invuln_time(2)
	set_stun_time(1)
	
	#set timers
	invuln_timer.wait_time = get_invuln_time()
	hitstun_timer.wait_time = get_stun_time()

	fill_health()

func _physics_process(delta):
	
	if not attacking and not stunned:
		if (ray_cast_front.is_colliding() or not ray_cast_below.is_colliding()) or distance_travelled >= max_distance:
			face_direction(direction.x * -1)
			direction.x *= -1
			distance_travelled = 0
		move(direction, get_accel() * get_accel_mult(), delta) 
		distance_travelled += abs(velocity.x) * delta
	apply_friction(delta)
	apply_gravity(delta)
	move_and_slide()
