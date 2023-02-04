extends Area2D

onready var collider = $collider

func _ready():
    var _ret = connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.name != "player":
        return
    body.set_current_room(self)