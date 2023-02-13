extends Hook

onready var sprite = $sprite
onready var blocks = get_node("../../blocks")

var stopped = false

func _ready():
    pull_type = PullType.MED
    add_to_group("levers")

func on_pull(player):
    stopped = false
    available = false
    sprite.play("pull")
    if player.grounded:
        player.end_hook()
    yield(sprite, "animation_finished")
    sprite.play("idle")

    if stopped:
        stopped = false
        available = true
        return

    blocks.swap()
    available = true

func stop():
    stopped = true
