extends RefCounted
class_name NSSaveManager
const PATH = "user://nightshift_v1.json"
const VERSION = 1

static func write(game: Node3D, path: String = PATH) -> Error:
	var objects = {}
	for id in game.registry:
		var obj = game.registry[id] as NSInteractable
		var pos = obj.global_position
		objects[id] = {"position": [pos.x, pos.y, pos.z], "active": not obj.disabled, "scanned": obj.scanned, "occupied_by": obj.occupied_by, "door_open": obj.door_open}
	var p = game.player.global_position
	var data = {"version": VERSION, "minutes": game.time.minutes, "player": [p.x, p.y, p.z], "yaw": game.player.rotation.y, "pitch": game.player.head.rotation.x, "power": game.power_on, "lights": game.lights_on, "tasks": game.tasks.progress, "npc": game.customer.save_state(), "objects": objects, "held": ["", ""], "cctv": game.cctv.channel, "real_shift_minutes": game.time.real_shift_minutes}
	for i in range(2):
		if game.player.held[i]:
			data.held[i] = game.player.held[i].stable_id
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var err = file.get_error()
	file.close()
	if err != OK:
		return err
	# Keep the previous complete save as a recovery copy.
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
	return DirAccess.rename_absolute(path + ".tmp", path)

static func read_into(game: Node3D, path: String = PATH) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return ERR_FILE_CORRUPT
	var data = parser.data
	if not data is Dictionary or int(data.get("version", -1)) != VERSION:
		return ERR_FILE_CORRUPT
	# Validate required containers and numeric fields before changing the live world.
	if not data.get("objects") is Dictionary or not data.get("npc") is Dictionary or not data.get("tasks") is Dictionary:
		return ERR_FILE_CORRUPT
	if not valid_vector(data.get("player")) or not data.get("held") is Array or data.held.size() != 2:
		return ERR_FILE_CORRUPT
	if not data.get("minutes") is float and not data.get("minutes") is int:
		return ERR_FILE_CORRUPT
	for id in game.registry:
		if not data.objects.has(id) or not data.objects[id] is Dictionary or not valid_vector(data.objects[id].get("position")):
			return ERR_FILE_CORRUPT
	for id in data.held:
		if id != "" and (not game.registry.has(id) or game.registry[id].kind != "pickup"):
			return ERR_FILE_CORRUPT
	if data.held[0] != "" and data.held[0] == data.held[1]:
		return ERR_FILE_CORRUPT
	for i in range(2):
		if game.player.held[i]:
			game.player.put(i, Vector3.ZERO)
	for id in game.registry:
		var obj = game.registry[id] as NSInteractable
		var state: Dictionary = data.objects[id]
		if obj.kind == "pickup":
			obj.reparent(game.world) if obj.get_parent() != game.world else null
			obj.global_position = from_array(state.position)
			obj.rotation = Vector3.ZERO
		obj.set_active(state.get("active", true))
		obj.scanned = state.get("scanned", false)
		obj.occupied_by = state.get("occupied_by", "")
		obj.door_open = state.get("door_open", false)
		if obj.kind == "drawer":
			obj.visual.position.z = 0.22 if obj.door_open else 0.0
		if obj.kind == "appliance":
			obj.visual.position.z = -0.6 if obj.door_open else 0.0
		if obj.kind == "door":
			game.set_door(obj, obj.door_open, true)
	for i in range(2):
		if data.held[i] != "":
			game.player.take(game.registry[data.held[i]], i)
	game.player.global_position = from_array(data.player)
	game.player.rotation.y = data.get("yaw", 0.0)
	game.player.head.rotation.x = clampf(data.get("pitch", 0.0), -1.38, 1.25)
	game.player.velocity = Vector3.ZERO
	game.time.minutes = clampf(data.minutes, 0, 420)
	game.time.last_hour = int(game.time.minutes / 60)
	game.time.real_shift_minutes = clampf(data.get("real_shift_minutes", 180), 1, 600)
	game.time.speed = 1.0
	game.time.running = game.time.minutes < 420
	for key in game.tasks.goals:
		game.tasks.progress[key] = clampi(int(data.tasks.get(key, 0)), 0, game.tasks.goals[key])
	game.power_on = data.get("power", true)
	game.lights_on = data.get("lights", true)
	game.apply_lights()
	game.customer.restore(data.npc)
	game.cctv.select(int(data.get("cctv", 0)))
	game.ended = game.time.minutes >= 420
	return OK

static func valid_vector(value: Variant) -> bool:
	if not value is Array or value.size() != 3:
		return false
	for n in value:
		if not (n is float or n is int) or not is_finite(float(n)):
			return false
	return true

static func from_array(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])
