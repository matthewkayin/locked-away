extends Area2D

signal collected

onready var sprite = $sprite
onready var fruit = $fruit
onready var sound = $sound

var has_been_used = false

export var enabled = true

func _ready():
    var _ret = connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if not enabled:
        return
    if has_been_used:
        return
    if body.name != "player":
        return

    if not body.grounded:
        yield(body, "grounded")
    if not overlaps_body(body):
        return
    
    has_been_used = true
    if body.position.x < position.x:
        body.facing_direction = 1
    else:
        body.facing_direction = -1
    body.pause_input()
    sprite.play("open")
    yield(sprite, "animation_finished")
    sprite.play("is_open")
    fruit.visible = true
    fruit.play()
    while fruit.frame != 13:
        yield(fruit, "frame_changed")
    sound.play()
    body.grow_hair()
    yield(fruit, "animation_finished")
    fruit.visible = false

    body.paused_input = false

    emit_signal("collected")