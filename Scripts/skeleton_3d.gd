extends CharacterBody3D

const PICKUP_INTERACT_SCRIPT := preload("res://Scripts/book_pickup_interactable.gd")
const TASK_BOOK := &"book_collected"
const TASK_CAN := &"can_collected"
const TASK_BREAKFAST_DINNER := &"breakfast_dinner_collected"
const TASK_BREAKFAST_CHEESE := &"breakfast_cheese_collected"
const TASK_UNIVERSITY := &"university_entered"
const ANIMATION_ALIASES := {
	"idle": ["Idle_B", "idle", "Idle", "Idle_1", "Idle_A"],
	"Running_C": ["Running_C", "Run", "Running", "Walk", "Walking", "Walking_A", "Walking_B", "Walking_Backwards"],
	"Jump_Start": ["Jump_Start", "Jump", "Jump_Up", "Jump_Idle"],
	"Jump_Land": ["Jump_Land", "Fall", "Landing", "Land"]
}

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0
@export var jump_impulse := 12.0

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 8.0

@export_group("Interaction")
@export var breakfast_pickup_sound: AudioStream
@export var breakfast_pickup_size := Vector3(2.5, 1.5, 2.5)

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
var _gravity := -30.0
var _current_interactable: Node = null

@onready var _camera_pivot: Node3D = %Camera
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: Node3D = %Skeleton_Minion
@onready var _animation_player: AnimationPlayer = find_animation_player(_skin)
@onready var _interact_label: Label = %InteractLabel
@onready var _interact_panel: Control = %InteractPanel
@onready var _task_label: RichTextLabel = %TaskLabel
@onready var _game_state: Node = get_node_or_null("/root/GameState")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _interact_label and _interact_panel:
		_interact_label.visible = true
		_interact_panel.visible = false
	update_task_ui()
	call_deferred("_setup_breakfast_pickups")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity

	if event.is_action_pressed("interact"):
		if _current_interactable and _current_interactable.has_method("interact"):
			_current_interactable.interact(self)


func _physics_process(delta: float) -> void:
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta

	_camera_input_direction = Vector2.ZERO

	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	velocity.y = y_velocity + _gravity * delta

	var is_starting_jump := Input.is_action_just_pressed("jump") and is_on_floor()
	if is_starting_jump:
		velocity.y += jump_impulse

	move_and_slide()

	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction

	if _skin:
		var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
		_skin.rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

	if is_starting_jump:
		play_skin_animation("Jump_Start")
	elif not is_on_floor() and velocity.y < 0.0:
		play_skin_animation("Jump_Land")
	elif is_on_floor():
		var ground_speed := Vector2(velocity.x, velocity.z).length()
		if ground_speed > 0.1:
			play_skin_animation("Running_C")
		else:
			play_skin_animation("idle")

	update_interact_prompt()


func play_skin_animation(animation_name: String) -> void:
	if _skin and _skin.has_method(animation_name):
		_skin.call(animation_name)
		return

	if _animation_player:
		var candidates: Array = ANIMATION_ALIASES.get(animation_name, [animation_name])
		for candidate in candidates:
			var candidate_name := str(candidate)
			if _animation_player.has_animation(candidate_name):
				if _animation_player.current_animation != candidate_name:
					_animation_player.play(candidate_name)
				return


func find_animation_player(root: Node) -> AnimationPlayer:
	if root == null:
		return null
	if root is AnimationPlayer:
		return root
	for child in root.get_children():
		var animation_player := find_animation_player(child)
		if animation_player:
			return animation_player
	return null


func update_interact_prompt() -> void:
	if _interact_label == null:
		return

	if _current_interactable and _current_interactable.has_method("get_interact_prompt"):
		_interact_label.text = str(_current_interactable.get_interact_prompt())
		_interact_label.visible = true
		_interact_panel.visible = true
	else:
		_interact_label.visible = true
		_interact_panel.visible = false


func set_current_interactable(interactable: Node) -> void:
	_current_interactable = interactable
	update_interact_prompt()


func clear_current_interactable(interactable: Node) -> void:
	if _current_interactable == interactable:
		_current_interactable = null
	update_interact_prompt()


func can_collect_book() -> bool:
	return true


func can_collect_can() -> bool:
	return _task_done(TASK_BOOK)


func can_collect_breakfast() -> bool:
	return _task_done(TASK_BOOK) and _task_done(TASK_CAN)


func can_enter_university() -> bool:
	return can_collect_breakfast() and _breakfast_done()


func mark_book_collected() -> void:
	_complete_task(TASK_BOOK)


func mark_can_collected() -> void:
	_complete_task(TASK_CAN)


func mark_breakfast_dinner_collected() -> void:
	_complete_task(TASK_BREAKFAST_DINNER)


func mark_breakfast_cheese_collected() -> void:
	_complete_task(TASK_BREAKFAST_CHEESE)


func mark_enter_university() -> void:
	_complete_task(TASK_UNIVERSITY)


func update_task_ui() -> void:
	if _task_label == null:
		return
	var task_lines: Array[String] = [
		_task_line("Collect the book", _task_done(TASK_BOOK)),
		_task_line("Take the can", _task_done(TASK_CAN)),
		_task_line("Eat breakfast", _breakfast_done()),
		_task_line("Enter University", _task_done(TASK_UNIVERSITY))
	]
	_task_label.text = "[font_size=84][b]Task to do:[/b][/font_size]\n[font_size=42]%s[/font_size]" % "\n".join(PackedStringArray(task_lines))


func _complete_task(task_name: StringName) -> void:
	if _game_state:
		_game_state.set(task_name, true)
	update_task_ui()


func _task_done(task_name: StringName) -> bool:
	if _game_state == null:
		return false
	return bool(_game_state.get(task_name))


func _breakfast_done() -> bool:
	return _task_done(TASK_BREAKFAST_DINNER) and _task_done(TASK_BREAKFAST_CHEESE)


func _task_line(text: String, completed: bool) -> String:
	return "[color=#2f9e44]✓[/color] %s" % text if completed else text


func _setup_breakfast_pickups() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	_setup_named_pickup(current_scene, "food_dinner2", &"mark_breakfast_dinner_collected")
	_setup_named_pickup(current_scene, "food_ingredient_cheese", &"mark_breakfast_cheese_collected")
	_setup_named_pickup(current_scene, "food_ingredient_cheese2", &"mark_breakfast_cheese_collected")


func _setup_named_pickup(root: Node, node_name: String, collect_method: StringName) -> void:
	var target: Node3D = _find_node3d_by_name(root, node_name)
	if target == null:
		return
	if target.has_node("AutoPickupInteract"):
		return

	var interact_area: Area3D = Area3D.new()
	interact_area.name = "AutoPickupInteract"
	interact_area.collision_mask = 2
	interact_area.script = PICKUP_INTERACT_SCRIPT
	interact_area.set("prompt_text", "Press E to eat breakfast")
	interact_area.set("collect_method_name", collect_method)
	interact_area.set("required_method_name", &"can_collect_breakfast")
	interact_area.set("blocked_prompt_text", "Finish Book and Can first")
	interact_area.set("highlight_target_path", NodePath(".."))
	interact_area.set("pickup_root_path", NodePath(".."))
	interact_area.set("audio_player_path", NodePath("../PickupSound"))
	interact_area.set("play_pickup_animation", true)
	target.add_child(interact_area)
	interact_area.owner = target.owner

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = breakfast_pickup_size
	collision_shape.shape = box_shape
	interact_area.add_child(collision_shape)
	collision_shape.owner = target.owner

	var pickup_sound := target.get_node_or_null("PickupSound") as AudioStreamPlayer3D
	if pickup_sound == null:
		pickup_sound = AudioStreamPlayer3D.new()
		pickup_sound.name = "PickupSound"
		target.add_child(pickup_sound)
		pickup_sound.owner = target.owner
	pickup_sound.stream = breakfast_pickup_sound


func _find_node3d_by_name(root: Node, target_name: String) -> Node3D:
	if root is Node3D and root.name == target_name:
		return root as Node3D
	for child in root.get_children():
		var found: Node3D = _find_node3d_by_name(child, target_name)
		if found:
			return found
	return null
