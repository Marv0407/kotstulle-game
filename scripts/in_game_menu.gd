extends CanvasLayer

@export var party_member_ui_scene: PackedScene
@export var character_details_scene: PackedScene
var is_sub_menu_open: bool = false
var current_details_screen = null

func _ready():
	hide() 

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if current_details_screen and current_details_screen.visible:
			current_details_screen.queue_free()
			current_details_screen = null
			$PanelContainer/MainContainer/ButtonList/PartyBtn.grab_focus() 
		elif is_sub_menu_open:
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
	_clear_content_area()
	
	for hero_data in GameData.party_members:
		var member_ui = party_member_ui_scene.instantiate()
		%PartyView.add_child(member_ui)
		member_ui.update_display(hero_data)
		member_ui.gui_input.connect(_on_hero_card_input.bind(hero_data, member_ui))

func _on_hero_card_input(event: InputEvent, hero_data: Dictionary, card_node: Control):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		if current_details_screen:
			current_details_screen.queue_free()
		var details = character_details_scene.instantiate()
		add_child(details) 
		details.display_hero(hero_data)
		current_details_screen = details
		is_sub_menu_open = true

func _on_party_btn_pressed() -> void:
	is_sub_menu_open = true
	show_party()

func _on_quit_btn_pressed() -> void:
	get_tree().quit()

func _clear_content_area():
	for child in %PartyView.get_children():
		child.queue_free()
