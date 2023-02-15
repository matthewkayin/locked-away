extends StaticBody2D

onready var first_fruit = get_node("../fruits/2")
onready var sprite = $sprite
onready var dialog = $dialog

func _ready():
    first_fruit.connect("collected", self, "_on_fruit_collected")

func _on_fruit_collected():
    var player = get_node("../player")

    player.paused_input = true
    player.direction = Vector2.ZERO
    if player.position.x < position.x:
        player.facing_direction = 1
    else:
        player.facing_direction = -1
    player.sprite.play("idle")

    sprite.play("wake")
    yield(sprite, "animation_finished")
    
    sprite.play("talk")
    dialog.open("Hey!")
    yield(dialog, "finished")

    dialog.open("I was gonna eat that!")
    yield(dialog, "finished")

    sprite.play("idle")
    dialog.open("Anyways...")
    yield(dialog, "finished")

    sprite.play("talk")
    dialog.open("Now that your hair is longer,")
    yield(dialog, "finished")

    dialog.open("I bet you could press H\nto grapple on to things.")
    yield(dialog, "finished")

    dialog.open("Try it sometime.")
    yield(dialog, "finished")

    dialog.close()

    sprite.play("hide")
    yield(sprite, "animation_finished")

    sprite.play("hidden")
    player.paused_input = false
