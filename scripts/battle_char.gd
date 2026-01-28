extends Node
class_name BattleCharacter

var data: CharData
var current_hp: int
var battle_node: Node2D
var active_effects: Array[StatusEffectData] = []

func _ready() -> void:
	pass 

func setup(character_data: CharData):
	data = character_data
	current_hp = data.max_hp

func is_alive() -> bool:
	return current_hp > 0

# ---- GETTER FUNCTIONS ----
func get_char_name() -> String:
	return data.name

func get_max_hp() -> int:
	return data.max_hp

func get_hp() -> int:
	return current_hp

func get_lvl() -> int:
	return data.level

func get_stat(stat_name: String) -> int:
	var base_value = data.get(stat_name)
	var multiplier = 1.0
	
	for effect in active_effects:
		if effect.affected_stat == stat_name:

			var effect_strength = (1.0 - effect.stat_modifier) * effect.current_stacks
			multiplier -= effect_strength

	return int(base_value * max(0.1, multiplier)) # Nicht unter 10% sinken lassen
