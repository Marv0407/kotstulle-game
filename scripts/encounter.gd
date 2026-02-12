extends Area2D

@export var encounter_data: EncounterData
@export var encounter_id: String

var triggered := false

func _ready():
	if encounter_id in GameData.defeated_encounters:
		queue_free()
		return

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if encounter_id in GameData.defeated_encounters:
		return
	GameData.defeated_encounters.append(encounter_id)
	var current_scene_path = get_tree().current_scene.scene_file_path
	var player_position = body.global_position
	GameData.start_battle(current_scene_path, player_position)
	call_deferred("queue_free")
