extends CharacterBody2D

var MAX_HORIZONTAL_VELOCITY = 250
var MAX_VERTICAL_VELOCITY = 500
var GROUND_ACCELERATION = 500
var AIR_ACCELERATION = 250
var FRICTION = 1000
var AIR_RESISTANCE = 500
var GRAVITY = 1000
var JUMP_ACCELERATION = GRAVITY + 500 * 60 # use suvat calc to determine how high you want the jump

@onready var animation_tree = $AnimationTree
@onready var sprite = $AnimatedSprite2D
@onready var direction = Vector2.ZERO

func _ready():
	animation_tree.active = true
	floor_snap_length = 5.0 #prevent character from bouncing down slopes

func start(pos):
	position = pos

# 60 times a second
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
		animation_tree.set("parameters/movement_time/scale",abs(velocity.x) * 2/MAX_HORIZONTAL_VELOCITY)
		apply_movement(direction * Vector2.RIGHT, GROUND_ACCELERATION, delta)
	
	#jumping
	if direction.y < 0 and is_on_floor():
		apply_jump(delta)
	move_and_slide()
	
func move_air(delta):
	animation_tree.set("parameters/in_air_state/transition_request","air")
	
	#constant gravity causing the player to fall
	fall(delta)
	
	#air resistance
	if direction == Vector2.ZERO or (sign(direction.x) != sign(velocity.x) and velocity.x != 0):
		apply_horizontal_air_resistance(delta)
	#air acceleration
	else:
		apply_movement(direction * Vector2.RIGHT, AIR_ACCELERATION, delta)
		
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

func apply_horizontal_ground_friction(delta):
	apply_horizontal_friction(FRICTION, delta)

func apply_horizontal_air_resistance(delta):
	apply_horizontal_friction(AIR_RESISTANCE, delta)
	
func apply_horizontal_friction(friction, delta):
	var amount = friction * delta
	if abs(velocity.x) > amount:
		velocity.x -= sign(velocity.x) * amount
	else:
		velocity.x = 0

func apply_vertical_friction(friction, delta):
	var amount = friction * delta
	if abs(velocity.y) > amount:
		velocity.y -= sign(velocity.y) * amount
	else:
		velocity.y = 0

func apply_movement(dir, accel, delta):
	velocity += dir * accel * delta
	velocity.x = sign(velocity.x) * min(abs(velocity.x), MAX_HORIZONTAL_VELOCITY)
	velocity.y = sign(velocity.y) * min(abs(velocity.y), MAX_VERTICAL_VELOCITY)

func apply_jump(delta):
	apply_movement(Vector2.UP, JUMP_ACCELERATION, delta)
	
func apply_fall(delta):
	apply_movement(Vector2.DOWN, JUMP_ACCELERATION, delta)

func fall(delta):
	apply_movement(Vector2.DOWN, GRAVITY, delta)
		
func switch_direction(horizontal_direction):
	sprite.flip_h = (horizontal_direction == -1)
	sprite.position.x = horizontal_direction * 4
