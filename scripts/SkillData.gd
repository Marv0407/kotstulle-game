extends Resource
class_name SkillData

@export_group("Info")
@export var skill_name: String = "Angriff"
@export var description: String = ""
@export var icon: Texture2D
@export var mp_cost: int = 0

@export_group("Targeting")
@export_enum("enemies", "friends", "all", "user") var target_pool: String = "enemies"
@export_enum("alive", "dead", "any") var target_state: String = "alive"
@export_enum("all", "random", "manual") var target_selector: String = "all"
@export var target_count: int = 1

@export_group("Damage & Type")
@export_enum("Physical", "Magic", "True") var damage_type: String = "Physical"
@export var base_damage: int = 10
@export_range(0.0, 5.0) var scaling_factor: float = 1.0
@export_enum("atk", "sp_atk", "luck", "speed") var scaling_stat: String = "atk"
