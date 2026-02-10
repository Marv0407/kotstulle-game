extends Resource
class_name CharData

@export var name: String
@export var max_hp: int
@export var atk: int
@export var def: int
@export var sp_atk: int
@export var sp_def: int
@export var luck: int
@export var speed: int
@export var level: int
@export var xp: int
@export var portrait: Texture2D
@export var sprite: Texture2D
@export var overworld_sprite: Texture2D
@export var resistances := {
	"FIRE": 0,
	"POISON": 0,
	"PSYCHIC": 0,
	#TODO
}
@export var description: String
@export var skills: Array[SkillData] = []
