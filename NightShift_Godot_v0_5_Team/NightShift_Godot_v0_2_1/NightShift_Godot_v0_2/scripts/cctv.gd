extends Node
class_name NSCCTV
var game: Node3D
var viewport: SubViewport
var camera: Camera3D
var stamp: Label
var channel = 0
var tick = 0.0
var stations = [Vector3(4.8, 2.7, 5.6), Vector3(-6.4, 2.9, -4.5), Vector3(6.8, 3.0, 6.5), Vector3(-6.5, 2.6, -8.5), Vector3(9, 3, -8)]
var targets = [Vector3(0, 1, 8), Vector3(0, 0.9, 2), Vector3(0, 0.5, 11), Vector3(-2, 1, -6), Vector3(7.8, 0.6, 0)]

func setup(owner_game: Node3D) -> void:
	game = owner_game
	viewport = SubViewport.new()
	add_child(viewport)
	viewport.size = Vector2i(480, 270)
	viewport.world_3d = game.get_world_3d()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	camera = Camera3D.new()
	viewport.add_child(camera)
	camera.fov = 85
	camera.current = true
	camera.cull_mask = 1
	var canvas = CanvasLayer.new()
	viewport.add_child(canvas)
	stamp = Label.new()
	canvas.add_child(stamp)
	stamp.position = Vector2(13, 10)
	stamp.add_theme_font_size_override("font_size", 17)
	stamp.add_theme_color_override("font_color", Color("b5f7d6"))
	var overlay = ColorRect.new()
	canvas.add_child(overlay)
	overlay.size = Vector2(480, 270)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader = Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ float n=fract(sin(dot(UV+vec2(TIME),vec2(12.9898,78.233)))*43758.5453); float s=step(0.55,fract(UV.y*135.0)); COLOR=vec4(vec3(n),0.028+s*0.045); }"
	var mat = ShaderMaterial.new()
	mat.shader = shader
	overlay.material = mat
	var monitor: NSInteractable = game.make_interactable("cctv", "CCTV · 다음 카메라", "cctv", Vector3(-3.45, 1.55, 3.3), Vector3(0.98, 0.61, 0.10), Color("112329"))
	var screen = MeshInstance3D.new()
	monitor.add_child(screen)
	screen.position.z = 0.056
	var quad = QuadMesh.new()
	quad.size = Vector2(0.88, 0.50)
	screen.mesh = quad
	screen.layers = 2 # exclude monitor from its own camera to prevent recursion
	var screen_mat = StandardMaterial3D.new()
	screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen_mat.albedo_texture = viewport.get_texture()
	screen.material_override = screen_mat
	var monitor_pos: Vector3 = monitor.global_position
	NSGeometry.box(game.world, monitor_pos + Vector3(0, -0.39, 0), Vector3(0.3, 0.25, 0.2), Color("112329"))
	NSGeometry.box(game.world, monitor_pos + Vector3(0, -1.10, 0), Vector3(1.1, 0.9, 0.6), Color("405259"))
	select(0)

func select(index: int) -> void:
	channel = posmod(index, stations.size())
	camera.position = stations[channel]
	camera.look_at(targets[channel])
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _process(delta: float) -> void:
	tick += delta
	if tick > 0.10:
		tick = 0.0
		stamp.text = "● REC   CAM %02d\n2026-10-09  %s" % [channel + 1, game.time.clock()]
		# Display one active camera at 10 fps, not five concurrent world renders.
		if game.power_on and game.player.global_position.distance_to(Vector3(-3.45, 1.55, 3.3)) < 9:
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		elif not game.power_on:
			stamp.text = "SIGNAL LOST / POWER OFF"
			camera.cull_mask = 0
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		if game.power_on:
			camera.cull_mask = 1
