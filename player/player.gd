extends KinematicBody2D

signal grounded

onready var hook_timer = $hook_timer
onready var jump_timer = $jump_timer
onready var coyote_timer = $coyote_timer
onready var delay_gravity_timer = $delay_gravity_timer
onready var raycast = $raycast
onready var sprite = $sprite
onready var hair_sprite = $hair_sprite
onready var land_timer = $land_timer
onready var camera = $camera
onready var tween = $tween
onready var hair_vine = $hair_vine
onready var grapple_point = $grapple_point
onready var blocks = get_node("../blocks")
onready var death_timer = $death_timer

const DECELERATION = 12
const VELOCITY = 96
const MAX_VELOCITY = 64 * 4
const GRAVITY = 10
const MAX_JUMP_HEIGHT = 1

const HOOK_DELAY_TIME = 0.2
const HOOK_PULL_SPEED = 256 
const MIN_HOOK_DIST = 16
const MAX_HOOK_DIST = [0, 64, 96, 128]
const HOOK_SPEED = [0, 64, 96, 128]

const JUMP_INPUT_DURATION = 0.06
const COYOTE_TIME_DURATION = 0.06
const LAND_FRAME_DURATION = 0.1
const DEATH_DURATION = 1.0

var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var facing_direction = 1
var grounded = false

var jump_height = null
var nearest_hook = null
export var hair_length = 1

var entered_first_room = false
var spawn_point = null
var current_room = null

enum HookState {
    NONE,
    THROW,
    DELAY,
    PULL
}

var hook_state = HookState.NONE
var paused = false
var paused_input = false
var camera_pos = Vector2.ZERO

func _ready():
    hook_timer.connect("timeout", self, "_on_hook_timer_timeout")

func _physics_process(_delta):
    if paused:
        return

    if not paused_input:
        if Input.is_action_pressed("up"):
            direction.y = -1
        elif Input.is_action_pressed("down"):
            direction.y = 1
        else:
            direction.y = 0

    # Direction input
    if not paused_input:
        if Input.is_action_pressed("right"):
            direction.x = 1
            facing_direction = 1
        elif Input.is_action_pressed("left"):
            direction.x = -1
            facing_direction = -1
        else:
            direction.x = 0

    # Jump input
    if not paused_input:
        if Input.is_action_just_pressed("jump"):
            jump_timer.start(JUMP_INPUT_DURATION)
        if jump_height != null and (position.y <= jump_height or Input.is_action_just_released("jump")):
            jump_height = null

    # Grapple input
    if not paused_input:
        if nearest_hook != null and Input.is_action_just_pressed("grapple"):
            hair_vine.region_rect.size.y = 0
            hook_state = HookState.THROW

    # Hook throw
    if hook_state == HookState.THROW:
        var desired_length = position.distance_to(nearest_hook.position)
        if desired_length - hair_vine.region_rect.size.y <= HOOK_SPEED[hair_length - 1]:
            hair_vine.region_rect.size.y = desired_length
            hook_state = HookState.DELAY
            hook_timer.start(HOOK_DELAY_TIME)
        else:
            hair_vine.region_rect.size.y += HOOK_SPEED[hair_length - 1]
    elif hook_state != HookState.NONE:
        hair_vine.region_rect.size.y = position.distance_to(nearest_hook.position)

    if hook_state != HookState.NONE:
        hair_vine.rotation = (nearest_hook.position - position).angle() - PI / 2
        if hook_state != HookState.THROW:
            grapple_point.visible = true
            grapple_point.position = nearest_hook.position - position

    # Velocity
    if hook_state == HookState.PULL:
        if nearest_hook.pull_type == Hook.PullType.HEAVY or (nearest_hook.pull_type == Hook.PullType.MED and not grounded):
            velocity = position.direction_to(nearest_hook.position) * HOOK_PULL_SPEED
    else:
        if abs(velocity.x) > MAX_VELOCITY or direction.x == 0:
            var decel_direction = -1
            if velocity.x < 0:
                decel_direction = 1
            var target_velocity = MAX_VELOCITY * direction.x

            var deceleration = DECELERATION
            if not grounded:
                deceleration *= 0.5

            if abs(velocity.x - target_velocity) <= deceleration:
                velocity.x = target_velocity
            else:
                velocity.x += deceleration * decel_direction
        else:
            velocity.x = direction.x * VELOCITY
        if jump_height == null:
            velocity.y += GRAVITY
            if velocity.y > MAX_VELOCITY:
                velocity.y = MAX_VELOCITY
        else:
            velocity.y = -MAX_VELOCITY

    var was_grounded = grounded
    grounded = is_on_floor()
    if not was_grounded and grounded:
        emit_signal("grounded")
    if was_grounded and not grounded:
        coyote_timer.start(COYOTE_TIME_DURATION)
    if grounded and velocity.y >= 5:
        velocity.y = 5

    if grounded and spawn_point == null:
        spawn_point = position
        spawn_point.x = clamp(spawn_point.x, camera.limit_left + 8, camera.limit_right - 8)
        spawn_point.y = clamp(spawn_point.y, camera.limit_top + 8, camera.limit_bottom - 8)

    if not grounded:
        land_timer.stop()
    if not was_grounded and grounded:
        land_timer.start(LAND_FRAME_DURATION)

    # Jump input
    if (grounded or not coyote_timer.is_stopped()) and not jump_timer.is_stopped() and hook_state == HookState.NONE:
        jump_height = position.y - MAX_JUMP_HEIGHT

    # Movement
    var _ret = move_and_slide(velocity, Vector2.UP)
    for i in get_slide_count():
        var collider = get_slide_collision(i)
        if collider.collider.name == "spikes":
            die()
            return

    # Check if end hook state
    # Possible bugfix idea: hooks send an area2d on_area_entered message to player when they pass it
    # If player nearest_hook == the hook that sent the message, release grapple
    if hook_state == HookState.PULL and position.distance_to(nearest_hook.position) <= 8:
        end_hook()

    # Hook Search
    if hook_state == HookState.NONE and hair_length > 1:
        search_hooks()

    update_sprite()

func end_hook():
    hair_vine.region_rect.position.x = 0
    hair_vine.region_rect.size.y = 0
    grapple_point.visible = false
    hook_state = HookState.NONE

func search_hooks():
    if current_room == null:
        return

    var look_direction
    if direction.y != 0:
        look_direction = Vector2(0, direction.y)
    else:
        look_direction = Vector2(facing_direction, -1)
    var search_origin = position + (look_direction * 128)

    nearest_hook = null
    var nearest_hook_dist = 0
    for hook in get_tree().get_nodes_in_group("hooks"):
        hook.set_inactive()
    
    for hook in get_tree().get_nodes_in_group("hooks"):
        if not hook.available:
            continue
        if position.distance_to(hook.position) > MAX_HOOK_DIST[hair_length - 1] or position.distance_to(hook.position) < MIN_HOOK_DIST:
            continue
        if not current_room.overlaps_area(hook):
            continue

        raycast.cast_to = hook.position - position
        raycast.force_raycast_update()
        if raycast.is_colliding():
            continue

        var hook_dist = search_origin.distance_to(hook.position)
        if nearest_hook == null or hook_dist < nearest_hook_dist:
            nearest_hook = hook
            nearest_hook_dist = hook_dist

    if nearest_hook != null:
        nearest_hook.set_active()

func _on_hook_timer_timeout():
    jump_height = null
    hair_vine.region_rect.position.x = 20
    hook_state = HookState.PULL
    nearest_hook.on_pull(self)

func update_sprite(force_anim=""):
    if force_anim != "":
        sprite.play(force_anim)
    elif hook_state == HookState.THROW or hook_state == HookState.DELAY:
        sprite.play("grapple_throw")
    elif hook_state == HookState.PULL:
        sprite.play("grapple_pull")
    elif grounded and not land_timer.is_stopped():
        sprite.play("jump_fall")
    elif grounded and velocity.x == 0:
        sprite.play("idle")
    elif grounded:
        sprite.play("run")
    elif not grounded and velocity.y >= 0:
        sprite.play("jump_apex")
    elif not grounded and jump_height != null and abs(position.y - jump_height) > 16:
        sprite.play("jump")
    elif not grounded: 
        sprite.play("jump_rise")

    if not hair_sprite.animation.ends_with("grow"):
        hair_sprite.animation = String(hair_length) + "_" + sprite.animation
        hair_sprite.frame = sprite.frame

    if hook_state != HookState.NONE:
        sprite.rotation = (nearest_hook.position - position).angle() + (PI / 2)
    else:
        sprite.rotation = 0
    hair_sprite.rotation = sprite.rotation
    
    sprite.flip_h = facing_direction == -1
    hair_sprite.flip_h = sprite.flip_h

func set_current_room(room):
    pause()
    var CAMERA_TRANSITION_DURATION = 1.0
    if not entered_first_room:
        CAMERA_TRANSITION_DURATION = 0
        entered_first_room = true
    tween.interpolate_property(camera, "limit_left", camera.limit_left, room.position.x - room.collider.shape.extents.x, CAMERA_TRANSITION_DURATION)
    tween.interpolate_property(camera, "limit_top", camera.limit_top, room.position.y - room.collider.shape.extents.y, CAMERA_TRANSITION_DURATION)
    tween.interpolate_property(camera, "limit_right", camera.limit_right, room.position.x + room.collider.shape.extents.x, CAMERA_TRANSITION_DURATION)
    tween.interpolate_property(camera, "limit_bottom", camera.limit_bottom, room.position.y + room.collider.shape.extents.y, CAMERA_TRANSITION_DURATION)
    tween.start()
    yield(tween, "tween_all_completed")
    blocks.save_state()
    spawn_point = null
    current_room = room
    resume()

func pause():
    paused = true
    sprite.stop()
    hair_sprite.stop()

func resume():
    paused = false
    sprite.play()

func pause_input():
    direction = Vector2.ZERO
    jump_height = null
    paused_input = true

func die():
    if not visible:
        return
    visible = false
    death_timer.start(DEATH_DURATION)
    print("hey")
    yield(death_timer, "timeout")
    print("hi")

    hook_timer.stop()
    jump_timer.stop()
    coyote_timer.stop()
    delay_gravity_timer.stop()
    land_timer.stop()
    hook_state = HookState.NONE
    jump_height = null
    nearest_hook = null
    hair_vine.region_rect.position.x = 0
    hair_vine.region_rect.size.y = 0
    grapple_point.visible = false
    velocity = Vector2.ZERO
    direction = Vector2.ZERO

    blocks.load_state()

    sprite.play("idle")
    position = spawn_point
    visible = true

func grow_hair():
    hair_length += 1
    hair_sprite.play(String(hair_length) + "_grow")
    yield(hair_sprite, "animation_finished")
    hair_sprite.animation = String(hair_length) + "_" + sprite.animation
    hair_sprite.frame = sprite.frame
