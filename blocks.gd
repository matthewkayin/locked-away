extends TileMap

var previous_state = []

func _ready():
    pass 

func save_state():
    previous_state = []
    for cell in get_used_cells():
        previous_state.append([cell, get_cellv(cell)])

func load_state():
    for cell_val in previous_state:
        set_cellv(cell_val[0], cell_val[1])

func swap():
    for cell in get_used_cells():
        if get_cellv(cell) == 0:
            set_cellv(cell, 1)
        elif get_cellv(cell) == 1:
            set_cellv(cell, 0)