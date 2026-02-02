extends PanelContainer

signal skill_selected(skill: SkillData)
signal canceled
signal request_sound(type: String)

@onready var list = $ScrollContainer/VBoxContainer

func setup(actor: BattleCharacter):
	for child in list.get_children():
		child.queue_free()
	
	for skill in actor.data.skills:
		var btn = Button.new()
		btn.text = skill.skill_name + " - " + str(skill.mp_cost) + " MP"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_entered.connect(_on_button_focused)
		btn.mouse_entered.connect(_on_button_focused)
		btn.pressed.connect(_on_button_pressed)
		btn.pressed.connect(func(): emit_signal("skill_selected", skill))
		list.add_child(btn)

func _unhandled_input(event):
	if not visible: return
	if event.is_action_pressed("ui_cancel"):
		close_menu()

func _on_back_btn_pressed() -> void:
	close_menu()

func focus_first_button():
	if list.get_child_count() > 0:
		list.get_child(0).grab_focus()

func close_menu():
	canceled.emit()

func _on_button_focused():
	request_sound.emit("focus")

func _on_button_pressed():
	request_sound.emit("select")
