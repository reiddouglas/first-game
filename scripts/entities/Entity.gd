extends CharacterBody2D

class_name Entity

var speed: int: set = _set_speed, get = _get_speed
var max_health: int: set = _set_max_health, get = _get_max_health
var health: int: set = _set_health, get = _get_health
var attack_power: int: set = _set_attack_power, get = _get_attack_power

#Setters and Getters
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

#Ready functions
@onready var hurt_box = $HurtBox
@onready var hit_box = $HitBox

func _ready():
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)

func _fill_health():
	health = max_health

func _on_hurt_box_area_entered(hitbox: Area2D):
	var entity: Entity = hitbox.get_parent() as Entity
	if entity:
		var damage = entity._get_attack_power()
		_set_health(_get_health()-damage)
		print("Entity " + str(entity) + " did " + str(damage) + " damage")
	else:
		printerr("Entity " + str(entity) + " is not valid")

