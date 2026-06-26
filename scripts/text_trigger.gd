extends Area2D

@export var text: String;
@export var start_coord: Vector2i;
@export var target_layer: TileMapLayer;
@export var type_speed: float = 0.05;
@export var scroll: bool = false;
@export var fall: bool = false;
@export var scroll_duration: float = 0.12
@export var delay: float = 0.00;

var tileset_source_id: int = 0
var sheet_columns: int = 8
var tile_size: int = 8

const START_ASCII = 32
const charmap = {
	32: 0,	# space
	# A -> Z
	65: 1, 66: 2, 67: 3, 68: 4, 69: 5, 70: 6, 
	71: 7, 72: 8, 73: 9, 74: 10, 75: 11,
	76: 12, 77: 13, 78: 14, 79: 15, 80: 16,
	81: 17, 82: 18, 83: 19, 84: 20, 85: 21,
	86: 22, 87: 23, 88: 24, 89: 25, 90: 26,
	# a -> z
	97: 1, 98: 2, 99: 3, 100: 4, 101: 5, 102: 6, 
	103: 7, 104: 8, 105: 9, 106: 10, 107: 11,
	108: 12, 109: 13, 110: 14, 111: 15, 112: 16,
	113: 17, 114: 18, 115: 19, 116: 20, 117: 21,
	118: 22, 119: 23, 120: 24, 121: 25, 122: 26,
	# 0 -> 9
	48: 27, 49: 28, 50: 29, 51: 30, 52: 31,
	53: 32, 54: 33, 55: 34, 56: 35, 57: 36
}

func write_text(text: String, start_coord: Vector2i, target_layer: TileMapLayer, type_speed: float = 0.05, scroll: bool = false, fall: bool = false):
	var current_coord = start_coord
	var placed_tiles: Array[Dictionary] = [] # Track tiles if fall is true
	for i in range(text.length()):
		await get_tree().create_timer(type_speed).timeout
		var character = text[i]
		if character == "\n":
			current_coord.x = start_coord.x
			if scroll != true:
				current_coord.y += 1
			else:
				await shift_lines_up(target_layer)
			continue
		var ascii_val = character.unicode_at(0)
		var glyph_index = charmap[ascii_val]
		if glyph_index < 0:
			current_coord.x += 1
			continue
		var atlas_x = glyph_index % sheet_columns
		var atlas_y = glyph_index / sheet_columns
		var atlas_coord = Vector2i(atlas_x, atlas_y)
		target_layer.set_cell(current_coord, tileset_source_id, atlas_coord)
		if fall:
			placed_tiles.append({
				"cell_coord": current_coord, 
				"atlas_coord": atlas_coord
			})
		current_coord.x += 1
	if fall and placed_tiles.size() > 0:
		_convert_to_physics_letters(target_layer, placed_tiles)


func _convert_to_physics_letters(layer: TileMapLayer, tiles: Array[Dictionary]):
	print("Its working")
	var tileset = layer.tile_set
	var source = tileset.get_source(tileset_source_id) as TileSetAtlasSource
	if not source:
		push_warning("Could not find TileSetAtlasSource for falling text.")
		return
		
	var texture = source.texture
	var tile_s = tileset.tile_size
	for t in tiles:
		var cell_coord = t["cell_coord"]
		var atlas_coord = t["atlas_coord"]
		layer.set_cell(cell_coord, -1)
		var rb = RigidBody2D.new()
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.region_enabled = true
		sprite.region_rect = Rect2(atlas_coord * tile_s, tile_s)
		rb.add_child(sprite)
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(tile_size*2,tile_size*2)
		collision.shape = shape
		rb.add_child(collision)
		var local_pos = layer.map_to_local(cell_coord)
		rb.global_position = layer.to_global(local_pos)
		layer.add_child(rb)
		
func shift_lines_up(target_layer: TileMapLayer):
	var tween = create_tween()
	tween.tween_property(target_layer, "position:y", -tile_size, scroll_duration)\
		 .set_trans(Tween.TRANS_QUAD)\
		 .set_ease(Tween.EASE_OUT)
	await tween.finished
	target_layer.position.y = 0
	var used_cells = target_layer.get_used_cells()
	var cells_to_move = []
	used_cells.sort_custom(func(a, b): return a.y < b.y)
	
	for cell in used_cells:
		var source = target_layer.get_cell_source_id(cell)
		var atlas_coords = target_layer.get_cell_atlas_coords(cell)
		target_layer.erase_cell(cell)
		if cell.y > 0:
			cells_to_move.append({
				"coord": Vector2i(cell.x, cell.y - 1),
				"source": source,
				"atlas": atlas_coords
			})
	for cell_data in cells_to_move:
		target_layer.set_cell(cell_data.coord, cell_data.source, cell_data.atlas)



func swap_character_layer(source: TileMapLayer, dest: TileMapLayer, character: String):
	if character.is_empty():
		return
	var ascii_val = character.unicode_at(0)
	if not charmap.has(ascii_val):
		print("Warning: Character '" + character + "' not found in charmap.")
		return
		
	var glyph_index = charmap[ascii_val]
	var atlas_x = glyph_index % sheet_columns
	var atlas_y = glyph_index / sheet_columns
	var target_atlas_coords = Vector2i(atlas_x, atlas_y)
	var source_id = 0 
	var used_cells = source.get_used_cells()
	
	for cell_coord in used_cells:
		var current_atlas = source.get_cell_atlas_coords(cell_coord)
		var current_source = source.get_cell_source_id(cell_coord)
		
		if current_source == source_id and current_atlas == target_atlas_coords:
			var alternative_id = source.get_cell_alternative_tile(cell_coord)
			
			dest.set_cell(cell_coord, source_id, target_atlas_coords, alternative_id)
			source.erase_cell(cell_coord)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body_entered.disconnect(_on_body_entered)
		await get_tree().create_timer(delay).timeout
		await write_text(text, start_coord, target_layer, type_speed, scroll, fall)
		queue_free()
