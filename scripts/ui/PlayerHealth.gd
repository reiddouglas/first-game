extends HBoxContainer

#NOTE: script will not work if executed before the player _ready script
#To circumvent, make sure the scene is below the Player in the hierarchy

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var health_bar = $HealthBar

func _ready():
	player.health_changed.connect(_on_health_changed)
	player.max_health_changed.connect(_on_max_health_changed)
	init_health(player.max_health, player.health)

func set_health(new_health: int):
	health_bar.value = max(new_health,health_bar.min_value)

func init_health(max_health: int, health: int):
	health_bar.max_value = max_health
	health_bar.value = health

func _on_health_changed():
	set_health(player.health)

func _on_max_health_changed():
	init_health(player.max_health, player.health)
