extends CharacterBody3D

@export var tile_size : float = 1.0  # Taille des cases
@export var speed : float = 0.2     # Vitesse de déplacement

@export var bomb_scene : PackedScene # La scène bomb.tscn

@export var bomb_stock : int = 3  # Le joueur commence avec 3 bombes
@export var explosion_range : int = 2

@onready var ray = $RayCast3D

var is_moving = false
var last_facing_dir = Vector3.RIGHT
var can_check_victory = false
var enemies_detected = false
var portal_spawned = false

func _ready():
	snap_to_grid()
	await get_tree().create_timer(1.0).timeout
	can_check_victory = true

func snap_to_grid():
	var x = floor(global_position.x / tile_size) * tile_size + (tile_size / 2.0)
	var z = floor(global_position.z / tile_size) * tile_size + (tile_size / 2.0)
	global_position = Vector3(x, global_position.y, z)

func _physics_process(_delta):
	if is_moving:
		return

	var dir = Vector3.ZERO
	# On garde ton mapping spécifique
	if Input.is_action_just_pressed("haut"): dir = Vector3.RIGHT
	elif Input.is_action_just_pressed("bas"): dir = Vector3.LEFT
	elif Input.is_action_just_pressed("gauche"): dir = Vector3.FORWARD
	elif Input.is_action_just_pressed("droite"): dir = Vector3.BACK

	if dir != Vector3.ZERO:
		last_facing_dir = dir # On enregistre vers où le joueur regarde
		attempt_move(dir)
	
	if Input.is_action_just_pressed("poser_bombe"):
		drop_bomb()

func attempt_move(direction: Vector3):
	ray.target_position = direction * tile_size
	ray.force_raycast_update()

	if not ray.is_colliding():
		is_moving = true
		var target_pos = global_position + (direction * tile_size)
		
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_pos, speed)
		tween.finished.connect(func(): is_moving = false)
		
func drop_bomb():
	
	if bomb_stock <= 0:
		print("Plus de munitions !")
		return
		
	# 1. On oriente le RayCast vers la case devant pour vérifier s'il y a un mur
	ray.target_position = last_facing_dir * tile_size
	ray.force_raycast_update()

	# 2. Si le rayon touche quelque chose (un mur), on ne pose pas la bombe
	if ray.is_colliding():
		print("Action impossible : un obstacle bloque la pose de la bombe !")
		return

	# 3. Calcul de la position de la case juste devant
	var target_bomb_pos = global_position + (last_facing_dir * tile_size)

	# 4. Création de la bombe
	var bomb = bomb_scene.instantiate()
	get_parent().add_child(bomb)
	
	bomb.explosion_size = explosion_range
	
	bomb_stock -= 1
	
	var hud = get_tree().current_scene.find_child("HUD", true)
	if hud:
		hud.update_bomb_count(bomb_stock)
		
	# 5. Alignement de la bombe sur la case devant
	var x = floor(target_bomb_pos.x / tile_size) * tile_size + (tile_size / 2.0)
	var z = floor(target_bomb_pos.z / tile_size) * tile_size + (tile_size / 2.0)
	bomb.global_position = Vector3(x, 2, z)

func die():
	print("Touché !")
	
	set_physics_process(false)
	
	var tween = create_tween()
	tween.tween_property(self, "visible", false, 0.1)
	tween.tween_property(self, "visible", true, 0.1)
	tween.set_loops(5) # Clignote 5 fois
	
	await get_tree().create_timer(1.5).timeout # 1.5s d'invulnérabilité
	# 1. On cherche le HUD pour enlever une vie
	var hud = get_tree().current_scene.find_child("HUD", true)
	if hud:
		hud.remove_life()
		
		# 2. Si le joueur a encore des vies, on le remet au départ
		if hud.lives > 0:
			respawn()
			set_physics_process(true)

func respawn():
	# Petite animation de clignotement ou de reset
	is_moving = false
	# Les coordonnées de la case de départ
	global_position = Vector3(1.5, 2.0, 1.5) 
	snap_to_grid()
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("reset_position"):
			enemy.reset_position()

func _process(_delta):
	if not can_check_victory: 
		return
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	var count = enemies.size()

	# Logique de détection
	if count > 0 and not enemies_detected:
		enemies_detected = true

	# Condition de victoire
	if enemies_detected and count == 0:
		spawn_portal()

func spawn_portal():
	if portal_spawned: 
		return
	
	portal_spawned = true
	print("Victoire ! Le portail est activé.")
	
	var portal = get_tree().current_scene.find_child("Portal", true)
	
	if portal:
		portal.show() # Il devient visible
		# On change son mode pour qu'il commence à détecter les collisions
		portal.process_mode = Node.PROCESS_MODE_INHERIT 
	else:
		# Si tu n'as pas de portail dans la scène, on affiche le HUD direct
		var hud = get_tree().current_scene.find_child("HUD", true)
		if hud:
			hud.show_victory_screen()

func update_hud_bombs():
	var hud = get_tree().current_scene.find_child("HUD", true)
	if hud:
		hud.update_bomb_count(bomb_stock)
