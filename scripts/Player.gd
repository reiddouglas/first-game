extends CharacterBody2D

@export var MAX_VELOCITY = 50
@export var GROUND_ACCELERATION = 500
@export var AIR_ACCELERATION = 250
@export var JUMP_ACCELERATION = 25_000
@export var FRICTION = 1000
@export var AIR_RESISTANCE = 100
@export var GRAVITY = 1000

@onready var animation_tree = $AnimationTree
@onready var sprite = $AnimatedSprite2D
@onready var direction = Vector2.ZERO

#Enums
enum IN_AIR_STATE {GROUND = 0, AIR}
enum IN_AIR_MOVEMENT {FALLING = 0, JUMPING}
enum ON_GROUND_MOVEMENT {IDLING = 0, RUNNING, TURNING}

func _ready():
	animation_tree.active = true
	

func start(pos):
	position = pos
	print(IN_AIR_STATE)

func _physics_process(delta):
	
	get_input_axis()
	
	print(velocity.y)
	
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
	if (direction.x == 0 or sign(direction.x) != sign(velocity.x)) and velocity.x != 0:
		animation_tree.set("parameters/on_ground_movement/transition_request","turning")
		apply_horizontal_ground_friction(delta)
	elif direction.x == 0 and velocity.x == 0:
		animation_tree.set("parameters/on_ground_movement/transition_request","idling")
	else:
		animation_tree.set("parameters/on_ground_movement/transition_request","running")
		apply_movement(direction * Vector2.RIGHT, GROUND_ACCELERATION, delta)
	if direction.y < 0 and is_on_floor():
		apply_jump(delta)
	move_and_slide()
	
func move_air(delta):
	animation_tree.set("parameters/in_air_state/transition_request","air")
	fall(GRAVITY, delta)
	if direction == Vector2.ZERO or (sign(direction.x) != sign(velocity.x) and velocity.x != 0):
		apply_horizontal_air_resistance(delta)
	else:
		apply_movement(direction * Vector2.RIGHT, AIR_ACCELERATION, delta)
		
	# change animation to falling if moving downwards in air, otherwise character is jumping upwards
	if velocity.y > 0:
		animation_tree.set("parameters/in_air_movement/transition_request","falling")
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
	velocity = velocity.limit_length(MAX_VELOCITY)

func apply_jump(delta):
	apply_movement(Vector2.UP, JUMP_ACCELERATION, delta)

func fall(accel, delta):
	apply_movement(Vector2.DOWN, accel, delta)
		
func switch_direction(horizontal_direction):
	sprite.flip_h = (horizontal_direction == -1)
	sprite.position.x = horizontal_direction * 4
