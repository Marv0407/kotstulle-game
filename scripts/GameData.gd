extends Node

var player_name: String = "Held"
var player_char_data: CharData

### --- Party & Stats Handling --- ###
var party_members = []

func add_new_hero(source_resource: CharData, custom_name: String):
	var dict = {
		"name": custom_name,
		"base_resource": source_resource.resource_path, # Falls wir das Original mal brauchen
		"level": 1,
		"xp": 0,
		# Stats
		"max_hp": source_resource.max_hp,
		"current_hp": source_resource.max_hp,
		"atk": source_resource.atk,
		"def": source_resource.def,
		"sp_atk": source_resource.sp_atk,
		"sp_def": source_resource.sp_def,
		"speed": source_resource.speed,
		"luck": source_resource.luck,
		"resistances": source_resource.resistances.duplicate(true),
		# Dynamische Dinge
		"equipment": {
			"weapon": null,
			"offhand": null,
			"head": null,
			"body": null,
			"legs": null,
			"feet": null,
			"accessory1": null,
			"accessory2": null,
		},
		"active_buffs": [], 
		"skills": []
	}
	for skill in source_resource.skills:
		if skill:
			dict["skills"].append(skill.resource_path)
	party_members.append(dict)

### --- Scene Return Handling --- ###
var return_scene_path: String = ""
var return_position: Vector2 = Vector2.ZERO

func start_battle(current_scene_path: String, player_position: Vector2):
	return_scene_path = current_scene_path
	return_position = player_position
	get_tree().change_scene_to_file("res://scenes/BattleTest.tscn")

func return_from_battle():
	get_tree().change_scene_to_file(return_scene_path)
