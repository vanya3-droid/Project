extends Node3D


func _ready() -> void:
	_add_collisions_recursive(self)


func _add_collisions_recursive(node: Node) -> void:
	for child in node.get_children():
		_add_collisions_recursive(child)

	if node is MeshInstance3D and not _has_collision_child(node):
		node.create_trimesh_collision()


func _has_collision_child(node: Node) -> bool:
	for child in node.get_children():
		if child is StaticBody3D or child is CollisionShape3D:
			return true
	return false
