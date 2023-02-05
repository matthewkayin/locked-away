extends Node2D

onready var sprite = $sprite
onready var tween = $tween
onready var timer = $timer
onready var enter = $enter

func _ready():
    sprite.frame = 0
    fade_in()
    timer.connect("timeout", self, "_on_timer_timeout")

func _on_timer_timeout():
    enter.visible = not enter.visible
    timer.start(0.5)

func fade_in():
    sprite.modulate = Color(1, 1, 1, 0)
    tween.interpolate_property(sprite, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.5)
    tween.start()
    yield(tween, "tween_all_completed")
    timer.start(1.0)

func fade_out():
    timer.stop()
    enter.visible = false

    tween.interpolate_property(sprite, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5)
    tween.start()
    yield(tween, "tween_all_completed")
    if sprite.frame == 3:
        end_scene()
        return
    sprite.frame += 1
    fade_in()

func _process(_delta):
    if sprite.modulate.a == 1 and Input.is_action_just_pressed("enter"):
        fade_out()
    
func end_scene():
    get_tree().change_scene("res://world.tscn")