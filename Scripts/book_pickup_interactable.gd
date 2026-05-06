extends "res://Scripts/interactable_area.gd"

@export var prompt_text := "Press E to pick up the book"
@export var collect_method_name: StringName = &"mark_book_collected"
@export var required_method_name: StringName
@export var blocked_prompt_text := "Complete previous task first"
@export var highlight_target_path: NodePath
@export var pickup_root_path: NodePath
@export var audio_player_path: NodePath
@export var play_pickup_animation := false
@export var lift_distance := 0.35
@export var lift_duration := 0.18

var _highlight_target: Node = null
var _pickup_root: Node = null
var _audio_player: AudioStreamPlayer3D = null
var _mesh_instances: Array[MeshInstance3D] = []
var _highlight_material: StandardMaterial3D = StandardMaterial3D.new()


func _ready() -> void:
	super._ready()

	_highlight_target = get_node_or_null(highlight_target_path)
	_pickup_root = get_node_or_null(pickup_root_path)
	_audio_player = get_node_or_null(audio_player_path) as AudioStreamPlayer3D
	_collect_mesh_instances(_highlight_target)

	_highlight_material.albedo_color = Color(1.0, 0.25, 0.25, 0.85)
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color(0.9, 0.1, 0.1, 1.0)
	_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func get_interact_prompt() -> String:
	if not _can_interact(_player_in_range):
		return blocked_prompt_text
	return prompt_text


func interact(player: Node3D) -> void:
	if player == null or not _can_interact(player):
		return
	_clear_player_interactable(player)
	if player.has_method(collect_method_name):
		player.call(collect_method_name)
	monitoring = false
	_set_highlighted(false)
	_play_pickup_sound()
	if _pickup_root:
		await _animate_and_remove_pickup_root()
	else:
		queue_free()


func _player_entered(_body: Node) -> void:
	_set_highlighted(true)


func _player_exited(_body: Node) -> void:
	_set_highlighted(false)


func _set_highlighted(enabled: bool) -> void:
	var valid_meshes: Array[MeshInstance3D] = []
	for mesh_instance in _mesh_instances:
		if not is_instance_valid(mesh_instance):
			continue
		mesh_instance.material_overlay = _highlight_material if enabled else null
		valid_meshes.append(mesh_instance)
	_mesh_instances = valid_meshes


func _can_interact(player: Node) -> bool:
	return _player_passes_requirement(player, required_method_name)


func _collect_mesh_instances(node: Node) -> void:
	if node == null:
		return
	if node is MeshInstance3D:
		_mesh_instances.append(node)
	for child in node.get_children():
		_collect_mesh_instances(child)


func _play_pickup_sound() -> void:
	if _audio_player == null or _audio_player.stream == null:
		return
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	var temp_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	current_scene.add_child(temp_player)
	temp_player.stream = _audio_player.stream
	temp_player.bus = _audio_player.bus
	temp_player.volume_db = _audio_player.volume_db
	temp_player.pitch_scale = _audio_player.pitch_scale
	temp_player.max_distance = _audio_player.max_distance
	temp_player.unit_size = _audio_player.unit_size
	temp_player.global_position = _audio_player.global_position
	temp_player.finished.connect(temp_player.queue_free)
	temp_player.play()


func _animate_and_remove_pickup_root() -> void:
	var pickup_root_node: Node = _pickup_root
	if pickup_root_node == null:
		queue_free()
		return
	if play_pickup_animation and pickup_root_node is Node3D:
		var pickup_root_3d: Node3D = pickup_root_node as Node3D
		var tween: Tween = create_tween()
		tween.tween_property(
			pickup_root_3d,
			"position:y",
			pickup_root_3d.position.y + lift_distance,
			lift_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished
	pickup_root_node.queue_free()
