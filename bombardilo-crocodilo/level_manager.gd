extends Node3D

class_name LevelManager

@export var gridmap : GridMap
@export var enemy_scene : PackedScene # Glisse ta scène enemy.tscn ici dans l'inspecteur

# IDs de ta GridMap
const ID_DESTRUCTIBLE = 2
const ID_BONUS = 3

# STATIC pour survivre au reload_current_scene()
static var current_level : int = 1

func _ready():
	load_level_json(current_level)

func load_level_json(num: int):
	var path = "res://data/levels/level_%02d.json" % num
	if not FileAccess.file_exists(path):
		print("Fichier niveau inexistant, retour au niveau 1")
		current_level = 1 
		load_level_json(1)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	# 1. Placement des blocs
	for pos in data["destructible_blocks"]:
		gridmap.set_cell_item(Vector3i(pos.x, 1, pos.z), ID_DESTRUCTIBLE)
	for pos in data["bonus_blocks"]:
		gridmap.set_cell_item(Vector3i(pos.x, 1, pos.z), ID_BONUS)

	# 2. Placement du Player (on déplace celui qui est déjà dans la scène)
	var player = get_tree().current_scene.find_child("Player", true)
	if player and data.has("player_spawn"):
		var p_pos = data["player_spawn"]
		player.global_position = Vector3(p_pos.x, 2.0, p_pos.z)

	# 3. Placement du Portail (on déplace celui qui est déjà dans la scène)
	var portal = get_tree().current_scene.find_child("Portal", true)
	if portal and data.has("portal_spawn"):
		var port_pos = data["portal_spawn"]
		portal.global_position = Vector3(port_pos.x, 1.0, port_pos.z)
		portal.hide() # On s'assure qu'il est invisible au début

	# 4. Spawn des Ennemis
	# NOTE : Supprime l'ennemi placé manuellement dans ton éditeur pour éviter les doublons
	if enemy_scene and data.has("enemies_spawn"):
		for e_pos in data["enemies_spawn"]:
			var new_enemy = enemy_scene.instantiate()
			add_child(new_enemy)
			new_enemy.global_position = Vector3(e_pos.x, 2.0, e_pos.z)
