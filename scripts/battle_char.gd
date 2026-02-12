extends Node
class_name BattleCharacter

var data: CharData
var current_hp: int
var battle_node: Node2D
var active_effects: Array[StatusEffectData] = []

func _ready() -> void:
	pass 

func setup_from_resource(res: CharData):
	self.data = res.duplicate()
	self.current_hp = res.max_hp

func setup_from_dict(dict: Dictionary):
	var base_res = load(dict["base_resource"]).duplicate()
	self.data = base_res

	self.data.name = dict["name"]
	self.data.max_hp = dict["max_hp"]
	self.current_hp = dict["current_hp"]
	self.data.atk = dict["atk"]
	self.data.def = dict["def"]
	self.data.sp_atk = dict["sp_atk"]
	self.data.sp_def = dict["sp_def"]
	self.data.speed = dict["speed"]
	self.data.luck = dict["luck"]
	self.data.skills.clear()
	for s_path in dict["skills"]:
		var s_res = load(s_path)
		self.data.skills.append(s_res)
	# TODO später hier noch Equipment-Stats dazurechnen..

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

	return int(base_value * max(0.1, multiplier)) # Nicht unter X% sinken lassen
