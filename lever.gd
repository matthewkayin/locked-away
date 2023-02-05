extends Hook

onready var sprite = $sprite
onready var blocks = get_node("../../blocks")

func _ready():
    pull_type = PullType.MED

func on_pull(player):
    available = false
    sprite.play("pull")
    if player.grounded:
        player.end_hook()
    yield(sprite, "animation_finished")
    sprite.play("idle")

    blocks.swap()
    available = true
