extends CharacterBody2D

class_name Entity

#Signals
signal health_changed
signal max_health_changed
signal death

#Variables
#Physics
var max_horizontal_velocity: int: set = _set_max_horizontal_velocity, get = _get_max_horizontal_velocity
var max_vertical_velocity: int: set = _set_max_vertical_velocity, get = _get_max_vertical_velocity
var friction: int: set = _set_friction, get = _get_friction
var air_resistance: int: set = _set_air_resistance, get = _get_air_resistance
var jump_acceleration: int: set = _set_jump_acceleration, get = _get_jump_acceleration
var gravity_mult: float = 1: set = _set_gravity_mult, get = _get_gravity_mult

#Entity stats
var speed: int: set = _set_speed, get = _get_speed
var speed_mult: float = 1: set = _set_speed_mult, get = _get_speed_mult
var max_health: int: set = _set_max_health, get = _get_max_health
var health: int: set = _set_health, get = _get_health
var attack_power: int: set = _set_attack_power, get = _get_attack_power
var invuln_time: float = 1.0: set = _set_invuln_time, get = _get_invuln_time

#Entity States
var attacking: bool = false
var stunned: bool = false
var invulnerable: bool = false

#Setters and Getters
func _set_max_horizontal_velocity(new_max_velocity):
	max_horizontal_velocity =  max(new_max_velocity,0)

func _get_max_horizontal_velocity():
	return max_horizontal_velocity

func _set_max_vertical_velocity(new_max_velocity):
	max_vertical_velocity =  max(new_max_velocity,0)

func _get_max_vertical_velocity():
	return max_vertical_velocity

func _set_friction(new_friction):
	friction =  max(new_friction,0)

func _get_friction():
	return friction

func _set_air_resistance(new_resistance):
	air_resistance =  max(new_resistance,0)

func _get_air_resistance():
	return air_resistance

func _set_jump_acceleration(new_acceleration):
	jump_acceleration =  max(new_acceleration,0)

func _get_jump_acceleration():
	return jump_acceleration

func _set_gravity_mult(new_mult: float):
	gravity_mult = max(new_mult,0)

func _get_gravity_mult():
	return gravity_mult

func _set_speed_mult(new_mult: float):
	speed_mult = max(new_mult,0)

func _get_speed_mult():
	return speed_mult

func _set_speed(new_speed: int):
	speed = max(new_speed,0)

func _get_speed():
	return speed

func _set_max_health(new_max_health: int):
	if max_health != null:
		if new_max_health > max_health:
			health += new_max_health - max_health
		elif health > new_max_health:
			health = new_max_health
		#The entity must have a non-zero positive max health
	max_health = max(new_max_health,1)

func _get_max_health():
	return max_health

func _set_health(new_health: int):
	health = min(max(new_health,0),max_health)

func _get_health():
	return health

func _set_attack_power(new_attack_power: int):
	attack_power = max(new_attack_power,0)

func _get_attack_power():
	return attack_power

func _set_invuln_time(new_invuln_time: float):
	invuln_time = new_invuln_time

func _get_invuln_time():
	return invuln_time

#Ready functions
@onready var sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree
@onready var hurt_box = $HurtBox
@onready var invuln_timer = $HurtBox/InvulnTimer
@onready var hit_box = $HitBox

func _ready():
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	invuln_timer.timeout.connect(_on_invuln_timer_timeout)
	#make sure to set invuln time for all entities!
	invuln_timer.wait_time = invuln_time

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
func _fill_health():
	health = max_health

func _death():
	print(name + " died!")
	queue_free()

func _on_hurt_box_area_entered(hitbox: Area2D):
	if hitbox.name != "HitBox":
		return
	var entity: Entity = hitbox.get_parent()
	if entity:
		#Deal damage to entity if hit
		var damage = entity._get_attack_power()
		_set_health(_get_health()-damage)
		emit_signal("health_changed")
		print(entity.name + " did " + str(damage) + " damage to " + name)
		print(name + " has " + str(health) + "/" + str(max_health) + " health remaining.")
		
		#Kill entity if health reaches zero
		if _get_health() <= 0:
			emit_signal("death")
			_death()
		else:
			#Invuln frames if entity survives the attack
			_invuln_enabled(true)
			invuln_timer.start()

	else:
		printerr( str(entity) + " is not valid")

func _on_invuln_timer_timeout():
	print("Invuln ended")
	_invuln_enabled(false)

func _invuln_enabled(input: bool):
	invulnerable = input
	for child in hurt_box.get_children():
		if child.is_class("CollisionShape2D"):
			child.set_deferred("disabled",input)
