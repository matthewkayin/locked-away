extends KinematicBody2D

onready var hook_timer = $hook_timer
onready var jump_timer = $jump_timer
onready var coyote_timer = $coyote_timer
onready var delay_gravity_timer = $delay_gravity_timer
onready var raycast = $raycast
onready var hairline = $hairline
onready var sprite = $sprite
onready var hair_sprite = $hair_sprite

const DECELERATION = 24
const VELOCITY = 128
const MAX_VELOCITY = 64 * 4
const GRAVITY = 24
const MAX_JUMP_HEIGHT = 16 * 3
const MAX_HOOK_DIST = 640

const HOOK_DELAY_TIME = 0.3
const HOOK_SPEED = 32
const HOOK_PULL_SPEED = 256 * 3

const JUMP_INPUT_DURATION = 0.06
const COYOTE_TIME_DURATION = 0.06

var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var facing_direction = 1
var grounded = false

var jump_height = null
var nearest_hook = null
var hair_length = 0

enum HookState {
    NONE,
    THROW,
    DELAY,
    PULL
}

var hook_state = HookState.NONE

func _ready():
    hook_timer.connect("timeout", self, "_on_hook_timer_timeout")

func _physics_process(_delta):
    if Input.is_action_just_pressed("up"):
        hair_length = min(hair_length + 1, 4)
    if Input.is_action_just_pressed("down"):
        hair_length = max(hair_length - 1, 0)

    # Direction input
    if Input.is_action_pressed("right"):
        direction.x = 1
        facing_direction = 1
    elif Input.is_action_pressed("left"):
        direction.x = -1
        facing_direction = -1
    else:
        direction.x = 0

    # Jump input
    if Input.is_action_just_pressed("jump"):
        jump_timer.start(JUMP_INPUT_DURATION)
    if jump_height != null and (position.y <= jump_height or Input.is_action_just_released("jump")):
        jump_height = null

    # Grapple input
    if nearest_hook != null and Input.is_action_just_pressed("grapple"):
        hairline.add_point(Vector2.ZERO)
        hairline.add_point(Vector2.ZERO)
        hook_state = HookState.THROW

    # Hook throw
    if hook_state == HookState.THROW:
        if hairline.points[1].distance_to(nearest_hook.position - position) <= HOOK_SPEED:
            hairline.points[1] = nearest_hook.position - position
            hook_state = HookState.DELAY
            hook_timer.start(HOOK_DELAY_TIME)
        else:
            hairline.points[1] += hairline.points[1].direction_to(nearest_hook.position - position) * HOOK_SPEED
    elif hook_state != HookState.NONE:
        hairline.points[1] = nearest_hook.position - position

    # Velocity
    if hook_state == HookState.PULL:
        velocity = position.direction_to(nearest_hook.position) * HOOK_PULL_SPEED
    else:
        if not grounded:
            print(velocity)
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
        else:
            velocity.y = -MAX_VELOCITY
        #velocity.y = clamp(velocity.y, -MAX_VELOCITY, MAX_VELOCITY)

    var was_grounded = grounded
    grounded = is_on_floor()
    if was_grounded and not grounded:
        coyote_timer.start(COYOTE_TIME_DURATION)
    if grounded and velocity.y >= 5:
        velocity.y = 5

    # Jump input
    if (grounded or not coyote_timer.is_stopped()) and not jump_timer.is_stopped() and hook_state == HookState.NONE:
        jump_height = position.y - MAX_JUMP_HEIGHT

    # Movement
    var _ret = move_and_slide(velocity, Vector2.UP)

    if hook_state == HookState.PULL and position.distance_to(nearest_hook.position) <= 8:
        hairline.clear_points()
        hook_state = HookState.NONE

    # Hook Search
    if hook_state == HookState.NONE:
        search_hooks()

    update_sprite()

func search_hooks():
    nearest_hook = null
    var nearest_hook_dist = 0
    for hook in get_tree().get_nodes_in_group("hooks"):
        hook.set_inactive()
    
    for hook in get_tree().get_nodes_in_group("hooks"):
        var hook_dist = position.distance_to(hook.position)
        if hook_dist > MAX_HOOK_DIST:
            continue
        var direction_to_hook = position.direction_to(hook.position)
        if (direction_to_hook.x > 0 and facing_direction == -1) or (direction_to_hook.x < 0 and facing_direction == 1):
            continue

        raycast.cast_to = hook.position - position
        raycast.force_raycast_update()
        if raycast.is_colliding():
            continue

        if nearest_hook == null or hook_dist < nearest_hook_dist:
            nearest_hook = hook
            nearest_hook_dist = hook_dist

    if nearest_hook != null:
        nearest_hook.set_active()

func _on_hook_timer_timeout():
    hook_state = HookState.PULL
    jump_height = null

func update_sprite():
    if grounded and velocity.x == 0:
        sprite.play("idle")
    elif grounded:
        sprite.play("run")
    elif not grounded and velocity.y == 0:
        sprite.play("jump_apex")
    elif not grounded and velocity.y > 0:
        sprite.play("jump_fall")
    elif not grounded and jump_height != null and abs(position.y - jump_height) > 16:
        sprite.play("jump")
    elif not grounded: 
        sprite.play("jump_rise")

    if hair_length == 0:
        hair_sprite.play("0")
    else:
        hair_sprite.animation = String(hair_length) + "_" + sprite.animation
        hair_sprite.frame = sprite.frame
    
    sprite.flip_h = facing_direction == -1
    hair_sprite.flip_h = sprite.flip_h
