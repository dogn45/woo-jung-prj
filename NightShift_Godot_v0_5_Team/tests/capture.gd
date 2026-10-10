extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/menu.png")
	game.resume()
	game.time.running = false
	game.customer.set_process(false)
	game.player.head.rotation.x = -0.13
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/counter.png")
	game.player.position = Vector3(1.0, 0.04, 4.6)
	game.player.rotation.y = 0
	game.player.head.rotation.x = -0.10
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/store.png")
	game.player.position = Vector3(3, 0.04, 12)
	game.player.rotation.y = 0.22
	game.player.head.rotation.x = 0.1
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/outside.png")
	game.show_help()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/help.png")
	game.stop_audio()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	quit()
