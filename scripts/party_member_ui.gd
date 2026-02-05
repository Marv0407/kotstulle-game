extends HBoxContainer

@onready var name_label: Label = $NameLbl
@onready var hp_label: Label = $HPBar/HPLbl
@onready var hp_bar: ProgressBar = $HPBar
@onready var highlight = $NameLbl/HighlightRect

var character: BattleCharacter

func setup(bc: BattleCharacter) -> void:
	character = bc
	name_label.text = character.get_char_name()
	hp_bar.max_value = character.get_max_hp()
	hp_bar.value = character.get_hp()

func update_hp(old_hp: int):
	if not character: return

	var new_hp = character.get_hp()
	hp_bar.max_value = character.get_max_hp()

	var tween = create_tween()
	tween.tween_property(hp_bar, "value", new_hp, 0.35)

	if new_hp < old_hp:
		flash(Color.RED)
	elif new_hp > old_hp:
		flash(Color.LIME_GREEN)

	hp_label.text = str(new_hp) + " / " + str(character.get_max_hp())

func flash(color: Color):
	modulate = color
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.25)

func sync_hp_initial():
	if not character: return
	hp_bar.max_value = character.get_max_hp()
	hp_bar.value = character.get_hp()
	hp_label.text = str(character.get_hp()) + " / " + str(character.get_max_hp())
