extends CanvasLayer

onready var rect = $rect
onready var tween = $tween

export var fade_in = true

func _ready():
    if not fade_in:
        rect.color = Color(1, 1, 1, 0)
        return
    rect.color = Color(1, 1, 1, 1)
    tween.interpolate_property(rect, "color", Color(0, 0, 0, 1), Color(0, 0, 0, 0), 0.5)
    tween.start()

func fade_out():
    rect.color = Color(0, 0, 0, 0)
    tween.interpolate_property(rect, "color", Color(0, 0, 0, 0), Color(0, 0, 0, 1), 0.5)
    tween.start()
    yield(tween, "tween_all_completed")
