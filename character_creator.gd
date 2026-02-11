extends Control

@onready var name_input = $Panel/VBoxContainer/LineEdit
@onready var class_dropdown = $Panel/VBoxContainer/ClassDropdown
@onready var hp_label = $Panel2/GridContainer/HPVal
@onready var atk_label = $Panel2/GridContainer/AtkVal
@onready var def_label = $Panel2/GridContainer/DefVal
@onready var spatk_label = $Panel2/GridContainer/SPAtkVal
@onready var spdef_label = $Panel2/GridContainer/SPDefVal
@onready var speed_label = $Panel2/GridContainer/SpeedVal
@onready var luck_label = $Panel2/GridContainer/LuckVal
@onready var portrait_preview = $Panel2/PanelContainer/ClassPortrait
@onready var class_description = $Panel2/ClassDescription

var class_options: Array[String] = [
	"res://ressources/PlayerCharacters/Hero.tres",
	"res://ressources/PlayerCharacters/Warrior.tres",
	"res://ressources/PlayerCharacters/Mage.tres",
	"res://ressources/PlayerCharacters/Rogue.tres",
]

func _ready():
	_update_stat_preview(0)
	class_dropdown.item_selected.connect(_update_stat_preview)

func _on_button_pressed():
	var chosen_name = name_input.text
	if chosen_name == "":
		chosen_name = "Held"

	var selected_index = class_dropdown.selected
	var class_res = load(class_options[selected_index]) as CharData

	GameData.party_members.clear()
	GameData.add_new_hero(class_res, chosen_name)

	get_tree().change_scene_to_file("res://scenes/BattleTest.tscn")

func _update_stat_preview(index: int):
	var class_res = load(class_options[index]) as CharData
	if class_res:
		hp_label.text = str(class_res.max_hp)
		atk_label.text = str(class_res.atk)
		def_label.text = str(class_res.def)
		spatk_label.text = str(class_res.sp_atk)
		spdef_label.text = str(class_res.sp_def)
		speed_label.text = str(class_res.speed)
		luck_label.text = str(class_res.luck)
		class_description.text = str(class_res.description)

		if class_res.portrait:
			portrait_preview.texture = class_res.portrait
