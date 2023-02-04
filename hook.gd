extends Node2D

onready var inactive = $inactive
onready var active = $active

func _ready():
    add_to_group("hooks")

func set_inactive():
    inactive.visible = true
    active.visible = false

func set_active():
    active.visible = true
    inactive.visible = false