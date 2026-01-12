extends StaticBody3D

@onready var timer = $ExplosionTimer
@export var explosion_scene : PackedScene # Glisse explosion.tscn ici

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
	
	var max_range = 2 # Tu peux changer ce chiffre pour augmenter la puissance !
	var directions = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]
	var gridmap = get_tree().current_scene.find_child("GridMap", true)
	
	for dir in directions:
		# Pour chaque direction, on "avance" case par case jusqu'à max_range
		for i in range(1, max_range + 1):
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
					
				if final_item == 2: # BRIQUE
					gridmap.set_cell_item(final_coords, -1) # Casse la brique
					
					# Augmentation score
					var hud = get_tree().current_scene.find_child("HUD", true)
					if hud:
						hud.add_score(10)
					
					spawn_explosion(target_pos) # Pose l'explosion sur la brique
					break # Arrête l'expansion dans cette direction (la brique a stoppé le souffle)
			
			# Si la case est vide, on pose l'explosion et la boucle continue (i devient 2)
			spawn_explosion(target_pos)

	queue_free()

func spawn_explosion(pos):
	var e = explosion_scene.instantiate()
	get_parent().add_child(e)
	e.global_position = pos
