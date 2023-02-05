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
