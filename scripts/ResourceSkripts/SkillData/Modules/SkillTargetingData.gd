extends Resource
class_name SkillTargetingData

@export_enum("enemies", "friends", "all", "user") var target_pool: String = "enemies"
@export_enum("alive", "dead", "any") var target_state: String = "alive"
@export_enum("all", "random", "manual") var target_selector: String = "all"
@export var target_count: int = 1
