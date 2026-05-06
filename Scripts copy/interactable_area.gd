extends Area3D

const PLAYER_NAME := "Player_S"

var _player_in_range: Node = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body == null or body.name != PLAYER_NAME:
		return
	_player_in_range = body
	_player_entered(body)
	if body.has_method("set_current_interactable"):
		body.set_current_interactable(self)


func _on_body_exited(body: Node) -> void:
	if body == null or body != _player_in_range:
		return
	_player_exited(body)
	if body.has_method("clear_current_interactable"):
		body.clear_current_interactable(self)
	_player_in_range = null


func _player_entered(_player: Node) -> void:
	pass


func _player_exited(_player: Node) -> void:
	pass


func _clear_player_interactable(player: Node) -> void:
	if player and player.has_method("clear_current_interactable"):
		player.clear_current_interactable(self)


func _player_passes_requirement(player: Node, required_method_name: StringName) -> bool:
	if String(required_method_name).is_empty():
		return true
	if player == null or not player.has_method(required_method_name):
		return false
	return bool(player.call(required_method_name))


func _teleport_player(player: Node3D, position: Vector3) -> void:
	if player == null:
		return
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.global_position = position
	player.set_deferred("global_position", position)
