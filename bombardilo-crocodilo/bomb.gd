extends StaticBody3D

@onready var timer = $ExplosionTimer
@export var explosion_scene : PackedScene # Glisse explosion.tscn ici
@export var bonus_scene : PackedScene # Glisse item_bonus.tscn ici

var explosion_size : int = 2

func _ready():
	# On lance le compte à rebours de 3 secondes dès que la bombe apparaît
	timer.start()
	# On connecte le signal du Timer à notre fonction d'explosion
	timer.timeout.connect(_on_explosion_timer_timeout)

func _on_explosion_timer_timeout():
	explode()

func explode():
	# 1. Explosion centrale
	spawn_explosion(global_position)
	
	var directions = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]
	var gridmap = get_tree().current_scene.find_child("GridMap", true)
	
	for dir in directions:
		# Pour chaque direction, on "avance" case par case jusqu'à max_range
		for i in range(1, explosion_size):
			var target_pos = global_position + (dir * i)
			
			if gridmap:
				var local_pos = gridmap.to_local(target_pos)
				var map_coords = gridmap.local_to_map(local_pos)
				
				# On teste l'étage 0 (sol) ET l'étage 1 (murs)
				var item_sol = gridmap.get_cell_item(Vector3i(map_coords.x, 0, map_coords.z))
				var item_mur = gridmap.get_cell_item(Vector3i(map_coords.x, 1, map_coords.z))
				
				var final_item = item_mur if item_mur != -1 else item_sol
				var final_coords = Vector3i(map_coords.x, 1, map_coords.z) if item_mur != -1 else Vector3i(map_coords.x, 0, map_coords.z)

				# --- LOGIQUE DE BLOCAGE ---
				if final_item == 1: # MUR INDESTRUCTIBLE
					break # Arrête l'expansion dans CETTE direction immédiatement
					
				# On vérifie si l'objet touché est une brique normale (2) OU une brique bonus (3)
				if final_item in [2, 3]: 
					# 1. On casse la brique (commun aux deux)
					gridmap.set_cell_item(final_coords, -1) 

					# 2. Augmentation du score
					var hud = get_tree().current_scene.find_child("HUD", true)
					if hud:
						hud.add_score(10)

					# 3. SI c'est la brique bonus (ID 3), on fait apparaître l'item
					if final_item == 3:
						spawn_bonus(target_pos)

					# 4. Effets visuels et arrêt du souffle
					spawn_explosion(target_pos) 
					break # La brique a stoppé l'explosion

			# Si la case est vide, on pose l'explosion et la boucle continue (i devient 2)
			spawn_explosion(target_pos)

	queue_free()

func spawn_explosion(pos):
	var e = explosion_scene.instantiate()
	get_parent().add_child(e)
	e.global_position = pos

func spawn_bonus(coords):
	if bonus_scene == null: return
	
	var bonus = bonus_scene.instantiate()
	get_parent().add_child(bonus)
	
	# --- LE CALCUL DE POSITION ---
	# floor() arrondit à l'unité (ex: 2.5 devient 2.0)
	# + 0.5 nous remet pile au centre de la case
	var x_centre = floor(coords.x) + 0.5
	var z_centre = floor(coords.z) + 0.5
	
	# On applique la position (Y=1.0 pour que le bonus ne soit pas dans le sol)
	bonus.global_position = Vector3(x_centre, 1.0, z_centre)
	# ------------------------------
	
	# Configuration du type de bonus
	bonus.type = bonus.BonusType.BOMB_COUNT if randf() > 0.5 else bonus.BonusType.EXPLOSION_RANGE
	bonus.setup_appearance()
