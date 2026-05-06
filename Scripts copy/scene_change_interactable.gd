extends "res://Scripts/interactable_area.gd"

@export var prompt_text := "Press E"
@export_file("*.tscn") var target_scene_path := ""
@export var mark_method_name: StringName
@export var required_method_name: StringName
@export var blocked_prompt_text := "Complete previous task first"


func get_interact_prompt() -> String:
	if not _can_interact(_player_in_range):
		return blocked_prompt_text
	return prompt_text


func interact(player: Node3D) -> void:
	if player == null:
		return
	if not _can_interact(player):
		return
	if target_scene_path.is_empty():
		return

	_clear_player_interactable(player)
	if not String(mark_method_name).is_empty() and player.has_method(mark_method_name):
		player.call(mark_method_name)

	get_tree().change_scene_to_file(target_scene_path)


func _can_interact(player: Node) -> bool:
	return _player_passes_requirement(player, required_method_name)
