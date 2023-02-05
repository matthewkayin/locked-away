extends Area2D

onready var sprite = $sprite
var player

var angy = false

func _ready():
    pass

func _process(_delta):
    if player == null:
        player = get_node_or_null("../player")
        if player == null:
            return

    if angy:
        sprite.play("angy")
    elif overlaps_body(player):
        if player.hair_length != 4:
            sprite.play("ha")
        else:
            sprite.play("what")
            yield(sprite, "animation_finished")
            angy = true
            sprite.play("angy")
    else:
        sprite.play("idle")