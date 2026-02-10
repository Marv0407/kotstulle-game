extends Control

@onready var name_input = $Panel/VBoxContainer/LineEdit
@onready var class_dropown = $Panel/VBoxContainer/ClassDropdown

func _on_button_pressed():
	if name_input.text != "":
		GameData.player_name = name_input.text

	get_tree().change_scene_to_file("res://scenes/BattleTest.tscn")
