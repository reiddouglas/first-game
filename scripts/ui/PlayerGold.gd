extends HBoxContainer

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var gold_label = $GoldLabel

func _ready():
	player.gold_changed.connect(_on_gold_changed)
	set_gold(player.gold)

func set_gold(gold: int):
	gold_label.text = "Gold: " + str(max(gold,0))

func _on_gold_changed():
	set_gold(player.gold)
