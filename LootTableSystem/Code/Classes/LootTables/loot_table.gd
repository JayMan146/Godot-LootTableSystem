## LootTable for randomly outputing any set of strings based on weights, minimums, maximums, and nested tables.
@icon("res://Art/loot_table_icon.png")
class_name LootTable
extends LootTableSystem

@export var loot_table_name: String ## Used for Use Nested Names
@export_multiline var description: String ## Useful for debugging and organization

@export var number_of_results_range: Array[int] = [1, 1]: ## Number of results the LootTable can have. Limited to length of 2 (deletes remaining), and duplicates the first element if has length of only 1. This is overriden if Number Of Results Range Loot Table is used.
	set(value):
		if len(value) > 2:
			number_of_results_range = value.slice(0, 2)
		elif len(value) == 1:
			number_of_results_range = [value[0], value[0]]
		else:
			number_of_results_range = value
@export var loot_system_items: Array[LootTableSystem] ## LootItems that can be rolled in the roll() method. If these are updated, make sure to call calculate_values() so the LootTable still functions properly, as it will most likely break or not function as intended.

@export_subgroup("Further Customization")
@export var nested_loot_info: LootItem ## Used for decided how a nested LootTable is rolled (it's behavior as a LootItem). Ignored by Use Children As Loot.
@export var number_of_results_range_loot_table: LootTable ## A loot table rather than random number in a range. Ignored by Use Children As Loot.
@export var use_children_as_loot: bool = true ## Uses all children as items for Loot System Items, only by appending and not replacing. Will ignore node that is set for Nested Loot Info and Number Of Results Range Loot Table (can still be explicitly set in lists).
@export var seperate_nested_loot_tables: bool = true ## Uses .append() if true and .append_array() if false when getting the results of a nested LootTable.
@export var use_nested_names: bool = false ## When true, puts the name of the nested LootTable at the beginning of result of a nested LootTable's roll. Does not work when Seperate Nested Loot Tables is false.
@export var debug: bool = false

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var has_calculated_values_automatically: bool = false

var usable_loot_system_items: Array = []
var weights: Array[float] = []

var minimum_loot: Dictionary = {}
var maximum_items: Dictionary = {}
var exact_loot: Dictionary = {}
var add_at_start_loot: Dictionary = {}
var starting_roll_results: Array = []
var number_of_results_subtraction: int

var current_usable_loot_system_items: Array = []
var current_weights: Array[float] = []

var debug_tag: String


func _ready() -> void:
	if not loot_table_name:
		loot_table_name = name
	debug_tag = loot_table_name + ": " # used for debugging to know the source of debug statements
	number_of_results_range = number_of_results_range # use setter function (this is strange)

	if use_children_as_loot:
		set_children_as_loot()

	calculate_values()


func set_children_as_loot() -> void:
	for child in get_children():
		if child == nested_loot_info or child == number_of_results_range_loot_table:
			continue

		if child is LootItem and child not in loot_system_items:
			loot_system_items.append(child)


func calculate_values() -> void:
	usable_loot_system_items = loot_system_items.duplicate()
	# combine the two Arrays of different types
	for item in loot_system_items:
		var item_flags: Dictionary
		if item is LootItem: # add weight and flags to vars if item
			weights.append(item.weight)
			item_flags = item.flags
		elif item is LootTable: # add weight and flags to vars if table
			weights.append(item.nested_loot_info.weight)
			item_flags = item.nested_loot_info.flags
		elif debug:
			print(debug_tag, "Invalid type")

		for flag in item_flags.keys():
			# adds to dictionary with key as lootitem (/ loottable) and value as the flag's value
			if flag == LootItem.ROLL_FLAG.MAXIMUM:
				maximum_items[item] = item_flags[flag]
			if flag == LootItem.ROLL_FLAG.EXACT: 
				exact_loot[item] = item_flags[flag]

				# remove from list since exacts can't be randomly rolled, a
				var exact_item_index: int = usable_loot_system_items.find(item)
				usable_loot_system_items.pop_at(exact_item_index)
				weights.pop_at(exact_item_index)
			if flag == LootItem.ROLL_FLAG.MINIMUM:
				exact_loot[item] = item_flags[flag]
	
	var duplicate_minimum_loot: Dictionary = minimum_loot.duplicate()
	duplicate_minimum_loot.merge(exact_loot)
	add_at_start_loot = duplicate_minimum_loot
	for item in add_at_start_loot.keys():
		for index in range(add_at_start_loot[item]):
			starting_roll_results.append(item)
	
	number_of_results_subtraction = len(add_at_start_loot)
	if not number_of_results_range_loot_table:
		for i in range(len(number_of_results_range) - 1):
			number_of_results_range[i] -= number_of_results_subtraction # subtract because of minimum and exacts


## Since godot typing is not great, it returns either Array[String], Array[Array[String]], or Array[String, Array[String]], or the previous examples nested further.
func roll() -> Array:
	var final_results: Array = []
	var roll_results: Array = []
	current_weights = weights.duplicate()
	current_usable_loot_system_items = usable_loot_system_items.duplicate()

	
	var number_of_results
	if number_of_results_range_loot_table:
		number_of_results = number_of_results_range_loot_table.roll()[0].to_int()
		number_of_results -= number_of_results_subtraction # subtract because of minimum and exacts
	else:
		number_of_results = rng.randi_range(number_of_results_range[0], number_of_results_range[1])

	for result_number in range(number_of_results):
		# select random item with weights
		if not current_weights or not current_usable_loot_system_items:
			if debug:
				print(debug_tag, "Weights or Loot System Items is empty, there is either not enough to roll from maximums or there is a bug.")
			break
		
		var new_item_index: int = rng.rand_weighted(current_weights)
		var new_item = current_usable_loot_system_items[new_item_index]
		roll_results.append(new_item)

		# has maximum and exceeds it
		if new_item in maximum_items.keys() and roll_results.count(new_item) == maximum_items[new_item]:
			var maximum_item_index: int = current_usable_loot_system_items.find(new_item)
			current_usable_loot_system_items.pop_at(maximum_item_index)
			current_weights.pop_at(maximum_item_index)

	# insert starting_roll_results (min and exact) in random spots of the list
	for starting_roll_result in starting_roll_results:
		var number_of_roll_results = len(roll_results)
		var highest_possible_index = number_of_roll_results
		var new_index = rng.randi_range(0, highest_possible_index)
		if new_index == number_of_roll_results:
			roll_results.append(starting_roll_result)
		else:
			roll_results.insert(new_index, starting_roll_result)

	# get the actual results from the rolled items
	for roll_result in roll_results:
		if roll_result is LootItem:
			final_results.append(roll_result.loot)
		elif roll_result is LootTable:
			var roll_result_roll: Array = roll_result.roll()
			if seperate_nested_loot_tables:
				if use_nested_names:
					roll_result_roll.insert(0, roll_result.loot_table_name)
				final_results.append(roll_result_roll)
				continue
			
			final_results.append_array(roll_result_roll)

	return final_results
