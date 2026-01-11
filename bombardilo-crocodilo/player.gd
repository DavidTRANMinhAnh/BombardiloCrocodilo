extends CharacterBody3D

@export var tile_size : float = 1.0  # Ajuste à 1.0 si tes cases sont petites
@export var speed : float = 0.2     # Vitesse du mouvement entre deux cases

@onready var ray = $RayCast3D
func _ready():
	# Aligne automatiquement le joueur sur la grille au lancement
	# On arrondit la position actuelle pour qu'elle tombe pile au milieu d'une case
	snap_to_grid()

func snap_to_grid():
	# Calcul pour centrer le joueur sur la case la plus proche
	var x = floor(global_position.x / tile_size) * tile_size + (tile_size / 2.0)
	var z = floor(global_position.z / tile_size) * tile_size + (tile_size / 2.0)
	
	# On garde le Y actuel (la hauteur) pour ne pas s'enfoncer dans le sol
	global_position = Vector3(x, global_position.y, z)
	
var is_moving = false

func _physics_process(_delta):
	if is_moving:
		return

	# Lecture des directions (Input System)
	var dir = Vector3.ZERO
	if Input.is_action_just_pressed("haut"): dir = Vector3.RIGHT
	elif Input.is_action_just_pressed("bas"): dir = Vector3.LEFT
	elif Input.is_action_just_pressed("gauche"): dir = Vector3.FORWARD
	elif Input.is_action_just_pressed("droite"): dir = Vector3.BACK

	if dir != Vector3.ZERO:
		attempt_move(dir)

func attempt_move(direction: Vector3):
	# On tourne le RayCast vers là où on veut aller
	ray.target_position = direction * tile_size
	ray.force_raycast_update()

	# Si le RayCast ne touche rien, on peut bouger (US02)
	if not ray.is_colliding():
		is_moving = true
		var target_pos = global_position + (direction * tile_size)
		
		# Animation fluide (Tween) pour l'US01
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_pos, speed)
		tween.finished.connect(func(): is_moving = false)
