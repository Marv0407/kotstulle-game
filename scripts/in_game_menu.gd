extends CanvasLayer

@export var party_member_ui_scene: PackedScene 
var is_sub_menu_open: bool = false

func _ready():
	hide() 

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if is_sub_menu_open:
			_close_sub_menu()
		else:
			toggle_menu()
		get_viewport().set_input_as_handled()

func _close_sub_menu():
	for child in %PartyView.get_children():
		child.queue_free()
	is_sub_menu_open = false
	$PanelContainer/MainContainer/ButtonList/PartyBtn.grab_focus()

func toggle_menu():
	visible = !visible
	get_tree().paused = visible
	if visible:
		is_sub_menu_open = false
		_close_sub_menu() 
		$PanelContainer/MainContainer/ButtonList/PartyBtn.grab_focus()

func show_party():
	for child in %PartyView.get_children():
		child.queue_free()
	for hero_data in GameData.party_members:
		var member_ui = party_member_ui_scene.instantiate()
		%PartyView.add_child(member_ui)
		member_ui.update_display(hero_data)

func _on_party_btn_pressed() -> void:
	is_sub_menu_open = true
	show_party()
