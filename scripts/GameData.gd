extends Node

var player_name: String = "Held"
var player_char_data: CharData
var last_encounter_id: String = ""

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

func start_battle(current_scene_path: String, player_position: Vector2, id: String = ""):
	return_scene_path = current_scene_path
	return_position = player_position
	last_encounter_id = id
	get_tree().change_scene_to_file("res://scenes/BattleTest.tscn")

func return_from_battle():
	get_tree().change_scene_to_file(return_scene_path)

### --- World Handling --- ###
var current_encounter: EncounterData = null
var defeated_encounters: Array[String] = []

### --- Level Handling --- ###
func get_required_xp(level: int) -> int: return int(pow(level, 1.5) * 100)

func add_xp_to_hero(hero_index: int, amount: int) -> bool:
	var hero = party_members[hero_index]
	hero["xp"] += amount
	var leveled_up = false
	while hero["xp"] >= get_required_xp(hero["level"]):
		hero["xp"] -= get_required_xp(hero["level"])
		hero["level"] += 1
		_apply_level_up_stats(hero)
		leveled_up = true
	return leveled_up

func _apply_level_up_stats(hero: Dictionary):
	var res = load(hero["base_resource"]) as CharData
	if res:
		hero["max_hp"] += res.hp_growth
		hero["atk"] += res.atk_growth
		hero["def"] += res.def_growth
		hero["sp_atk"] += res.sp_atk_growth
		hero["sp_def"] += res.sp_def_growth
		hero["speed"] += res.speed_growth
		hero["current_hp"] = hero["max_hp"] # Vollständige Heilung beim Level-Up
		print("Level Up für ", hero["name"], "!")
