extends Node2D
class_name Hook

enum PullType {
    HEAVY,
    MED,
    LIGHT
}

onready var cursor = $cursor

var pull_type = PullType.HEAVY
var available = true

func _ready():
    add_to_group("hooks")

func set_inactive():
    cursor.visible = false

func set_active():
    cursor.visible = true

func on_pull(_player):
    pass
