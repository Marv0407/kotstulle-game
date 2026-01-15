extends Node

@onready var battle_manager = $BattleManager
@onready var log_label = $DebugUI/LogLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	log_label.text = "Bereit.\n"

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

#func _on_start_battle_button_pressed():
	#log_label.text += "\n--- Kampf startet ---\n"
	#battle_manager.start_battle()

func _on_start_battle_btn_pressed() -> void:
	log_label.text += "\n--- Kampf startet ---\n"
	battle_manager.start_battle()
