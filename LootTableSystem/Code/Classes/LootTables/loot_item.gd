## Information contained for how a item possible to be rolled by a LootTable should be rolled
@icon("res://Art/loot_item_icon.png")
class_name LootItem
extends LootTableSystem

enum ROLL_FLAG {
	MAXIMUM,
	MINIMUM,
	EXACT,
}

var flags: Dictionary
@export var loot: String ## What is put in the output of a LootTable
@export_multiline var description: String

@export var weight: float: ## How likely something is to be rolled. Higher is more common. I would recommend treating these like percentages, but it's up to you. Must be greater than or equal to 0, and setting it to 0 disables it entirely.
	set(value):
		if value >= 0:
			weight = value
		else:
			weight = 0

@export_range(0, 10, 1, "or_greater") var minimum_value: int = 0: ## The minimum amount that this LootItem can be rolled. This will count against the number_of_results_range, since these will always be rolled (plan accordingly). Will swap with maximum if minimum > maximum. Sets to 0 if < 0.
	set(value):
		if value >= 0:
			minimum_value = value
		else:
			minimum_value = 0
		calculate_flags()
@export_range(0, 10, 1, "or_greater") var maximum_value: int = 0: ## Will swap with minimum if minimum > maximum. Sets to 0 if < 0.
	set(value):
		if value >= 0:
			maximum_value = value
		else:
			maximum_value = 0
		calculate_flags()

func _ready() -> void:
	weight = weight # use setter function (this is strange)
	if not loot: # default loot output
		loot = name
	#print(name, " -> Min value: ", minimum_value, ", Max value: ", maximum_value)
	calculate_flags()


func calculate_flags() -> void:
	var valid_flags: int = 0
	if maximum_value > 0:
		flags[ROLL_FLAG.MAXIMUM] = maximum_value
		valid_flags += 1
	if minimum_value > 0:
		flags[ROLL_FLAG.MINIMUM] = minimum_value
		valid_flags += 1

	if valid_flags < 2: #if it doesn't have enough flags for them to be swappable or exact, ignore the remaining code
		return
		
	if minimum_value == maximum_value:
		flags = {ROLL_FLAG.EXACT: minimum_value}
	elif minimum_value > maximum_value: #or maximum_value < minimum_value
		flags = {ROLL_FLAG.MINIMUM: maximum_value, ROLL_FLAG.MAXIMUM: minimum_value}
