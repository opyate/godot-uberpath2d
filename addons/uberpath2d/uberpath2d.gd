@tool
class_name UberPath2D
extends Path2D

# SmoothPath credit Dlean Jeans:
# https://ask.godotengine.org/32506/how-to-draw-a-curve-in-2d?show=57123#a57123

@export var spline_length: float = 100


@warning_ignore("unused_private_class_variable")
@export var _smooth: bool:
	set(value):
		if not value: return

		var point_count = curve.get_point_count()
		for i in point_count:
			var spline = _get_spline(i)
			curve.set_point_in(i, -spline)
			curve.set_point_out(i, spline)


@warning_ignore("unused_private_class_variable")
@export var _straighten: bool:
	set(value):
		if not value: return
		for i in curve.get_point_count():
			curve.set_point_in(i, Vector2())
			curve.set_point_out(i, Vector2())


var normalized_points: PackedVector2Array:
	get:
		var points = curve.get_baked_points()
		return _normalize_points(points)


func _get_spline(i):
	var last_point = _get_point(i - 1)
	var next_point = _get_point(i + 1)
	var spline = last_point.direction_to(next_point) * spline_length
	return spline


func _get_point(i):
	var point_count = curve.get_point_count()
	i = wrapi(i, 0, point_count - 1)
	return curve.get_point_position(i)


func _draw():
	var points = curve.get_baked_points()
	if points:
		draw_polyline(points, Color.BLACK, 8, true)



static func _shift_points(points: PackedVector2Array) -> PackedVector2Array:
	"""Shift points so that at least one of the X and Y values in any point is 0.
	
	This also ensures all points are positive.
	"""
	var min_point: Vector2 = _get_min_x_and_y(points)
	
	var _shifted_points: PackedVector2Array = []
	for point in points:
		var shifted_point = Vector2(point.x - min_point.x, point.y - min_point.y)
		_shifted_points.append(shifted_point)
	
	return _shifted_points


static func _get_min_x_and_y(points: PackedVector2Array) -> Vector2:
	"""Given points, return a vec representing the smallest X and smallest Y
	from the points.
	"""
	var min_x = INF
	var min_y = INF
	for point in points:
		if min_x > point.x:
			min_x = point.x
		if min_y > point.y:
			min_y = point.y
	return Vector2(min_x, min_y)


static func _get_max_x_and_y(points: PackedVector2Array) -> Vector2:
	"""Given points, return a vec representing the largest X and largest Y
	from the points.
	"""
	var max_x = -INF
	var max_y = -INF
	for point in points:
		if max_x < point.x:
			max_x = point.x
		if max_y < point.y:
			max_y = point.y
	return Vector2(max_x, max_y)


static func _normalize_points(points: PackedVector2Array):
	"""Normalizes all points to the range (0,0)->(1,1)
	"""
	var _shifted_points: PackedVector2Array = _shift_points(points)
	var max_point: Vector2 = _get_max_x_and_y(_shifted_points)
	var _normalized_points: PackedVector2Array = []
	for point in _shifted_points:
		var normalized_point = point / max_point
		_normalized_points.append(normalized_point)
	return _normalized_points


static func get_bounded_path_follow_2d(
	parent: Node,
	node_path:NodePath,
	_normalized_points: PackedVector2Array,
	rect: Rect2,
	start_corner: Vector2i = Vector2i(0, 1),
) -> PathFollow2D:
	"""Move the thing at `node_path` along a curve, bound by a `rect`.

	- parent: the parent for the newly-instanced path
	- normalized_points: the curve
	- rect: the rect to move inside
	- start_corner:
		- (0,0) -> top left
		- (1,1) -> bottom right
		- (0,1) -> bottom left  [default]
		- (1,0) -> top right
	"""
	# assert rect is positive
	assert(rect == rect.abs())
	
	var height: float = rect.size.y
	var start_point: Vector2
	var end_point: Vector2
	var flip_y: bool = false
	match start_corner:
		Vector2i.ZERO:  # top left
			flip_y = true
			start_point = rect.position
			end_point = rect.position + Vector2(rect.size.x, 0.0)
		Vector2i.ONE:  # bottom right
			start_point = Vector2(rect.end)
			end_point = rect.position + Vector2(0.0, rect.size.y)
		Vector2i(0, 1):  # bottom left
			start_point = rect.position + Vector2(0.0, rect.size.y)
			end_point = Vector2(rect.end)
		Vector2i(1, 0):  # top right
			flip_y = true
			start_point = rect.position + Vector2(rect.size.x, 0.0)
			end_point = rect.position
		_:
			print("WARNING unhandled corner %s" % [start_corner])
	
	var height_vec: Vector2 = -Vector2(0.0, height)
	if flip_y:
		height_vec = abs(height_vec)
		height = -height
	
	var _path_2d: UberPath2D = UberPath2D.new()
	_path_2d.hide()  # SmoothPath draws itself by default
	parent.add_child(_path_2d)
	
	var _path_follow_2d = PathFollow2D.new()
	_path_2d.add_child(_path_follow_2d)
	
	var _remote_transform_2d = RemoteTransform2D.new()
	_path_follow_2d.add_child(_remote_transform_2d)
	_remote_transform_2d.remote_path = node_path

	var _curve_2d: Curve2D = Curve2D.new()
	for point in _normalized_points:
		var denorm_point = start_point + height_vec + Vector2(end_point.x - start_point.x, height) * point
		_curve_2d.add_point(denorm_point)
	_path_2d.curve = _curve_2d

	return _path_follow_2d
