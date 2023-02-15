extends Area2D

func _ready():
    var _ret = connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.name == "player":
        yield(get_node("../canvas").fade_out(), "completed")
        var root = get_parent().get_parent()
        var level = get_parent()
        root.remove_child(level)
        level.call_deferred("free")
        var title = load("res://title.tscn").instance()
        title.end_scene_on_start = true
        root.add_child(title)
