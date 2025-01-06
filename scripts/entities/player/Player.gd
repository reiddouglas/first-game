extends Entity

#Signals
signal gold_changed

#Unique Player attributes
var gold: int: set = set_gold, get = get_gold
var wall_jump_accel: int: set = set_wall_jump_accel, get = get_wall_jump_accel
var on_wall = false
var rolling = false

#Setters and Getters
func set_gold(new_gold: int):
	gold = max(new_gold,0)
	gold_changed.emit()

func get_gold():
	return gold

func set_wall_jump_accel(new_accel: int):
	wall_jump_accel = new_accel

func get_wall_jump_accel():
	return wall_jump_accel

#Ready functions


func _ready():
	super._ready()
	
	animation_tree.animation_finished.connect(_on_animation_finished)
	animation_tree.active = true
	
	#physics stats
	set_gravity_mult(2)
	set_max_horizontal_speed(300)
	set_max_vertical_speed(700)
	set_friction(400)
	set_air_resistance(300)
	set_jump_accel(Constants.GRAVITY * get_gravity_mult() + 800 * 60)
	set_wall_jump_accel(Constants.GRAVITY * get_gravity_mult() + 1000 * 60)
	
	#player stats
	set_max_health(100)
	set_health(100)
	set_accel(1000)
	set_attack_power(50)
	set_knock_power(1000)
	set_invuln_time(2.5)
	set_stun_time(1.0)
	set_gold(0)
	
	#set timers
	invuln_timer.wait_time = get_invuln_time()
	hitstun_timer.wait_time = get_stun_time()

func start(pos):
	position = pos

#Player physics

#60 times a second
func _physics_process(delta):
	if stunned == false and attacking == false and rolling == false:
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
	apply_friction(delta)
	move_and_slide()


func get_input_axis():
	var input_axis = Vector2.ZERO
	input_axis.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	input_axis.y = int(Input.is_action_just_pressed("move_down")) - int(Input.is_action_just_pressed("jump"))
	return input_axis.normalized()

func move_ground(delta):
	animation_tree.set("parameters/in_air_state/transition_request","ground")
	#rolling
	if rolling == false:
		if direction.y > 0:
			animation_tree.set("parameters/on_ground_movement/transition_request","rolling")
			rolling = true
			velocity.x = sign(direction.x) * get_max_vertical_speed()
		#sliding
		elif (direction.x == 0 or sign(direction.x) != sign(velocity.x)) and velocity.x != 0:
			animation_tree.set("parameters/on_ground_movement/transition_request","turning")
		#idling
		elif direction.x == 0 and velocity.x == 0:
			animation_tree.set("parameters/on_ground_movement/transition_request","idling")
		#running
		else:
			animation_tree.set("parameters/on_ground_movement/transition_request","running")
			animation_tree.set("parameters/movement_time/scale",abs(get_velocity().x) * 2/get_max_horizontal_speed())
			move(direction * Vector2.RIGHT, get_accel() * get_accel_mult(), delta)
		#jumping
		if direction.y < 0 and is_on_floor():
			jump(delta)
	face_direction(sign(velocity.x))
	
func move_air(delta):
	rolling = false
	animation_tree.set("parameters/in_air_state/transition_request","air")
	if is_on_wall():
		#need to get player to "stick" to the wall, otherwise is_on_wall will return false
		if (direction.x == 0 or sign(direction.x) != sign(get_wall_normal().x)) and direction.y >= 0:
			move(-get_wall_normal() * Vector2.RIGHT, get_accel() * get_accel_mult(), delta)
		#add sliding down wall logic here
		wall_slide(delta)
		face_direction(get_wall_normal().x)
		animation_tree.set("parameters/in_air_movement/transition_request","wall_sliding")
		
		if direction.y < 0:
			wall_jump(delta)
	else:
		move(direction * Vector2.RIGHT, get_accel() * get_accel_mult(), delta)
		#applying the "fast_fall" movement
		if direction.y > 0:
			fast_fall(delta)
		# falling animation
		if velocity.y > 0:
			animation_tree.set("parameters/in_air_movement/transition_request","falling")
		# jumping animation
		else:
			animation_tree.set("parameters/in_air_movement/transition_request","jumping")
		face_direction(sign(velocity.x))
		apply_gravity(delta)

func fast_fall(delta):
	move(Vector2.DOWN, get_jump_accel(), delta)

func wall_jump(delta):
	move(Vector2(get_wall_normal().x,-1), get_wall_jump_accel(), delta)

func wall_slide(delta):
	velocity.y = max(velocity.y, 0)
	move(Vector2.DOWN, Constants.GRAVITY * get_gravity_mult() * 0.2, delta)

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
	elif anim_name.contains("roll"):
		rolling = false

func _on_hurt_box_area_entered(hitbox: Area2D):
	if hitbox.get_parent().is_in_group("Gold"):
		set_gold(get_gold() + 1)
	else:
		super._on_hurt_box_area_entered(hitbox)
