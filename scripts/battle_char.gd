extends Node
class_name BattleCharacter

var data: CharData
var current_hp: int
var battle_node: Node2D

func _ready() -> void:
	pass 

func setup(character_data: CharData):
	data = character_data
	current_hp = data.max_hp

func is_alive() -> bool:
	return current_hp > 0
