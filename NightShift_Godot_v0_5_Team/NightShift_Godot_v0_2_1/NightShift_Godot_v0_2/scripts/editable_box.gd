@tool
extends StaticBody3D
class_name NSEditableBox

@export var box_size: Vector3 = Vector3.ONE:
	set(value):
		box_size = value
		_refresh()
@export var box_color: Color = Color(0.7, 0.7, 0.7, 1.0):
	set(value):
		box_color = value
		_refresh()
@export var solid: bool = true:
	set(value):
		solid = value
		_refresh()
@export_range(0.0, 8.0, 0.1) var glow: float = 0.0:
	set(value):
		glow = value
		_refresh()

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	if not is_inside_tree():
		return
	var mesh_instance := get_node_or_null("_Mesh") as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "_Mesh"
		add_child(mesh_instance)
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = box_color
	material.roughness = 0.68
	if box_color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = box_color
		material.emission_energy_multiplier = glow
	mesh_instance.material_override = material

	var collision := get_node_or_null("_Collision") as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = "_Collision"
		add_child(collision)
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	collision.disabled = not solid
	collision_layer = 1 if solid else 0
	collision_mask = 1
