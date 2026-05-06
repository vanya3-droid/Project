extends "res://Scripts/interactable_area.gd"

@export var prompt_text := "Press E"
@export var target_path: NodePath


func get_interact_prompt() -> String:
	return prompt_text


func interact(player: Node3D) -> void:
	if player == null:
		return

	var target: Node3D = get_node_or_null(target_path) as Node3D
	if target == null:
		return

	_teleport_player(player, target.global_position)
