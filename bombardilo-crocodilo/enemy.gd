extends CharacterBody3D

@export var speed : float = 0.5      # Temps pour parcourir une case
@export var tile_size : float = 1.0   # Taille des cases

@onready var ray = $RayCast3D
# --- AJOUTE CES RÉFÉRENCES ICI ---
@onready var anim_player = $Zombie/AnimationPlayer 
@onready var model = $Zombie
# ---------------------------------

var is_moving = false
var is_dead = false # Pour empêcher l'IA de bouger pendant qu'elle meurt
var target_player : Node3D = null
var start_position : Vector3

func _ready():
	add_to_group("enemies")
	target_player = get_tree().get_first_node_in_group("player")
	start_position = global_position
	
	if target_player:
		ray.add_exception(target_player)
	
	snap_to_grid()

func snap_to_grid():
	var x = floor(global_position.x / tile_size) * tile_size + (tile_size / 2.0)
	var z = floor(global_position.z / tile_size) * tile_size + (tile_size / 2.0)
	global_position = Vector3(x, global_position.y, z)

func _physics_process(_delta):
	# Si l'ennemi est mort ou déjà en mouvement, on ne fait rien
	if is_dead: return
	
	# Si l'animation Punch est en cours, on ne change pas d'animation
	if anim_player.current_animation == "Punch":
		return
	
	if is_moving:
		if anim_player.current_animation != "Walk":
			anim_player.play("Walk")
		return
	
	# Animation de repos
	if anim_player.current_animation != "Idle":
		anim_player.play("Idle")

	var next_dir = calculate_chase_direction()
	if next_dir != Vector3.ZERO:
		attempt_move(next_dir)

func calculate_chase_direction() -> Vector3:
	if not target_player: return Vector3.ZERO
	var diff = target_player.global_position - global_position
	
	if abs(diff.x) > abs(diff.z):
		return Vector3(sign(diff.x), 0, 0)
	else:
		return Vector3(0, 0, sign(diff.z))

func attempt_move(direction: Vector3):
	ray.target_position = direction * tile_size
	ray.force_raycast_update()

	if not ray.is_colliding():
		move_to_tile(direction)
	else:
		var alternate_dir = Vector3(direction.z, 0, direction.x) 
		ray.target_position = alternate_dir * tile_size
		ray.force_raycast_update()
		
		if not ray.is_colliding() and alternate_dir != Vector3.ZERO:
			move_to_tile(alternate_dir)

func move_to_tile(direction: Vector3):
	is_moving = true
	
	# --- ROTATION FLUIDE (Comme le player) ---
	var target_angle = atan2(direction.x, direction.z)
	var rot_tween = create_tween()
	rot_tween.tween_property(model, "rotation:y", target_angle, 0.15)
	# ------------------------------------------

	var target_pos = global_position + (direction * tile_size)
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, speed)
	tween.finished.connect(func(): is_moving = false)

func reset_position():
	is_moving = false
	is_dead = false
	global_position = start_position
	snap_to_grid()
	anim_player.play("Idle")

func die():
	if is_dead: return # Éviter de mourir deux fois
	
	is_dead = true
	is_moving = false
	print("Ennemi éliminé !")
	
	# ON JOUE L'ANIMATION DE MORT
	anim_player.play("Death")
	
	# On attend la fin de l'animation avant de supprimer l'ennemi
	await get_tree().create_timer(1.0).timeout 
	queue_free()

func _on_area_3d_body_entered(body):
	if is_dead: return 
	
	if body.is_in_group("player"):
		# 1. On arrête l'IA quelques instants
		is_moving = false 
		
		# 2. On oriente le Zombie face au joueur pour le coup de poing
		var look_dir = (body.global_position - global_position).normalized()
		var target_angle = atan2(look_dir.x, look_dir.z)
		model.rotation.y = target_angle
		
		# 3. On joue l'animation Punch
		if anim_player.has_animation("Punch"):
			anim_player.play("Punch")
		
		print("L'ennemi donne un coup au joueur !")
		
		# 4. On appelle la mort du joueur
		if body.has_method("die"):
			body.die()
