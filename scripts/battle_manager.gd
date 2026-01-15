extends Node
class_name  BattleManager

####################
# Variables
####################
@export var party_data: Array[CharData]
@export var enemy_data: Array[CharData]
var party: Array[BattleCharacter] = []
var enemies: Array[BattleCharacter] = []
var turn_order: Array[BattleCharacter] = []
var current_turn_index := 0
enum BattleState {
	START,
	PLAYER_TURN,
	ENEMY_TURN,
	END
}
var state := BattleState.START


####################
# Functions
####################

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_battle():
	print("Battle Start") #delete later
	
	party.clear()
	enemies.clear()

	for data in party_data:
		var bc = BattleCharacter.new()
		bc.setup(data)
		party.append(bc)
		print("Party:", data.name, data.max_hp) #delete later
		
	for data in enemy_data:
		var bc = BattleCharacter.new()
		bc.setup(data)
		enemies.append(bc)
		print("Enemy:", data.name, data.max_hp) #delete later

	calculate_turn_order()
	print_turn_order() #delete later

func process_turn():
	var actor = get_current_actor()

	if actor in party:
		state = BattleState.PLAYER_TURN
	else:
		state = BattleState.ENEMY_TURN

func calculate_turn_order():
	turn_order.clear()
	turn_order.append_array(party)
	turn_order.append_array(enemies)

	turn_order.sort_custom(func(a, b):
		return a.data.speed > b.data.speed
		)

func get_current_actor() -> BattleCharacter:
	return turn_order[current_turn_index]

func next_turn():
	current_turn_index += 1
	if current_turn_index >= turn_order.size():
		current_turn_index = 0

func attack(attacker: BattleCharacter, target: BattleCharacter):
	var damage = max(
		attacker.data.attack - target.data.defense,
		1
	)
	target.current_hp -= damage

func print_turn_order(): #delete later
	print("Turn Order:")
	for c in turn_order:
		print(" - ", c.data.name)
