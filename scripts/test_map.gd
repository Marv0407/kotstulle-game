extends Node2D

@onready var player = $Player

func _ready():
	if GameData.return_position != Vector2.ZERO:
		player.global_position = GameData.return_position
		GameData.return_position = Vector2.ZERO
