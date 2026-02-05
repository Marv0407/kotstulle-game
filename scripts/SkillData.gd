extends Resource
class_name SkillData

@export_group("Info")
@export var skill_name: String = "Angriff"
@export var description: String = ""
@export var icon: Texture2D
@export var mp_cost: int = 0

@export_group("Visuals")
@export var vfx_scene: PackedScene 
@export var visible_in_menu: bool = true

@export_group("Targeting")
@export_enum("enemies", "friends", "all", "user") var target_pool: String = "enemies"
@export_enum("alive", "dead", "any") var target_state: String = "alive"
@export_enum("all", "random", "manual") var target_selector: String = "all"
@export var target_count: int = 1

@export_group("Damage & Type")
@export_enum("Physical", "Magic", "True") var damage_type: String = "Physical"
@export var base_damage: int = 10
@export var can_crit: bool = true
@export var crit_multiplier: float = 1.5
@export_range(0.0, 5.0) var scaling_factor: float = 1.0
@export_enum("atk", "sp_atk", "luck", "speed") var scaling_stat: String = "atk"
@export var hit_count: int = 1 
@export var delay_between_hits: float = 0.1

@export_group("Status Effects")
@export var status_to_apply: StatusEffectData
@export_range(0, 100) var chance_to_apply: float = 100.0
