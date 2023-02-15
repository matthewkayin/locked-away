extends ParallaxBackground

onready var layer1 = $layer1
onready var play = $layer3/play
onready var quit = $layer3/quit
onready var tower = $layer3/tower
onready var words = $layer3/words
onready var jump = $layer3/jump
onready var layer2 = $layer2
onready var tween = $tween
onready var timer = $timer
onready var fade = $fade
onready var hop = $hop
onready var tick = $tick
onready var select = $select

var cursor_index = 0
var ui_enabled = false
var end_scene_on_start = false

func _ready():
    set_cursor()
    if end_scene_on_start:
        end_scene()
    else:
        fade_in()

func fade_in():
    ui_enabled = false
    tween.interpolate_property(fade, "color", Color(0, 0, 0, 1), Color(0, 0, 0, 0), 0.5)
    tween.start()
    yield(tween, "tween_all_completed")
    ui_enabled = true

func fade_out():
    tween.interpolate_property(fade, "color", Color(0, 0, 0, 0), Color(0, 0, 0, 1), 0.5)
    tween.start()
    yield(tween, "tween_all_completed")

func _process(_delta):
    layer1.motion_offset.x -= 0.1
    if not ui_enabled:
        return
    if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("down"):
        cursor_index = (cursor_index + 1) % 2
        set_cursor()
        tick.play()
    if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("enter"):
        select.play()
        if cursor_index == 0:
            yield(fade_out(), "completed")
            var root = get_parent()
            root.remove_child(self)
            self.call_deferred("free")
            var story = load("res://story.tscn").instance()
            root.add_child(story)
        else:
            get_tree().quit()
    
func set_cursor():
    if cursor_index == 0:
        play.frame = 1
        quit.frame = 2
    else:
        play.frame = 0
        quit.frame = 3

func end_scene():
    ui_enabled = false

    tower.position.x = 162
    layer2.motion_offset.x = 64
    play.modulate = Color(1, 1, 1, 0)
    quit.modulate = Color(1, 1, 1, 0)
    words.modulate = Color(1, 1, 1, 0)

    yield(fade_in(), "completed")
    timer.start(3.0)
    yield(timer, "timeout")

    jump.visible = true

    jump.play()
    hop.play()
    yield(jump, "animation_finished")
    jump.visible = false

    timer.start(3.0)
    yield(timer, "timeout")

    var PAN_DURATION = 2.5
    tween.interpolate_property(tower, "position", tower.position, Vector2(0, 0), PAN_DURATION)
    tween.interpolate_property(layer2, "motion_offset", layer2.motion_offset, Vector2(0, 0), PAN_DURATION)
    tween.start()
    yield(tween, "tween_all_completed")

    timer.start(0.5)
    yield(timer, "timeout")

    var FADE_DURATION = 0.5
    tween.interpolate_property(words, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), FADE_DURATION)
    tween.interpolate_property(play, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), FADE_DURATION)
    tween.interpolate_property(quit, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), FADE_DURATION)
    tween.start()
    yield(tween, "tween_all_completed")

    ui_enabled = true
