extends Entity

#Signals
signal gold_changed

#Unique Player attributes
var gold: int: set = _set_gold, get = _get_gold

#Setters and Getters
func _set_gold(new_gold: int):
	gold = max(new_gold,0)

func _get_gold():
	return gold

#Ready functions
@onready var animation_tree = $AnimationTree
@onready var sprite = $AnimatedSprite2D
@onready var direction = Vector2.ZERO

func _ready():
	super._ready()
	
	animation_tree.active = true
	floor_snap_length = 5.0 #prevent character from bouncing down slopes
	
	#physics stats
	_set_max_horizontal_velocity(250)
	_set_max_vertical_velocity(500)
	_set_friction(1000)
	_set_air_resistance(500)
	_set_jump_acceleration(Constants.GRAVITY + 500 * 60)
	
	#player stats
	_set_max_health(PlayerData.max_health)
	_set_health(PlayerData.health)
	_set_speed(PlayerData.speed)
	_set_attack_power(PlayerData.attack_power)
	_set_gold(PlayerData.gold)
	
	print(health, max_health, gold)

func start(pos):
	position = pos

#Player physics

#60 times a second
func _physics_process(delta):
	get_input_axis()
	
	if is_on_floor():
		move_ground(delta)
	else:
		move_air(delta)
		
	if sign(velocity.x) != 0:
		switch_direction(sign(velocity.x))


func get_input_axis():
	direction.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	direction.y = int(Input.is_action_just_pressed("move_down")) - int(Input.is_action_just_pressed("jump"))
	direction.normalized()

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

func switch_direction(horizontal_direction):
	sprite.flip_h = (horizontal_direction == -1)
	sprite.position.x = horizontal_direction * 4
