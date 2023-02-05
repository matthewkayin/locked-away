extends Area2D

func _ready():
    var _ret = connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.name == "player":
        yield(get_node("../canvas").fade_out(), "completed")
        get_tree().change_scene("res://title.tscn")