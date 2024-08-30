extends CharacterBody2D

class_name Entity

#Signals
signal health_changed
signal max_health_changed
signal death

#Variables
#Physics
var max_horizontal_speed: int: set = set_max_horizontal_speed, get = get_max_horizontal_speed
var max_vertical_speed: int: set = set_max_vertical_speed, get = get_max_vertical_speed
var friction: int: set = set_friction, get = get_friction
var air_resistance: int: set = set_air_resistance, get = get_air_resistance
var jump_accel: int: set = set_jump_accel, get = get_jump_accel
var gravity_mult: float = 1: set = set_gravity_mult, get = get_gravity_mult
var accel: int: set = set_accel, get = get_accel
var accel_mult: float = 1: set = set_accel_mult, get = get_accel_mult

#Entity stats
var max_health: int: set = set_max_health, get = get_max_health
var health: int: set = set_health, get = get_health
var attack_power: int: set = set_attack_power, get = get_attack_power
var knock_power: int: set = set_knock_power, get = get_knock_power
var invuln_time: float = 1.0: set = set_invuln_time, get = get_invuln_time
var stun_time: float = 1.0: set = set_stun_time, get = get_stun_time

#Entity States
var attacking: bool = false
var stunned: bool = false
var invulnerable: bool = false

#Setters and Getters
func set_max_horizontal_speed(new_max_speed):
	max_horizontal_speed =  max(new_max_speed,0)

func get_max_horizontal_speed():
	return max_horizontal_speed

func set_max_vertical_speed(new_max_speed):
	max_vertical_speed =  max(new_max_speed,0)

func get_max_vertical_speed():
	return max_vertical_speed

func set_friction(new_friction):
	friction =  max(new_friction,0)

func get_friction():
	return friction

func set_air_resistance(new_resistance):
	air_resistance =  max(new_resistance,0)

func get_air_resistance():
	return air_resistance

func set_jump_accel(new_acceleration):
	jump_accel =  max(new_acceleration,0)

func get_jump_accel():
	return jump_accel

func set_gravity_mult(new_mult: float):
	gravity_mult = max(new_mult,0)

func get_gravity_mult():
	return gravity_mult

func set_accel_mult(new_mult: float):
	accel_mult = max(new_mult,0)

func get_accel_mult():
	return accel_mult

func set_accel(new_accel: int):
	accel = max(new_accel,0)

func get_accel():
	return accel

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

func set_knock_power(new_knock_power: int):
	knock_power = max(new_knock_power,0)

func get_knock_power():
	return knock_power

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

"""
Function: move
Description: moves the character in the given direction on the ground or air
Input:
	dir - the direction of the movement in Vector2 form
	delta - the delta function from get_physics_process_delta_time()
Output:
	void
"""
func move(dir: Vector2, accel: int, delta):
	velocity += dir * accel * delta

"""
Function: jump
Description: applies the jump acceleration upwards for a fraction of a second
Input:
	delta - the delta function from get_physics_process_delta_time()
Output:
	void
"""
func jump(delta):
	move(Vector2.UP, get_jump_accel(), delta)

"""
Function: apply_friction
Description: applies friction and air resistance against entity movement.
Input:
	delta - the delta function from get_physics_process_delta_time()
Output:
	void
"""
func apply_friction(delta):
	var initial_velocity: Vector2 = get_velocity()
	if is_on_floor():
		if(abs(initial_velocity.x) > 0):
			velocity.x -= sign(velocity.x) * (get_friction() + max(0,abs(get_velocity().x) - get_max_horizontal_speed())) * delta
			if sign(get_velocity().x) != sign(initial_velocity.x):
				velocity.x = 0
	else:
		if(abs(initial_velocity.x) > 0):
			velocity.x -= sign(velocity.x) * (get_air_resistance() + max(0,abs(get_velocity().x) - get_max_horizontal_speed())) * delta
			if sign(get_velocity().x) != sign(initial_velocity.x):
				velocity.x = 0
		if(abs(initial_velocity.y) > 0):
			velocity.y -= sign(velocity.y) * (get_air_resistance() + max(0,abs(get_velocity().y) - get_max_vertical_speed())) * delta
			if sign(get_velocity().y) != sign(initial_velocity.y):
				velocity.y = 0

"""
Function: apply_gravity
Description: applies the downward acceleration due to gravity
Input:
	delta - the delta function from get_physics_process_delta_time()
Output:
	void
"""
func apply_gravity(delta):
	move(Vector2.DOWN, Constants.GRAVITY * get_gravity_mult(), delta)

"""
Function: face_direction
Description: turns the entity to face the given direction. care for entities
			 with sprites facing the negative x direction, since this function will
			 do the opposite of what you want
Input:
	delta - the delta function from get_physics_process_delta_time()
Output:
	void
"""
func face_direction(horizontal_direction):
	scale.x = scale.y * horizontal_direction

#Health
func fill_health():
	health = max_health

func die():
	print(name + " died!")
	queue_free()

func _on_hurt_box_area_entered(hitbox: Area2D):
	#Only hitboxes can interact with hurtboxes
	if hitbox.name != "HitBox":
		return
	var entity: Entity = hitbox.get_parent()
	if entity:
		#Deal damage to this entity if hit
		if take_damage(entity):
			return
		#Invuln frames if entity survives the attack
		_invuln_enabled(true)
		invuln_timer.start()
		#Hitstun for entity after being hit
		_hitstun_enabled(true)
		hitstun_timer.start()
		#Get knocked back as well
		take_knockback(entity)

	else:
		printerr( str(entity) + " is not valid")

func _on_invuln_timer_timeout():
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
	_hitstun_enabled(false)

func _hitstun_enabled(input: bool):
	stunned = input
	if(input):
		animation_tree.set("parameters/hit_state/transition_request","hit")
	else:
		animation_tree.set("parameters/hit_state/transition_request","not_hit")

"""
Function: take_damage
Description: adjusts health values after taking damage from an opposing entity and checks for fatal damage
Input:
	entity - the entity dealing damage
Output:
	Boolean - true if the damage taken would be fatal (reduce health to zero), false otherwise
"""
func take_damage(entity: Entity):
		var damage = entity.get_attack_power()
		set_health(get_health()-damage)
		emit_signal("health_changed")
		print(entity.name + " did " + str(damage) + " damage to " + name)
		print(name + " has " + str(health) + "/" + str(max_health) + " health remaining.")
		
		#Kill entity if health reaches zero
		if get_health() <= 0:
			emit_signal("death")
			die()
			return true
		else:
			return false

"""
Function: take_knockback
Description: applies a force away from an entity based on its knockback value
			 special considerations are taken if on the floor when the knockback is applied
Input:
	entity - the entity being interacted with
Output:
	void
"""
func take_knockback(entity: Entity):
	#default angle if hit while planted on the ground
	const FLOOR_ANGLE = PI/16
	
	var knockback = entity.get_knock_power()
	var entity_pos = entity.global_position
	var trajectory: float = global_position.angle_to_point(entity_pos)
	
	if is_on_floor():
		if entity_pos.x - global_position.x < 0:
			trajectory = -FLOOR_ANGLE
		else:
			trajectory = -PI + FLOOR_ANGLE
	print(str(name) + " took knockback at angle " + str(trajectory) + " from " + str(entity.name))
	set_velocity(Vector2.from_angle(trajectory) * knockback)
