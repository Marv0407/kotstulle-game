extends Control

####################
# Variables
####################
@onready var label = $HBoxContainer/Label
@onready var start_btn = $VBoxBtnContainer/StartBtn
@onready var load_btn = $VBoxBtnContainer/LoadBtn
@onready var credits_btn = $VBoxBtnContainer/CreditsBtn
@onready var quit_btn = $VBoxBtnContainer/QuitBtn

####################
# Functions
####################

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_btn_pressed() -> void:
	pass # Replace with function body.


func _on_load_btn_pressed() -> void:
	pass # Replace with function body.


func _on_credits_btn_pressed() -> void:
	pass # Replace with function body.


func _on_quit_btn_pressed() -> void:
	pass # Replace with function body.
