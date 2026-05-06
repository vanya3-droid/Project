extends "res://Scripts/interactable_area.gd"

@export var target_position := Vector3(-5, -0.1, -10.2)
@export var prompt_text := "Press E to leave the room"


func get_interact_prompt() -> String:
	return prompt_text


func interact(player: Node3D) -> void:
	if player == null:
		return
	_teleport_player(player, target_position)
