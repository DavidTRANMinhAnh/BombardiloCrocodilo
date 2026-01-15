extends CharacterBody3D

@export var speed : float = 0.5     # Temps pour parcourir une case (plus petit = plus rapide)
@export var tile_size : float = 1.0  # Taille des cases

@onready var ray = $RayCast3D

var is_moving = false
var target_player : Node3D = null

func _ready():
	add_to_group("enemies")
	# On récupère le joueur une seule fois au début
	target_player = get_tree().get_first_node_in_group("player")
	# On aligne l'ennemi sur la grille (.5) dès le départ
	snap_to_grid()

func snap_to_grid():
	var x = floor(global_position.x / tile_size) * tile_size + (tile_size / 2.0)
	var z = floor(global_position.z / tile_size) * tile_size + (tile_size / 2.0)
	global_position = Vector3(x, global_position.y, z)

func _physics_process(_delta):
	if is_moving:
		return

	# 1. Décider de la direction intelligente
	var next_dir = calculate_chase_direction()
	
	if next_dir != Vector3.ZERO:
		attempt_move(next_dir)

func calculate_chase_direction() -> Vector3:
	if not target_player:
		return Vector3.ZERO
		
	# On calcule la distance sur chaque axe
	var diff = target_player.global_position - global_position
	
	# On choisit l'axe où l'écart est le plus grand (X ou Z)
	# Cela empêche les diagonales : on ne bouge que sur un axe à la fois
	if abs(diff.x) > abs(diff.z):
		# Priorité à l'axe X
		return Vector3(sign(diff.x), 0, 0)
	else:
		# Priorité à l'axe Z
		return Vector3(0, 0, sign(diff.z))

func attempt_move(direction: Vector3):
	# On oriente le RayCast pour vérifier s'il y a un mur/brique
	ray.target_position = direction * tile_size
	ray.force_raycast_update()

	if not ray.is_colliding():
		move_to_tile(direction)
	else:
		# Si bloqué sur l'axe prioritaire, on essaie l'autre axe (pour contourner)
		var alternate_dir = Vector3(direction.z, 0, direction.x) # Inverse X et Z
		ray.target_position = alternate_dir * tile_size
		ray.force_raycast_update()
		
		if not ray.is_colliding() and alternate_dir != Vector3.ZERO:
			move_to_tile(alternate_dir)

func move_to_tile(direction: Vector3):
	is_moving = true
	var target_pos = global_position + (direction * tile_size)
	
	# On utilise un Tween pour un mouvement fluide mais calé sur la grille
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, speed)
	tween.finished.connect(func(): is_moving = false)

func die():
	print("Ennemi éliminé !")
	queue_free()
