extends Node

@onready var battle_manager = $BattleManager
@onready var log_label = $DebugUI/LogLabel
@onready var attack_btn = $DebugUI/CanvasLayer/PartyMenuContainer/ActionsContainer/ColorRect/VBoxContainer/AttackBtn
@onready var start_battle_btn = $DebugUI/VBoxContainer/StartBattleBtn

func _ready() -> void:
	log_label.text = "Bereit.\n"


func _on_start_battle_btn_pressed() -> void:
	log_label.text += "\n--- Kampf startet ---\n"
	battle_manager.start_battle()
	start_battle_btn.hide()

func _on_basic_attack_pressed() -> void:
	var skill = load("res://ressources/skills/PlayerAttack.tres")
	battle_manager.start_target_selection(battle_manager.get_current_actor(), skill)
