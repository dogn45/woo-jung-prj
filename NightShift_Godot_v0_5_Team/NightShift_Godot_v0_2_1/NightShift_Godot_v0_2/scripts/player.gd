extends CharacterBody3D
class_name NSPlayer

var game: Node3D
var head: Node3D
var camera: Camera3D
var ray: RayCast3D
var hands: Array[Node3D] = []
var held: Array = [null, null]
var arms: Array = []
var legs: Array = []
var hand_home = [Vector3(-0.32, -0.30, -0.64), Vector3(0.32, -0.30, -0.64)]
var busy = false
var target: NSInteractable
var stride = 0.0
var foot_timer = 0.0
var bob_enabled = true
var sensitivity = 0.0022

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 0.3
	var shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.26
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = 0.88
	add_child(shape)
	head = Node3D.new()
	add_child(head)
	head.position.y = 1.66
	camera = Camera3D.new()
	head.add_child(camera)
	camera.current = true
	camera.fov = 77
	camera.near = 0.04
	ray = RayCast3D.new()
	camera.add_child(ray)
	ray.target_position = Vector3(0, 0, -2.3)
	ray.collision_mask = 3
	ray.add_exception(self)
	ray.enabled = true
	# Primitive full body: easy to replace with a rigged GLB later.
	NSGeometry.box(self, Vector3(0, 1.17, 0.14), Vector3(0.43, 0.57, 0.26), Color("204a4b"), false)
	NSGeometry.box(self, Vector3(0, 0.85, 0.12), Vector3(0.38, 0.16, 0.25), Color("161e28"), false)
	for side in [-1, 1]:
		var leg = Node3D.new()
		add_child(leg)
		leg.position = Vector3(side * 0.12, 0.85, 0.13)
		NSGeometry.box(leg, Vector3(0, -0.34, 0), Vector3(0.17, 0.68, 0.19), Color("202936"), false)
		NSGeometry.box(leg, Vector3(0, -0.77, -0.08), Vector3(0.19, 0.15, 0.34), Color("10141c"), false)
		legs.append(leg)
		var hand = Node3D.new()
		camera.add_child(hand)
		hand.name = "LeftHoldPoint" if side == -1 else "RightHoldPoint"
		hand.position = hand_home[0 if side == -1 else 1]
		NSGeometry.box(hand, Vector3(0, 0, 0.07), Vector3(0.10, 0.07, 0.15), Color("bb9279"), false)
		for finger in range(4):
			NSGeometry.box(hand, Vector3(-0.034 + finger * 0.023, -0.005, -0.035), Vector3(0.018, 0.035, 0.07), Color("bb9279"), false)
		NSGeometry.box(hand, Vector3(-side * 0.065, -0.005, 0.055), Vector3(0.032, 0.045, 0.065), Color("bb9279"), false)
		hands.append(hand)
		var upper = NSGeometry.cylinder(camera, Vector3.ZERO, 0.065, 1.0, Color("204a4b"))
		var fore = NSGeometry.cylinder(camera, Vector3.ZERO, 0.047, 1.0, Color("bb9279"))
		arms.append([upper, fore])

func _unhandled_input(event: InputEvent) -> void:
	if game.modal_open or game.ended:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * sensitivity, -1.38, 1.25)
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT:
			use_hand(0)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			use_hand(1)

func _physics_process(delta: float) -> void:
	if game.modal_open or game.ended:
		velocity = Vector3.ZERO
		return
	var axis = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
	var direction = transform.basis * Vector3(axis.x, 0, axis.y)
	var speed = 3.6 if Input.is_physical_key_pressed(KEY_SHIFT) else 2.35
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 16)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 16)
	if not is_on_floor():
		velocity.y -= delta * 16.0
	else:
		velocity.y = -0.3
	# Step-up only for an actual low obstacle, with overhead clearance.
	var motion = Vector3(velocity.x, 0, velocity.z) * delta
	if is_on_floor() and motion.length() > 0.001 and test_move(global_transform, motion):
		var raised = global_transform
		raised.origin.y += 0.21
		if not test_move(global_transform, Vector3.UP * 0.21) and not test_move(raised, motion):
			global_position.y += 0.21
	move_and_slide()
	var moving = Vector2(velocity.x, velocity.z).length() > 0.15 and is_on_floor()
	if moving:
		stride += delta * speed * 4.1
		foot_timer += delta * speed
		if foot_timer > 1.15:
			foot_timer = 0.0
			game.play_step(global_position.z > 6 or absf(global_position.x) > 7)
	legs[0].rotation.x = sin(stride) * 0.34 if moving else lerpf(legs[0].rotation.x, 0, delta * 12)
	legs[1].rotation.x = -sin(stride) * 0.34 if moving else lerpf(legs[1].rotation.x, 0, delta * 12)
	camera.position.y = sin(stride * 2) * 0.009 if moving and bob_enabled else 0.0
	for i in range(2):
		var sign_x = -1.0 if i == 0 else 1.0
		var shoulder = Vector3(sign_x * 0.24, -0.28, 0.09)
		var wrist = hands[i].position + Vector3(0, 0, 0.12)
		var elbow = shoulder.lerp(wrist, 0.5) + Vector3(sign_x * 0.10, -0.18, 0.04)
		segment(arms[i][0], shoulder, elbow)
		segment(arms[i][1], elbow, wrist)
	ray.force_raycast_update()
	target = ray.get_collider() as NSInteractable if ray.is_colliding() else null
	if target and target.disabled:
		target = null

func segment(mesh: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var direction = b - a
	mesh.position = (a + b) * 0.5
	mesh.quaternion = Quaternion(Vector3.UP, direction.normalized())
	mesh.scale = Vector3(1, direction.length(), 1)

func use_hand(index: int) -> void:
	if busy or not target:
		return
	var obj = target
	if not game.can_interact(obj, index):
		return
	busy = true
	var point = camera.to_local(ray.get_collision_point())
	point = point.limit_length(1.0)
	var tween = create_tween()
	tween.tween_property(hands[index], "position", point, 0.16).set_trans(Tween.TRANS_SINE)
	await tween.finished
	if is_instance_valid(obj):
		game.interact(obj, index)
	var back = create_tween()
	back.tween_property(hands[index], "position", hand_home[index], 0.22).set_trans(Tween.TRANS_SINE)
	await back.finished
	busy = false

func take(item: NSInteractable, index: int) -> void:
	held[index] = item
	item.collision_layer = 0
	item.reparent(hands[index])
	item.position = Vector3(0, 0, -0.07)
	item.rotation = Vector3.ZERO

func put(index: int, pos: Vector3) -> NSInteractable:
	var item = held[index] as NSInteractable
	if not item:
		return null
	held[index] = null
	item.reparent(game.world)
	item.global_position = pos
	item.rotation = Vector3.ZERO
	item.collision_layer = 3
	return item
