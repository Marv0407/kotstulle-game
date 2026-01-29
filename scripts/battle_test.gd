extends Node

@onready var battle_manager = $BattleManager
@onready var log_label = $DebugUI/LogLabel
@onready var attack_btn = $DebugUI/CanvasLayer/PartyMenuContainer/ActionsContainer/ColorRect/VBoxContainer/AttackBtn
@onready var start_battle_btn = $DebugUI/VBoxContainer/StartBattleBtn

func _ready() -> void:
	log_label.text = "Bereit.\n"


func _on_start_battle_btn_pressed() -> void:
	log_label.text += "\n--- Kampf startet ---\n"
	#attack_btn.disabled = false
	battle_manager.start_battle()
	start_battle_btn.hide()

func _on_basic_attack_pressed() -> void:
	battle_manager.debug_player_attack()
