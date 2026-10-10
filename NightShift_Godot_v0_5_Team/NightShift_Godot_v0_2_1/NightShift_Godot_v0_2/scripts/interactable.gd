extends StaticBody3D
class_name NSInteractable

var stable_id = ""
var title = ""
var kind = "use"
var item_type = ""
var occupied_by = ""
var scanned = false
var door_open = false
var disabled = false
var home = Transform3D.IDENTITY
var pivot: Node3D
var visual: Node3D
var size = Vector3.ONE

func setup(id: String, label: String, action: String, dimensions: Vector3, color: Color) -> void:
	stable_id = id
	title = label
	kind = action
	size = dimensions
	collision_layer = 3
	collision_mask = 1
	var c = CollisionShape3D.new()
	var s = BoxShape3D.new()
	s.size = size
	c.shape = s
	add_child(c)
	visual = NSGeometry.box(self, Vector3.ZERO, size, color, false)

func set_active(active: bool) -> void:
	disabled = not active
	visible = active
	collision_layer = 3 if active else 0

func prompt() -> String:
	if kind == "door":
		return title + (" · 닫기" if door_open else " · 열기")
	if kind == "pickup":
		return title + " · 집기"
	if kind == "slot":
		return title + (" · 비어 있음 / 내려놓기" if occupied_by == "" else " · 진열됨")
	return title
