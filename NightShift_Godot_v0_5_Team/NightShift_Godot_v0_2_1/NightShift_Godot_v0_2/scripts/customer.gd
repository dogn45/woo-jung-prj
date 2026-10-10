extends Node3D
class_name NSCustomer

var game: Node3D
var state = "idle"
var waypoint = 0
var next_visit = 1.0
var browse_until = 0.0
var walk_phase = 0.0
var legs: Array = []
var carry: Node3D
var route_in = [Vector3(0, 0, 10), Vector3(0, 0, 5), Vector3(-2.0, 0, 3.8), Vector3(-2.0, 0, -1.5)]
var route_checkout = [Vector3(-2.0, 0, -1.5), Vector3(-2.0, 0, 0.5), Vector3(-3.5, 0, 0.5)]
var route_out = [Vector3(-2, 0, 0.5), Vector3(-2, 0, 4.2), Vector3(0, 0, 5), Vector3(0, 0, 12)]
var collider: StaticBody3D

func _ready() -> void:
	NSGeometry.box(self, Vector3(0, 1.2, 0), Vector3(0.45, 0.6, 0.25), Color("8d7868"), false)
	NSGeometry.box(self, Vector3(0, 1.68, 0), Vector3(0.27, 0.32, 0.25), Color("bb9279"), false)
	NSGeometry.box(self, Vector3(0, 1.85, 0.02), Vector3(0.29, 0.09, 0.28), Color("29333d"), false)
	for s in [-1, 1]:
		var leg = Node3D.new()
		add_child(leg)
		leg.position = Vector3(s * 0.12, 0.9, 0)
		NSGeometry.box(leg, Vector3(0, -0.4, 0), Vector3(0.17, 0.8, 0.2), Color("283542"), false)
		legs.append(leg)
		NSGeometry.box(self, Vector3(s * 0.3, 1.05, 0), Vector3(0.14, 0.63, 0.18), Color("8d7868"), false)
	carry = NSGeometry.box(self, Vector3(0.3, 0.90, -0.2), Vector3(0.18, 0.3, 0.18), Color("b18cac"), false)
	collider = StaticBody3D.new()
	add_child(collider)
	var c = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.28
	c.shape = shape
	c.position.y = 0.9
	collider.add_child(c)
	visible = false
	collider.collision_layer = 0

func _process(delta: float) -> void:
	if game.modal_open or game.ended:
		return
	if state == "idle":
		if game.time.minutes >= next_visit and game.time.minutes < 405:
			state = "enter"
			waypoint = 0
			position = Vector3(0, 0, 12)
			visible = true
			carry.visible = false
			collider.collision_layer = 1
		return
	if state == "browse":
		if game.time.minutes >= browse_until:
			state = "checkout"
			waypoint = 0
			carry.visible = true
		return
	if state == "waiting":
		rotation.y = PI
		return
	var route = route_in if state == "enter" else (route_checkout if state == "checkout" else route_out)
	var destination: Vector3 = route[waypoint]
	var difference = destination - position
	# Stop if the player blocks the immediate walking direction.
	var to_player = game.player.global_position - global_position
	to_player.y = 0
	if to_player.length() < 0.85 and difference.normalized().dot(to_player.normalized()) > 0.3:
		return
	if difference.length() > 0.1:
		position = position.move_toward(destination, delta * 1.15)
		rotation.y = lerp_angle(rotation.y, atan2(-difference.x, -difference.z), delta * 8)
		walk_phase += delta * 6.0
		legs[0].rotation.x = sin(walk_phase) * 0.32
		legs[1].rotation.x = -sin(walk_phase) * 0.32
	else:
		waypoint += 1
		if waypoint >= route.size():
			waypoint = 0
			legs[0].rotation.x = 0
			legs[1].rotation.x = 0
			if state == "enter":
				state = "browse"
				browse_until = game.time.minutes + 0.3
			elif state == "checkout":
				state = "waiting"
				carry.visible = false
				var order = game.registry["order"] as NSInteractable
				order.set_active(true)
				order.global_position = order.home.origin
				order.scanned = false
				game.toast("손님이 기다립니다 · 음료를 들고 스캐너 → POS")
			else:
				state = "idle"
				visible = false
				collider.collision_layer = 0
				next_visit = game.time.minutes + 20.0

func paid() -> void:
	state = "leave"
	waypoint = 0
	carry.visible = true

func save_state() -> Dictionary:
	return {"state": state, "waypoint": waypoint, "next_visit": next_visit, "browse_until": browse_until, "position": [position.x, position.y, position.z], "rotation": rotation.y, "carry": carry.visible}

func restore(data: Dictionary) -> void:
	state = data.get("state", "idle")
	waypoint = int(data.get("waypoint", 0))
	next_visit = float(data.get("next_visit", 1.0))
	browse_until = float(data.get("browse_until", 0.0))
	var p = data.get("position", [0, 0, 12])
	position = Vector3(p[0], p[1], p[2])
	rotation.y = data.get("rotation", 0.0)
	visible = state != "idle"
	collider.collision_layer = 1 if visible else 0
	carry.visible = data.get("carry", false)
