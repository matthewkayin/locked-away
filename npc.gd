extends StaticBody2D

onready var cutscene_trigger = $cutscene_trigger
onready var sprite = $sprite
onready var dialog = $dialog

var has_played_scene = false

func _ready():
    cutscene_trigger.connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.name != "player":
        return
    if has_played_scene:
        return

    body.paused_input = true
    body.direction = Vector2.ZERO
    body.sprite.play("idle")

    sprite.play("rise")
    yield(sprite, "animation_finished")

    sprite.play("talk")
    dialog.open("Hey")
    yield(dialog, "finished")

    dialog.open("You're the\nprincess, right?")
    yield(dialog, "finished")

    sprite.play("scratch")
    dialog.open("Look, I'm not sure why they\nlocked you down here but...")
    yield(dialog, "finished")

    dialog.open("You don't want to end up like me.")
    yield(dialog, "finished")

    sprite.play("talk")
    dialog.open("Just use SPACE\nto jump.")
    yield(dialog, "finished")
    dialog.open("Now go! Get outta here!")
    yield(dialog, "finished")
    dialog.close()

    sprite.play("idle")
    has_played_scene = true
    body.paused_input = false
    body.allow_jump = true
