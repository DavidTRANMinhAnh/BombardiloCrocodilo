extends Area3D

# On définit l'ID de la brique destructible (celui de ta MeshLibrary)
const BRICK_ID = 2 

func _ready():
	# 1. On lance les particules
	if has_node("GPUParticles3D"):
		$GPUParticles3D.emitting = true
	
	# 2. OPTIONNEL : Un flash de lumière rapide
	var light = OmniLight3D.new()
	add_child(light)
	light.light_color = Color.ORANGE
	light.light_energy = 5.0
	var lt = create_tween()
	lt.tween_property(light, "light_energy", 0.0, 0.3) # La lumière disparaît vite
	
	# 3. L'explosion disparaît après 0.6s (un peu après les particules)
	get_tree().create_timer(0.6).timeout.connect(queue_free)
	
	body_entered.connect(_on_body_entered)
	
	# On cherche le GridMap dans la scène Main
	var gridmap = get_tree().root.find_child("GridMap", true)
	
	if gridmap:
		# 1. Convertir la position de l'explosion en coordonnées de grille
		var map_pos = gridmap.local_to_map(global_position)
		
		# 2. Regarder quel objet est sur cette case
		var cell_id = gridmap.get_cell_item(map_pos)
		
		# 3. Si c'est une brique (ID 2), on la supprime
		if cell_id == BRICK_ID:
			gridmap.set_cell_item(map_pos, -1) # -1 signifie "vide"
			print("Brique détruite !")
			
func _on_body_entered(body):
	# Si l'objet (joueur ou ennemi) a une fonction die(), on l'appelle
	if body.has_method("die"):
		body.die()
