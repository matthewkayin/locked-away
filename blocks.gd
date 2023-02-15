extends TileMap

var previous_state = []
var previous_open = false
var open = false

func _ready():
    pass 

func save_state():
    previous_state = []
    for cell in get_used_cells():
        previous_state.append([cell, get_cellv(cell)])
    previous_open = open

func load_state():
    for cell_val in previous_state:
        set_cellv(cell_val[0], cell_val[1])
    open = previous_open

func swap():
    open = not open
    for cell in get_used_cells():
        if get_cellv(cell) == 0:
            set_cellv(cell, 1)
        elif get_cellv(cell) == 1:
            set_cellv(cell, 0)