extends VBoxContainer
class_name PartyHUD

@export var party_member_ui_scene: PackedScene

func populate(party: Array[BattleCharacter]) -> void:
	for child in get_children():
		child.queue_free()

	for member in party:
		var ui = party_member_ui_scene.instantiate()
		add_child(ui)
		ui.setup(member)
		ui.sync_hp_initial()
