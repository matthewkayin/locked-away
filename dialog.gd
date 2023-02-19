extends Control

signal finished

onready var dialog = $dialog
onready var label = $dialog/label
onready var timer = $timer
onready var blip = $blip
onready var blip_timer = $blip_timer
onready var h_prompt = $h_prompt
onready var h_prompt_timer = $h_prompt_timer

const H_PROMPT_DELAY = 0.5
const CHAR_DURATION = 0.05

export var blip_delay = 0.02
export var pitch_scale = 2
export var use_right_tail = false

func _ready():
    h_prompt.visible = false
    if use_right_tail:
        $tail.visible = false
        $tail_right.visible = true
    else:
        $tail.visible = true
        $tail_right.visible = false
    blip.pitch_scale = pitch_scale
    timer.connect("timeout", self, "_on_timer_timeout")
    blip.connect("finished", self, "_on_blip_finished")
    h_prompt_timer.connect("timeout", self, "_on_h_prompt_timer_timeout")
    close()

func open(with_text: String):
    h_prompt.visible = false
    h_prompt_timer.stop()
    var line_length = 0
    var line_height = 1
    if "\n" in with_text:
        var lines = with_text.split("\n")
        line_length = max(lines[0].length(), lines[1].length())
        line_height = 2
        dialog.rect_position.y = 0
        h_prompt.position.y = 14
    else:
        dialog.rect_position.y = 8
        h_prompt.position.y = 14
        line_length = with_text.length()

    label.text = with_text
    label.percent_visible = 0
    dialog.rect_size.x = 7 + (line_length * 8) + 14
    h_prompt.position.x = 7 + (line_length * 8) + 1
    if use_right_tail:
        dialog.rect_position.x = (103 - dialog.rect_size.x)
        h_prompt.position.x = 90
    dialog.rect_size.y = 9 + (line_height * 8)
    timer.start(CHAR_DURATION)
    blip.play()
    visible = true

func close():
    visible = false

func is_finished():
    return label.percent_visible == 1

func _on_timer_timeout():
    if not is_finished():
        label.visible_characters += 1
        timer.start(CHAR_DURATION)

func _on_h_prompt_timer_timeout():
    h_prompt.visible = not h_prompt.visible
    h_prompt_timer.start(H_PROMPT_DELAY)

func _on_blip_finished():
    blip_timer.start(blip_delay)
    yield(blip_timer, "timeout")
    if not is_finished():
        blip.play()

func _process(_delta):
    if not visible:
        return
    if Input.is_action_just_pressed("grapple"):
        if not is_finished():
            timer.stop()
            label.percent_visible = 1
        else:
            emit_signal("finished")
    if label.percent_visible == 1 and h_prompt_timer.is_stopped():
        h_prompt_timer.start(H_PROMPT_DELAY)
