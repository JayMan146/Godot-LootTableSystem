extends Node

var chest: Node
var loot_table: LootTable
var uses_names: bool


func _ready() -> void:
	chest = get_parent()
	if chest:
		loot_table = chest.get_node("LootTable")
		if loot_table:
			uses_names = loot_table.use_nested_names


func _on_chest_body_entered(body: Node2D) -> void:
	#print("area entered by {name}".format({"name": body.name}))
	if not body.is_in_group("player"):
		return

	if loot_table:
		print("Opening {name}".format({"name": chest.name}))
		print(loot_table.description + "\n")
		var output: Array = loot_table.roll()
		recursively_print_chest_output(output)
	else:
		print("No Loot Table present on chest.")


func print_with_bullet_points(to_print: String, number_of_spaces: int, character: String="-") -> void:
	var bullet_point_string: String = ""
	for i in range(number_of_spaces - 1):
		bullet_point_string += " "
	bullet_point_string += character
	print("{bullet_point_string} {to_print}".format({"bullet_point_string": bullet_point_string, "to_print": to_print}))


func recursively_print_chest_output(output: Array, depth: int=1) -> void:
	for item in output:
		if item is String:
			print_with_bullet_points(item, depth)
		else:
			var to_use: Array = item.duplicate()
			if uses_names:
				print_with_bullet_points(item[0], depth, ">")
				to_use = to_use.slice(1)
			recursively_print_chest_output(to_use, depth + 1)
		