extends Resource
class_name StatusEffectData

@export var effect_name: String = ""
@export var icon: Texture2D
@export var duration: int = 3
@export_enum("Buff", "Debuff", "DoT") var type: String = "DoT"
@export var is_stackable: bool = false
@export var stack_cap: int = 5
var current_stacks: int = 1

@export_group("Buff&Debuff")
@export var stat_modifier: float = 1.0 # 1.1 wäre +10% auf einen Stat
@export_enum("atk", "def", "speed") var affected_stat: String = "atk"
@export_group("Damage over Time")
@export var base_dot_damage: int = 0

@export_group("Scaling")
@export_enum("atk", "sp_atk", "none") var scaling_stat: String = "none"
@export var scaling_factor: float = 0.2
var stored_actor_stat: int = 0
