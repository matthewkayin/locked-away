extends KinematicBody2D

onready var hook_timer = $hook_timer
onready var raycast = $raycast
onready var hairline = $hairline

const VELOCITY = 128
const MAX_VELOCITY = 64 * 4
const GRAVITY = 16
const MAX_JUMP_HEIGHT = 16 * 3
const MAX_HOOK_DIST = 640

const HOOK_DELAY_TIME = 0.3
const HOOK_SPEED = 32
const HOOK_PULL_SPEED = 256 * 3

var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var facing_direction = 1

var jump_height = null
var nearest_hook = null

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
    # Direction input
    if Input.is_action_pressed("right"):
        direction.x = 1
        facing_direction = 1
    elif Input.is_action_pressed("left"):
        direction.x = -1
        facing_direction = -1
    else:
        direction.x = 0

    # Jump release input
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
        velocity.x = direction.x * VELOCITY
        if jump_height == null:
            velocity.y += GRAVITY
        else:
            velocity.y = -MAX_VELOCITY
        velocity.y = clamp(velocity.y, -MAX_VELOCITY, MAX_VELOCITY)

    var grounded = is_on_floor()
    if grounded and velocity.y >= 5:
        velocity.y = 5

    # Jump input
    if grounded and Input.is_action_pressed("jump") and hook_state == HookState.NONE:
        jump_height = position.y - MAX_JUMP_HEIGHT

    # Movement
    var _ret = move_and_slide(velocity, Vector2.UP)

    if hook_state == HookState.PULL and position.distance_to(nearest_hook.position) <= 8:
        hairline.clear_points()
        hook_state = HookState.NONE

    # Hook Search
    if hook_state == HookState.NONE:
        search_hooks()

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
