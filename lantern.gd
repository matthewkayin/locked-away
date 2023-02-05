extends Hook

onready var raycast = $raycast
onready var chain = $chain

func _ready():
    raycast.cast_to = Vector2.UP * 1920
    raycast.force_raycast_update()
    chain.region_rect.size.y = abs(position.y - raycast.get_collision_point().y)
    chain.position.y = -chain.region_rect.size.y