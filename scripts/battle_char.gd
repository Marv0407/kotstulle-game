extends Node
class_name BattleCharacter

var data: CharData
var current_hp: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func setup(character_data: CharData):
	data = character_data
	current_hp = data.max_hp

func is_alive() -> bool:
	return current_hp > 0
