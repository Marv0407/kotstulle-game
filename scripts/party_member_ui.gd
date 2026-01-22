extends HBoxContainer

@onready var name_label: Label = $NameLbl
@onready var hp_label: Label = $HPBar/HPLbl
@onready var hp_bar: ProgressBar = $HPBar

var character: BattleCharacter

func setup(bc: BattleCharacter) -> void:
	character = bc
	name_label.text = character.get_char_name()
	hp_bar.max_value = character.get_max_hp()
	hp_bar.value = character.get_hp()

func update_hp():
	if character:
		hp_bar.max_value = character.get_max_hp()
		hp_label.text = str(character.get_hp()) + " / " + str(character.get_max_hp())
		var tween = create_tween()
		tween.tween_property(hp_bar, "value", character.get_hp(), 0.3)
