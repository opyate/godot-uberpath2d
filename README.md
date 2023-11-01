# godot-uberpath2d

![icon](icon.png)

A Path2D with smoothing, and utilities for restricting it to any Rect2

# Demo

![Demo](demo.gif)

# Usage

Create a new node of type `UberPath2D`

Draw a path.

Check `Smooth` in the editor properties to smooth the path.

In code, restrict your path to a rect like so:

```gdscript
@onready var path: Path2D = $UberPath2D
@onready var sprite: Sprite = $my_sprite
var rect2: Rect2 = Rect2(0, 0, 100, 100)
var start_corner: Vector2i = Vector2i(0,1) # bottom left

var path_follow_2d: PathFollow2D = UberPath2D.get_bounded_path_follow_2d(
    self,  # or some other container to parent to
    sprite.get_path(),  # the sprite you want to move along the path
    path.normalized_points,
    rect2,
    start_corner
)

# tween it!
await create_tween()\
    .tween_property(path_follow_2d, "progress_ratio", 1.0, 3.5).finished
```


start_corner` (type `Vector2i`) is one of
- (0,0) -> top left
- (1,1) -> bottom right
- (0,1) -> bottom left  [default]
- (1,0) -> top right