extends CharacterBody2D

class_name Entity

#Signals
signal health_changed
signal max_health_changed
signal death

#Variables
#Physics
var max_horizontal_velocity: int: set = set_max_horizontal_velocity, get = get_max_horizontal_velocity
var max_vertical_velocity: int: set = set_max_vertical_velocity, get = get_max_vertical_velocity
var friction: int: set = set_friction, get = get_friction
var air_resistance: int: set = set_air_resistance, get = get_air_resistance
var jump_acceleration: int: set = set_jump_acceleration, get = get_jump_acceleration
var gravity_mult: float = 1: set = set_gravity_mult, get = get_gravity_mult

#Entity stats
var speed: int: set = set_speed, get = get_speed
var speed_mult: float = 1: set = set_speed_mult, get = get_speed_mult
var max_health: int: set = set_max_health, get = get_max_health
var health: int: set = set_health, get = get_health
var attack_power: int: set = set_attack_power, get = get_attack_power
var invuln_time: float = 1.0: set = set_invuln_time, get = get_invuln_time
var stun_time: float = 1.0: set = set_stun_time, get = get_stun_time

#Entity States
var attacking: bool = false
var stunned: bool = false
var invulnerable: bool = false

#Setters and Getters
func set_max_horizontal_velocity(new_max_velocity):
	max_horizontal_velocity =  max(new_max_velocity,0)

func get_max_horizontal_velocity():
	return max_horizontal_velocity

func set_max_vertical_velocity(new_max_velocity):
	max_vertical_velocity =  max(new_max_velocity,0)

func get_max_vertical_velocity():
	return max_vertical_velocity

func set_friction(new_friction):
	friction =  max(new_friction,0)

func get_friction():
	return friction

func set_air_resistance(new_resistance):
	air_resistance =  max(new_resistance,0)

func get_air_resistance():
	return air_resistance

func set_jump_acceleration(new_acceleration):
	jump_acceleration =  max(new_acceleration,0)

func get_jump_acceleration():
	return jump_acceleration

func set_gravity_mult(new_mult: float):
	gravity_mult = max(new_mult,0)

func get_gravity_mult():
	return gravity_mult

func set_speed_mult(new_mult: float):
	speed_mult = max(new_mult,0)

func get_speed_mult():
	return speed_mult

func set_speed(new_speed: int):
	speed = max(new_speed,0)

func get_speed():
	return speed

func set_max_health(new_max_health: int):
	if max_health != null:
		if new_max_health > max_health:
			health += new_max_health - max_health
		elif health > new_max_health:
			health = new_max_health
		#The entity must have a non-zero positive max health
	max_health = max(new_max_health,1)

func get_max_health():
	return max_health

func set_health(new_health: int):
	health = min(max(new_health,0),max_health)

func get_health():
	return health

func set_attack_power(new_attack_power: int):
	attack_power = max(new_attack_power,0)

func get_attack_power():
	return attack_power

func set_invuln_time(new_invuln_time: float):
	invuln_time = new_invuln_time

func get_invuln_time():
	return invuln_time

func set_stun_time(new_stun_time: float):
	stun_time = new_stun_time

func get_stun_time():
	return stun_time

#Ready functions
@onready var direction = Vector2.ZERO
@onready var sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree
@onready var hurt_box = $HurtBox
@onready var invuln_timer = $HurtBox/InvulnTimer
@onready var hitstun_timer = $HurtBox/HitstunTimer
@onready var hit_box = $HitBox

func _ready():
	floor_snap_length = 5.0 #prevent entity from bouncing down slopes
	
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	invuln_timer.timeout.connect(_on_invuln_timer_timeout)
	hitstun_timer.timeout.connect(_on_hitstun_timer_timeout)
	#make sure to set timer for all entities!
	invuln_timer.wait_time = invuln_time
	hitstun_timer.wait_time = stun_time

func apply_horizontal_ground_friction(delta):
	apply_horizontal_friction(friction, delta)

func apply_horizontal_air_resistance(delta):
	apply_horizontal_friction(air_resistance, delta)
	
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
	velocity.x = sign(velocity.x) * min(abs(velocity.x), max_horizontal_velocity)
	velocity.y = sign(velocity.y) * min(abs(velocity.y), max_vertical_velocity)

func apply_jump(delta):
	apply_movement(Vector2.UP, jump_acceleration, delta)
	
func apply_fall(delta):
	apply_movement(Vector2.DOWN, jump_acceleration, delta)

func apply_gravity(delta):
	apply_movement(Vector2.DOWN, Constants.GRAVITY, delta)

# Horizontal direction is the new direction the entity wants to face
func switch_direction(horizontal_direction):
	sprite.flip_h = (horizontal_direction == -1)

#Health
func fill_health():
	health = max_health

func die():
	print(name + " died!")
	queue_free()

func _on_hurt_box_area_entered(hitbox: Area2D):
	if hitbox.name != "HitBox":
		return
	var entity: Entity = hitbox.get_parent()
	if entity:
		#Deal damage to entity if hit
		var damage = entity.get_attack_power()
		set_health(get_health()-damage)
		emit_signal("health_changed")
		print(entity.name + " did " + str(damage) + " damage to " + name)
		print(name + " has " + str(health) + "/" + str(max_health) + " health remaining.")
		
		#Kill entity if health reaches zero
		if get_health() <= 0:
			emit_signal("death")
			die()
		else:
			#Invuln frames if entity survives the attack
			_invuln_enabled(true)
			invuln_timer.start()
			#Hitstun for entity after being hit
			_hitstun_enabled(true)
			hitstun_timer.start()

	else:
		printerr( str(entity) + " is not valid")

func _on_invuln_timer_timeout():
	print("Invuln ended")
	_invuln_enabled(false)

func _invuln_enabled(input: bool):
	invulnerable = input
	if(input):
		animation_tree.set("parameters/invuln_state/transition_request","invuln")
	else:
		animation_tree.set("parameters/invuln_state/transition_request","not_invuln")
	for child in hurt_box.get_children():
		if child.is_class("CollisionShape2D"):
			child.set_deferred("disabled",input)

func _on_hitstun_timer_timeout():
	print("Stun ended")
	_hitstun_enabled(false)

func _hitstun_enabled(input: bool):
	stunned = input
	if(input):
		animation_tree.set("parameters/hit_state/transition_request","hit")
	else:
		animation_tree.set("parameters/hit_state/transition_request","not_hit")
