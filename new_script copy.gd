extends Area3D

@export var target_position := Vector3(-11.1, 2.2, 18.5)
@export var prompt_text := "Press E to enter the room"

var _player_in_range: Node = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func get_interact_prompt() -> String:
	return prompt_text


func interact(player: Node3D) -> void:
	if player == null:
		return
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.global_position = target_position


func _on_body_entered(body: Node) -> void:
	if body == null or body.name != "Player_S":
		return
	_player_in_range = body
	if body.has_method("set_current_interactable"):
		body.set_current_interactable(self)


func _on_body_exited(body: Node) -> void:
	if body == null or body != _player_in_range:
		return
	if body.has_method("clear_current_interactable"):
		body.clear_current_interactable(self)
	_player_in_range = null
