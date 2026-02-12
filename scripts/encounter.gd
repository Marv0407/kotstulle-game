extends Area2D

@export var encounter_data: EncounterData
@export var encounter_id: String
@export var custom_overworld_sprite: Texture2D

func _ready():
	if encounter_id == "": encounter_id = name + "_" + str(global_position)
	if encounter_id in GameData.defeated_encounters:
		queue_free()
		return
	if custom_overworld_sprite: $Sprite2D.texture = custom_overworld_sprite
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player": return
	if encounter_id in GameData.defeated_encounters: return
	GameData.current_encounter = encounter_data
	var current_scene_path = get_tree().current_scene.scene_file_path
	GameData.start_battle(current_scene_path, body.global_position, encounter_id)
