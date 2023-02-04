extends Area2D

func _ready():
    var _ret = connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.name == "player":
        body.hair_length += 1
        queue_free()