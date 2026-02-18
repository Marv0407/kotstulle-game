extends Resource
class_name SkillData

@export_group("Info")
@export var skill_name: String = "Angriff"
@export var description: String = ""
@export var icon: Texture2D
@export var mp_cost: int = 0

@export_group("Targeting")
@export var targeting: SkillTargetingData

@export_group("Effects")
@export var effects: Array[SkillEffect]

@export_group("VFX & SFX")
@export_subgroup("Visuals")
@export var vfx_scene: PackedScene 
@export var visible_in_menu: bool = true
@export_subgroup("SFX")
@export var wind_up: AudioStream
@export var hit_sound: AudioStream
