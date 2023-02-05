extends Node2D

onready var play = $play
onready var quit = $quit

var cursor_index = 0

func _ready():
    set_cursor()

func _process(_delta):
    if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("down"):
        cursor_index = (cursor_index + 1) % 2
        set_cursor()
    if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("enter"):
        if cursor_index == 0:
            get_tree().change_scene("res://story.tscn")
        else:
            get_tree().quit()
    
func set_cursor():
    if cursor_index == 0:
        play.frame = 1
        quit.frame = 2
    else:
        play.frame = 0
        quit.frame = 3