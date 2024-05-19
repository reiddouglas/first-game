extends CharacterBody2D

@export var MAX_VELOCITY = 50
@export var GROUND_ACCELERATION = 500
@export var AIR_ACCELERATION = 250
@export var JUMP_ACCELERATION = 25_000
@export var FRICTION = 2500
@export var AIR_RESISTANCE = 100
@export var GRAVITY = 1000

@onready var animation_tree = $AnimationTree
@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $CollisionShape2D

@onready var direction = Vector2.ZERO

func _physics_process(delta):
	
	get_input_axis()
	fall(GRAVITY, delta)
	if is_on_floor():
		move_ground(delta)
	else:
		move_air(delta)
	
	if sign(velocity.x) != 0:
		switch_direction(sign(velocity.x))

func start(pos):
	position = pos

func get_input_axis():
	direction.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	direction.y = int(Input.is_action_just_pressed("move_down")) - int(Input.is_action_just_pressed("jump"))
	direction.normalized()

func move_ground(delta):
	if direction == Vector2.ZERO or (sign(direction.x) != sign(velocity.x) and velocity.x != 0):
		apply_horizontal_friction(FRICTION, delta)
	else:
		apply_movement(direction * Vector2.RIGHT, GROUND_ACCELERATION, delta)
	if(direction.y < 0):
		apply_jump(Vector2.UP, JUMP_ACCELERATION, delta)
	move_and_slide()
	
func move_air(delta):
	if direction == Vector2.ZERO or (sign(direction.x) != sign(velocity.x) and velocity.x != 0):
		apply_horizontal_friction(AIR_RESISTANCE, delta)
	else:
		apply_movement(direction * Vector2.RIGHT, AIR_ACCELERATION, delta)
	
		
	move_and_slide()
	
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

func apply_jump(dir, accel, delta):
	if is_on_floor():
		apply_movement(dir, accel, delta)

func fall(accel, delta):
	if not is_on_floor():
		apply_movement(Vector2.DOWN, accel, delta)
		
func switch_direction(horizontal_direction):
	sprite.flip_h = (horizontal_direction == -1)
	sprite.position.x = horizontal_direction * 4
