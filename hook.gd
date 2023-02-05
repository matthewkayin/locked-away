extends Node2D
class_name Hook

onready var cursor = $cursor

func _ready():
    add_to_group("hooks")

func set_inactive():
    cursor.visible = false

func set_active():
    cursor.visible = true
