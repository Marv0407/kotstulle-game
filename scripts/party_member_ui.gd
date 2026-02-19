extends HBoxContainer

signal selected(hero_data: Dictionary)

@onready var name_label: Label = $NameLabel
@onready var hp_label: Label = $HPBar/HPLabel
@onready var hp_bar: ProgressBar = $HPBar
@onready var ghost_bar: ProgressBar = $HPBar/GhostBar

var character: BattleCharacter
var ghost_tween: Tween
var data: CharData

func setup(bc: BattleCharacter) -> void:
	character = bc
	name_label.text = character.get_char_name()
	hp_bar.max_value = character.get_max_hp()
	hp_bar.value = character.get_hp()
	ghost_bar.max_value = character.get_max_hp()
	ghost_bar.value = character.get_hp()

func update_hp(old_hp: int):
	if not character: return

	var new_hp = character.get_hp()
	hp_bar.max_value = character.get_max_hp()

	var tween = create_tween()
	tween.tween_property(hp_bar, "value", new_hp, 0.35)

	if new_hp < old_hp:
		adjust_ghost_hp(new_hp)
		flash(Color.RED)
	elif new_hp > old_hp:
		ghost_bar.value = new_hp
		flash(Color.LIME_GREEN)

	hp_label.text = str(new_hp) + " / " + str(character.get_max_hp())

func adjust_ghost_hp(target_value: int):
	if ghost_tween:
		ghost_tween.kill()
	ghost_tween = create_tween()
	ghost_tween.tween_interval(0.5)
	ghost_tween.tween_property(ghost_bar, "value", target_value, 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func flash(color: Color):
	modulate = color
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.25)

func sync_hp_initial():
	if not character: return
	hp_bar.max_value = character.get_max_hp()
	hp_bar.value = character.get_hp()
	ghost_bar.max_value = character.get_max_hp()
	ghost_bar.value = character.get_hp()
	hp_label.text = str(character.get_hp()) + " / " + str(character.get_max_hp())

func update_display(data: Dictionary):
	name_label.text = data["name"]
	$LevelLabel.text = "Lvl: " + str(data["level"]) # TODO
	hp_bar.max_value = data["max_hp"]
	hp_bar.value = data["current_hp"]
	hp_label.text = str(data["current_hp"]) + " / " + str(data["max_hp"])
	if has_node("XPLabel"):
		var req_xp = GameData.get_required_xp(data["level"])
		$XPLabel.text = "XP: %d / %d" % [data["xp"], req_xp]

func _gui_input(event):
	if event.is_action_pressed("ui_accept"):
		emit_signal("selected", data)
