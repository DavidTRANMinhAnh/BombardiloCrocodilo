extends CharacterBody3D

@export var tile_size : float = 1.0  # Taille des cases
@export var speed : float = 0.2     # Vitesse de déplacement

@export var bomb_scene : PackedScene # La scène bomb.tscn

@onready var ray = $RayCast3D

var is_moving = false
var last_facing_dir = Vector3.RIGHT # Direction par défaut (correspond à "haut" dans ton code)

func _ready():
	snap_to_grid()

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
	
	# 5. Alignement de la bombe sur la case devant
	var x = floor(target_bomb_pos.x / tile_size) * tile_size + (tile_size / 2.0)
	var z = floor(target_bomb_pos.z / tile_size) * tile_size + (tile_size / 2.0)
	bomb.global_position = Vector3(x, 2, z)

func die():
	print("Touché !")
	
	# 1. On cherche le HUD pour enlever une vie
	var hud = get_tree().current_scene.find_child("HUD", true)
	if hud:
		hud.remove_life()
		
		# 2. Si le joueur a encore des vies, on le remet au départ
		if hud.lives > 0:
			respawn()
		# Si 0 vies, le HUD s'occupe déjà de reload_current_scene()

func respawn():
	# Petite animation de clignotement ou de reset
	is_moving = false
	# Les coordonnées de la case de départ
	global_position = Vector3(1.5, 2.0, 1.5) 
	snap_to_grid()
