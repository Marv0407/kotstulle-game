extends Area2D

var triggered := false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return

	if body.name == "Player":
		triggered = true
		var current_scene_path = get_tree().current_scene.scene_file_path
		var player_position = body.global_position
		GameData.start_battle(current_scene_path, player_position)
