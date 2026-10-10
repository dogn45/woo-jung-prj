extends RefCounted
class_name NSGeometry

static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.72
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = true, glow: float = 0.0) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	parent.add_child(root)
	root.position = pos
	var mesh = MeshInstance3D.new()
	var shape = BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color, glow)
	root.add_child(mesh)
	if solid:
		var c = CollisionShape3D.new()
		var s = BoxShape3D.new()
		s.size = size
		c.shape = s
		root.add_child(c)
	return root

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 12
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

static func text(parent: Node3D, value: String, pos: Vector3, size: int = 40, color: Color = Color.WHITE) -> Label3D:
	var l = Label3D.new()
	parent.add_child(l)
	var font = FontVariation.new()
	font.base_font = load("res://assets/NotoSansKR.ttf")
	font.variation_opentype = {"wght": 600}
	font.variation_embolden = 0.7
	l.font = font
	l.text = value
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = color
	l.no_depth_test = false
	l.outline_size = 3
	return l

static func light(parent: Node3D, pos: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var l = OmniLight3D.new()
	parent.add_child(l)
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = radius
	l.shadow_enabled = false
	return l
