extends PanelContainer

signal skill_selected(skill: SkillData)
signal canceled

@onready var list = $ScrollContainer/VBoxContainer

func setup(actor: BattleCharacter):
	for child in list.get_children():
		child.queue_free()
	
	for skill in actor.data.skills:
		var btn = Button.new()
		btn.text = skill.skill_name
		btn.pressed.connect(func(): emit_signal("skill_selected", skill))
		list.add_child(btn)

func _on_back_btn_pressed() -> void:
	canceled.emit()
