## Insane Routine

A Godot 4.6 third-person task game prototype. The player explores a small 3D environment, completes objectives in order, collects objects through proximity interaction, and eventually enters the university area through a scene transition.

## Project Overview

The game is built around a simple objective chain shown in the on-screen `Task to do` panel:

1. Collect the book
2. Take the can
3. Eat breakfast
4. Enter University

Tasks must be completed in this order. Later interactions are blocked until the required earlier tasks are done, so the player cannot collect the can before the book, eat breakfast before collecting the book and can, or enter the university before completing the previous objectives.

## Submission Links


Itch.io page: https://wallyxo.itch.io/insane-routine-0

Repository: https://github.com/vanya3-droid


## Controls

| Action | Input |
| --- | --- |
| Move | `W`, `A`, `S`, `D` |
| Jump | `Space` |
| Look around | Mouse |
| Interact | `E` |
| Capture mouse | Left mouse button |
| Release mouse | `Esc` |

## Gameplay

The player starts in the 3D scene with a third-person camera. The camera follows `Player_S` through a pivot and spring arm setup, so it stays behind the character and avoids clipping into collision objects.

Interactive objects use radius-based `Area3D` detection. When the player is close enough, a white UI prompt appears at the bottom of the screen. Pressing `E` triggers the interaction if the task order allows it.

The collectible objects currently include:

| Object | Scene Node | Behavior |
| --- | --- | --- |
| Book | `BookPickup` | Highlights red, lifts upward, disappears, marks `Collect the book` complete |
| Can | `CanInteract` | Highlights red, lifts upward, disappears, marks `Take the can` complete |
| Breakfast food | `food_dinner2` | Highlights red, plays optional pickup sound, lifts upward, disappears |
| Breakfast cheese | `food_ingredient_cheese` or `food_ingredient_cheese2` | Highlights red, plays optional pickup sound, lifts upward, disappears |
| Box teleporter | `Box_C2` | Teleports the player back into the room |
| University trigger | `Box_C3` | Changes scene to `res://node_2d.tscn` after all previous tasks are complete |

The breakfast task is completed only after both breakfast objects have been collected.

## Scenes

| Scene | Purpose |
| --- | --- |
| `res://Addons/node_3d.tscn` | Main playable 3D scene |
| `res://Scripts/player_s.tscn` | Player character, camera, task UI, and interaction UI |
| `res://node_2d.tscn` | End / thank-you screen reached from `Box_C3` |
| `res://Scenes/university_scene.tscn` | Extra prototype university scene |
| `res://Scenes/building_square.tscn` | Earlier prototype scene for the building layout |

## Main Systems

### Player Controller

File:

```text
res://Scripts/skeleton_3d.gd
```

Responsibilities:

- Handles movement, jumping, gravity, and character rotation.
- Controls the camera pivot and mouse look.
- Plays movement, idle, and jump animations when available.
- Shows the bottom interaction prompt.
- Updates the `Task to do` UI.
- Enforces the required order of tasks.
- Syncs progress from the global `GameState`.

### Task State

File:

```text
res://Scripts/game_state.gd
```

This script is loaded as an autoload singleton named `GameState`. It stores task completion so progress can survive scene changes.

Tracked values:

- `book_collected`
- `can_collected`
- `breakfast_dinner_collected`
- `breakfast_cheese_collected`
- `university_entered`

### Pickup Interaction

File:

```text
res://Scripts/book_pickup_interactable.gd
```

This is a reusable pickup script used by the book, can, and breakfast objects. It supports:

- Proximity interaction through `Area3D`
- Red object highlight
- Optional sound playback
- Small upward pickup animation
- Object removal after collection
- Task-order requirements through `required_method_name`
- Blocked prompt text when the player tries to interact too early

### Scene Change Interaction

File:

```text
res://Scripts/scene_change_interactable.gd
```

This script is used by `Box_C3`. It changes to another scene when the player presses `E`, but only if the required task condition is met.

Current target:

```text
res://node_2d.tscn
```

### Teleport Interaction

File:

```text
res://Scripts/teleport_interactable.gd
```

This script is used by `Box_C2`. It moves the player to a target `Marker3D`, currently `RoomEnterTarget`.

### Collision Setup

File:

```text
res://Addons/buildings_collision_setup.gd
```

This helper automatically adds trimesh collisions to mesh objects inside containers such as `Buildings` and `Room`.

## Task Order Logic

The task order is enforced by methods on `Player_S`:

```gdscript
func can_collect_book() -> bool:
	return true

func can_collect_can() -> bool:
	return _book_collected

func can_collect_breakfast() -> bool:
	return _book_collected and _can_collected

func can_enter_university() -> bool:
	return _book_collected and _can_collected and _breakfast_dinner_collected and _breakfast_cheese_collected
```

Interactive objects call these methods before allowing the action. If the method returns `false`, the UI shows a blocked message instead of completing the task.

## UI

The project uses two main UI panels inside `res://Scripts/player_s.tscn`:

- `TaskUI`: shows the objective list in the top-left corner.
- `InteractUI`: shows a bottom-screen prompt such as `Press E to pick up the can`.

Completed tasks receive a green check mark in the task list.

## Assets

The project uses imported 3D assets from the repository folders:

- `res://Models/gltf`
- `res://KayKit_Restaurant_Bits_1.0_FREE`

These include buildings, room furniture, food props, cans, a book model, a character model, and environment props.

## Audio

The main scene includes background music through `AudioStreamPlayer`.

Assign an audio file to this exported field in the Godot Inspector to play a sound when breakfast objects are collected.

## How To Add A New Ordered Task

1. Add a new task state variable to `GameState`.
2. Add a matching local variable in `skeleton_3d.gd`.
3. Add a `can_do_task_name()` method for the prerequisite rule.
4. Add a `mark_task_name()` method to mark it complete.
5. Add the task text to `update_task_ui()`.
6. Attach `book_pickup_interactable.gd`, `teleport_interactable.gd`, or `scene_change_interactable.gd` to the object that should trigger the task.
7. Set `required_method_name` and `blocked_prompt_text` in the Inspector or `.tscn` file.

## Known Notes

- `food_ingredient_cheese` and `food_ingredient_cheese2` are both supported because Godot may rename duplicated scene nodes automatically.
- The project currently contains older prototype scenes and scripts that are not the main gameplay path.
- If changes do not appear in the editor, close and reopen the scene from the Godot FileSystem panel or restart the editor.
- The main playable path is `Addons/node_3d.tscn` to `node_2d.tscn`.

## Credits

Credits:

Game project: made by Ivan Yarovyi
3D room scene: made by Ivan Yarovyi
Building environment: made by Ivan Yarovyi
Player movement: made by Ivan Yarovyi
Third-person camera: made by Ivan Yarovyi
Task system: made by Ivan Yarovyi
Ordered task progression: made by Ivan Yarovyi
Book pickup interaction: made by Ivan Yarovyi
Can pickup interaction: made by Ivan Yarovyi
Breakfast interaction: made by Ivan Yarovyi
Scene transition to node_2d: made by Ivan Yarovyi
UI prompts and task list: made by Ivan Yarovyi
Collision setup: made by Ivan Yarovyi
README documentation: made by Ivan Yarovyi
Imported 3D assets: used for educational prototyping from asset packs.
