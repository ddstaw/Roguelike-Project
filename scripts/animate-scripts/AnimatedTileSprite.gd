extends Sprite2D
class_name AnimatedTileSprite

@export var frames: Array[Texture2D] = []
@export var frame_time: float = 0.25

var _frame_index := 0
var _timer := 0.0

func _ready():
	if frames.size() > 0:
		texture = frames[0]
		_frame_index = randi() % frames.size()

func _process(delta):
	if frames.size() <= 1:
		return
	_timer += delta
	if _timer >= frame_time:
		_timer = 0.0
		_frame_index = (_frame_index + 1) % frames.size()
		texture = frames[_frame_index]
