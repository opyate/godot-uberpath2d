extends Node2D

@onready var path: Path2D = $UberPath2D


func _ready():
	$run_again.button_up.connect(on_run_again)
	on_run_again()


func on_run_again():
	$run_again.disabled = true
	for child in $container.get_children():
		child.queue_free()
	
	set_sprite_position($bottom_left_sprite, $bottom_left_rect.get_rect(), Vector2i(0,1))
	set_sprite_position($bottom_right_sprite, $bottom_right_rect.get_rect(), Vector2i.ONE)
	set_sprite_position($top_left_sprite, $top_left_rect.get_rect(), Vector2i.ZERO)
	set_sprite_position($top_right_sprite, $top_right_rect.get_rect(), Vector2i(1,0))
	
	await get_tree().create_timer(1.0).timeout

	move_inside_rect($bottom_left_sprite, $bottom_left_rect.get_rect(), Vector2i(0,1))
	move_inside_rect($bottom_right_sprite, $bottom_right_rect.get_rect(), Vector2i.ONE)
	move_inside_rect($top_left_sprite, $top_left_rect.get_rect(), Vector2i.ZERO)
	move_inside_rect($top_right_sprite, $top_right_rect.get_rect(), Vector2i(1,0))
	
	await get_tree().create_timer(3.5).timeout
	$run_again.disabled = false


func set_sprite_position(sprite: Sprite2D, rect: Rect2, start_corner: Vector2i):
	match start_corner:
		Vector2i.ZERO:  # top left
			sprite.position = rect.position
		Vector2i.ONE:  # bottom right
			sprite.position = Vector2(rect.end)
		Vector2i(0, 1):  # bottom left
			sprite.position = rect.position + Vector2(0.0, rect.size.y)
		Vector2i(1, 0):  # top right
			sprite.position = rect.position + Vector2(rect.size.x, 0.0)
		_:
			print("WARNING unhandled corner")


func move_inside_rect(sprite: Sprite2D, rect: Rect2, start_corner: Vector2i):
	var path_follow_2d: PathFollow2D = UberPath2D.get_bounded_path_follow_2d($container, sprite.get_path(), path.normalized_points, rect, start_corner)

	await create_tween()\
		.tween_property(path_follow_2d, "progress_ratio", 1.0, 3.5).finished

var count = 0.0
func _physics_process(delta):
	if $run_again.disabled:
		count += delta
		if count >= 0.1:
			for sp in [$bottom_left_sprite, $bottom_right_sprite, $top_left_sprite, $top_right_sprite]:
				var sp_clone = $bottom_left_sprite.duplicate(0)
				sp_clone.scale = Vector2(0.5, 0.5)
				$container.add_child(sp_clone)
			count = 0.0
	else:
		# reset
		count = 0.0
