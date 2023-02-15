extends Area2D

onready var sprite = $sprite
onready var dialog = $dialog
var player

var angy = false
var has_played_scene = false

func _ready():
    var _ret = self.connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.name != "player":
        return
    if has_played_scene:
        return

    body.paused_input = true
    body.direction = Vector2.ZERO
    if body.position.x < position.x:
        body.facing_direction = 1
    else:
        body.facing_direction = -1
    body.sprite.play("idle")

    dialog.open("Huh?")
    yield(dialog, "finished")

    dialog.open("Oh. It's you.")
    yield(dialog, "finished")

    dialog.open("I'm not sure how\nyou escaped...")
    yield(dialog, "finished")

    dialog.open("but it doesn't matter.")
    yield(dialog, "finished")

    dialog.open("You'll never get out alive!")
    yield(dialog, "finished")

    dialog.close()

    has_played_scene = true
    body.paused_input = false

func _process(_delta):
    if player == null:
        player = get_node_or_null("../player")
        if player == null:
            return

    if angy:
        sprite.play("angy")
    elif overlaps_body(player):
        if player.hair_length != 4 and has_played_scene:
            sprite.play("ha")
        elif player.hair_length == 4:
            sprite.play("what")
            yield(sprite, "animation_finished")
            angy = true
            sprite.play("angy")
        else:
            sprite.play("idle")
    else:
        sprite.play("idle")