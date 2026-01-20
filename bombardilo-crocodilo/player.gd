extends CharacterBody3D

@export var tile_size : float = 1.0  # Taille des cases
@export var speed : float = 0.3     # Vitesse de déplacement

@export var bomb_scene : PackedScene # La scène bomb.tscn

@export var bomb_stock : int = 3  # Le joueur commence avec 3 bombes
@export var explosion_range : int = 2

@onready var ray = $RayCast3D

@onready var anim_player = $Panda/AnimationPlayer
@onready var model = $Panda

var is_moving = false
var is_victorious = false
var is_dead = false
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
	# 1. Si on est en train de glisser vers une case, on laisse l'animation "Walk" tourner
	if is_moving:
		if anim_player.current_animation != "Walk":
			anim_player.play("Walk")
		return

	# 2. On récupère la direction maintenue
	var dir = Vector3.ZERO
	if Input.is_action_pressed("haut"): dir = Vector3.RIGHT
	elif Input.is_action_pressed("bas"): dir = Vector3.LEFT
	elif Input.is_action_pressed("gauche"): dir = Vector3.FORWARD
	elif Input.is_action_pressed("droite"): dir = Vector3.BACK

	# 3. GESTION DU MOUVEMENT ET DE L'ANIMATION
	if dir != Vector3.ZERO:
		last_facing_dir = dir 
		attempt_move(dir)
		
		# On joue Walk SEULEMENT s'il n'est pas déjà en train de jouer
		# C'est ça qui empêche le reset à chaque case !
		if anim_player.current_animation != "Walk":
			anim_player.play("Walk")
	else:
		# On ne joue Idle que si on ne bouge pas ET qu'on n'appuie sur rien
		# On vérifie aussi qu'on ne coupe pas une animation spéciale (Sword, No, etc.)
		var anim_speciales = ["Sword", "No", "Death", "Wave"]
		if not anim_player.current_animation in anim_speciales:
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle")

	# 4. Pose de bombe
	if Input.is_action_just_pressed("poser_bombe"):
		drop_bomb()

func attempt_move(direction: Vector3):
	ray.target_position = direction * tile_size
	ray.force_raycast_update()

	if not ray.is_colliding():
		# --- ROTATION FLUIDE ---
		# On calcule l'angle de base. 
		# Si le perso est encore à l'envers, on ajoutera le correctif ici.
		var target_angle = atan2(direction.x, direction.z)
		
		var rot_tween = create_tween()
		rot_tween.tween_property(model, "rotation:y", target_angle, 0.15)
		# -----------------------

		is_moving = true
		var target_pos = global_position + (direction * tile_size)
		
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_pos, speed)
		tween.finished.connect(func(): is_moving = false)
	else:
		anim_player.play("No")

func drop_bomb():
	if bomb_stock <= 0:
		print("Plus de munitions !")
		anim_player.play("No")
		return
		
	# 1. On oriente le RayCast vers la case devant pour vérifier s'il y a un mur
	ray.target_position = last_facing_dir * tile_size
	ray.force_raycast_update()

	if ray.is_colliding():
		print("Action impossible : un obstacle bloque la pose de la bombe !")
		anim_player.play("No")
		return

	# 2. Calcul de la position de la case juste devant (pour la vérification et le placement)
	var target_bomb_pos = global_position + (last_facing_dir * tile_size)
	var x = floor(target_bomb_pos.x / tile_size) * tile_size + (tile_size / 2.0)
	var z = floor(target_bomb_pos.z / tile_size) * tile_size + (tile_size / 2.0)
	var final_pos = Vector3(x, 1.5, z)

	# 3. VÉRIFICATION : Y a-t-il déjà une bombe ici ?
	var existing_bombs = get_tree().get_nodes_in_group("bombs")
	for b in existing_bombs:
		# Si une bombe est à moins de 0.5 mètre de la position cible, on refuse
		if b.global_position.distance_to(final_pos) < 0.5:
			print("Une bombe est déjà présente sur cette case !")
			anim_player.play("No")
			return

	# 4. Création de la bombe si la case est libre
	anim_player.play("Sword")

	var bomb = bomb_scene.instantiate()
	get_parent().add_child(bomb)
	
	bomb.explosion_size = explosion_range
	bomb.global_position = final_pos # On utilise la position calculée plus haut
	
	bomb_stock -= 1
	
	var hud = get_tree().current_scene.find_child("HUD", true)
	if hud:
		hud.update_bomb_count(bomb_stock)

func die():
	if is_dead: return 
	is_dead = true
	
	collision_layer = 0
	
	print("Touché !")
	
	var hud = get_tree().current_scene.find_child("HUD", true)
	var camera = get_viewport().get_camera_3d()
	
	set_physics_process(false)
	
	var will_be_game_over = false
	if hud and hud.lives - 1 <= 0:
		will_be_game_over = true
	
	var death_sound = AudioStreamPlayer.new()
	get_parent().add_child(death_sound)
	
	if will_be_game_over:
		death_sound.stream = load("res://assets/audio/player_death.wav")
		death_sound.volume_db = 0.0
		anim_player.speed_scale = 0.3 
		
		if camera:
			var tween_cam = create_tween().set_parallel(true)
			tween_cam.tween_property(camera, "fov", 30.0, 1.5).set_trans(Tween.TRANS_SINE)
			
			var target_pos = global_position + Vector3(0, 1.0, 0)
			var target_transform = camera.global_transform.looking_at(target_pos, Vector3.UP)
			# Utilisation de la bonne fonction Godot 4 ici :
			tween_cam.tween_property(camera, "quaternion", target_transform.basis.get_rotation_quaternion(), 1.5).set_trans(Tween.TRANS_SINE)
	else:
		death_sound.stream = load("res://assets/audio/fall.mp3")
		death_sound.volume_db = -30.0
		anim_player.speed_scale = 1.0

	death_sound.play()
	death_sound.finished.connect(death_sound.queue_free)

	anim_player.play("Death")
	
	var wait_time = 1.5 if not will_be_game_over else 4.0
	await get_tree().create_timer(wait_time).timeout
	
	if hud:
		hud.remove_life()
		if hud.lives > 0:
			respawn()
			set_physics_process(true)
			anim_player.play("Idle")

func respawn():
	# Petite animation de clignotement ou de reset
	is_dead = false
	is_moving = false
	collision_layer = 1
	# Les coordonnées de la case de départ
	global_position = Vector3(1.5, 2.0, 1.5) 
	snap_to_grid()
	
	set_physics_process(true)
	anim_player.play("Idle")
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("reset_position"):
			enemy.reset_position()

func win():
	if is_victorious: return 
	
	is_victorious = true
	is_moving = false 
	
	# On coupe les contrôles
	set_physics_process(false)
	
	# On calcule l'angle pour regarder vers -1 en X et 0 en Z
	var target_angle = atan2(-1.0, 0.0) 
	
	var rot_tween = create_tween()
	# On fait une rotation un peu plus lente (0.5s) pour que ce soit élégant
	rot_tween.tween_property(model, "rotation:y", target_angle, 0.5).set_trans(Tween.TRANS_SINE)
	
	if anim_player.has_animation("Wave"):
		# On récupère l'animation pour forcer la boucle par code
		var wave_anim = anim_player.get_animation("Wave")
		wave_anim.loop_mode = Animation.LOOP_LINEAR
		
		# On lance l'animation
		anim_player.play("Wave")
	
	print("Le Panda vous salue pour la victoire !")
	
	var hud = get_tree().current_scene.find_child("HUD", true)
	if hud:
		hud.show_victory_screen()

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
