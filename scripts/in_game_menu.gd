extends CanvasLayer

@export var party_member_ui_scene: PackedScene 

func _ready():
	hide() 

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_menu()

func toggle_menu():
	visible = !visible
	get_tree().paused = visible
	if visible:
		show_party()

func show_party():
	for child in %PartyView.get_children():
		child.queue_free()

	for hero_data in GameData.party_members:
		var member_ui = party_member_ui_scene.instantiate()
		%PartyView.add_child(member_ui)
		member_ui.update_display(hero_data)
