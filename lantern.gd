extends Hook

onready var raycast = $raycast
onready var chain = $chain

func _ready():
    raycast.cast_to = Vector2.UP * 1024
    raycast.force_raycast_update()
    if raycast.is_colliding():
        chain.region_rect.size.y = abs(position.y - raycast.get_collision_point().y)
    else:
        chain.region_rect.size.y = 64
    chain.position.y = -chain.region_rect.size.y