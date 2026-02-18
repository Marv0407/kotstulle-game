extends Resource
class_name CharData

@export_group("Info")
@export var name: String
@export var description: String

@export_group("Stats")
@export var max_hp: int
@export var max_mp: int
@export var atk: int
@export var def: int
@export var sp_atk: int
@export var sp_def: int
@export var luck: int
@export var speed: int
@export var level: int
@export var xp: int

@export_group("Growth Stats")
@export var hp_growth: int = 10
@export var mp_growth: int = 10
@export var atk_growth: int = 2
@export var def_growth: int = 1
@export var sp_atk_growth: int = 2
@export var sp_def_growth: int = 1
@export var speed_growth: int = 1
@export var luck_growth: int = 1

@export_group("Skills")
@export var skills: Array[SkillData] = []

@export_group("Visuals")
@export var portrait: Texture2D
@export var sprite: Texture2D
@export var overworld_sprite: Texture2D

@export_group("Drops")
@export var xp_yield: int
@export var gold: int
@export var items: Array[SkillData] = [] # FIXME hier ItemData einfügen
@export_range(0, 100) var item_dropchance: float = 100

@export_group("Misc.")
@export var resistances := {
	"FIRE": 0,
	"POISON": 0,
	"PSYCHIC": 0,
	#TODO
}
