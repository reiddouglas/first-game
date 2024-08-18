extends Entity

#Signals
signal gold_changed

#Unique Player attributes
var gold: int: set = set_gold, get = get_gold

#Setters and Getters
func set_gold(new_gold: int):
	gold = max(new_gold,0)

func get_gold():
	return gold

#Ready functions


func _ready():
	super._ready()
	
	animation_tree.animation_finished.connect(_on_animation_finished)
	animation_tree.active = true
	
	#physics stats
	set_max_horizontal_velocity(250)
	set_max_vertical_velocity(500)
	set_friction(1000)
	set_air_resistance(500)
	set_jump_acceleration(Constants.GRAVITY + 500 * 60)
	
	#player stats
	set_max_health(PlayerData.max_health)
	set_health(PlayerData.health)
	set_speed(PlayerData.speed)
	set_attack_power(PlayerData.attack_power)
	set_invuln_time(PlayerData.invuln_time)
	set_stun_time(PlayerData.stun_time)
	set_gold(PlayerData.gold)
	
	#set timers
	invuln_timer.wait_time = get_invuln_time()
	hitstun_timer.wait_time = get_stun_time()

func start(pos):
	position = pos

#Player physics

#60 times a second
func _physics_process(delta):
	
	if stunned == false and attacking == false:
		#Check for player movement input
		direction = get_input_axis()
		if is_on_floor():
			#Check for player attack input
			if Input.is_action_just_pressed("attack"):
				_attack_enabled(true)
	else:
		#reset player movement input
		direction = Vector2.ZERO
	
	if is_on_floor():
		move_ground(delta)
	else:
		move_air(delta)
	if sign(velocity.x) != 0:
		face_direction(sign(velocity.x))


func get_input_axis():
	var input_axis = Vector2.ZERO
	input_axis.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	input_axis.y = int(Input.is_action_just_pressed("move_down")) - int(Input.is_action_just_pressed("jump"))
	return input_axis.normalized()

func move_ground(delta):
	animation_tree.set("parameters/in_air_state/transition_request","ground")
	#sliding
	if (direction.x == 0 or sign(direction.x) != sign(velocity.x)) and velocity.x != 0:
		animation_tree.set("parameters/on_ground_movement/transition_request","turning")
		apply_horizontal_ground_friction(delta)
	#idling
	elif direction.x == 0 and velocity.x == 0:
		animation_tree.set("parameters/on_ground_movement/transition_request","idling")
	#running
	else:
		animation_tree.set("parameters/on_ground_movement/transition_request","running")
		animation_tree.set("parameters/movement_time/scale",abs(velocity.x) * 2/max_horizontal_velocity)
		apply_movement(direction * Vector2.RIGHT, speed, delta)
	
	#jumping
	if direction.y < 0 and is_on_floor():
		apply_jump(delta)
	move_and_slide()
	
func move_air(delta):
	animation_tree.set("parameters/in_air_state/transition_request","air")
	
	#constant gravity causing the player to fall
	apply_gravity(delta)
	
	#air resistance
	if direction == Vector2.ZERO or (sign(direction.x) != sign(velocity.x) and velocity.x != 0):
		apply_horizontal_air_resistance(delta)
	#air acceleration
	else:
		apply_movement(direction * Vector2.RIGHT, speed, delta)
		
	if direction.y > 0:
		apply_fall(delta)
		
	# falling
	if velocity.y > 0:
		animation_tree.set("parameters/in_air_movement/transition_request","falling")
	# jumping (upwards falling)
	else:
		# set the animation here in case character can move upwards without jumping
		animation_tree.set("parameters/in_air_movement/transition_request","jumping")
	move_and_slide()

func face_direction(horizontal_direction):
	scale.x = scale.y * horizontal_direction

func _attack_enabled(input: bool):
	attacking = input
	if input:
		animation_tree.set("parameters/attacking_state/transition_request","attacking")
		velocity = Vector2.ZERO
	else:
		animation_tree.set("parameters/attacking_state/transition_request","not_attacking")

func _on_animation_finished(anim_name: StringName):
	if anim_name.contains("attack"):
		_attack_enabled(false)
