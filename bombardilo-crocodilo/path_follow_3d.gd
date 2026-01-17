extends PathFollow3D

@export var speed : float = 2.0
@export var rotation_speed : float = 10.0 # Plus c'est haut, plus il tourne vite

@onready var model = $GermanShepherd

func _ready():
	# On active la boucle de l'animation par code pour être sûr
	var anim = $GermanShepherd/AnimationPlayer
	if anim.has_animation("Walk"):
		anim.get_animation("Walk").loop_mode = Animation.LOOP_LINEAR
		anim.play("Walk")

func _process(delta):
	# 1. On mémorise la position actuelle avant de bouger
	var pos_avant = global_position
	
	# 2. On avance sur le chemin
	progress += speed * delta
	
	# 3. On calcule la direction vers laquelle on se déplace
	var direction = global_position - pos_avant
	
	# On ne tourne que si le chien bouge vraiment
	if direction.length() > 0.001:
		# On calcule l'angle cible (vers où le chien doit regarder)
		var target_angle = atan2(direction.x, direction.z)
		
		# --- ROTATION SMOOTH ---
		# lerp_angle gère la transition fluide entre l'angle actuel et l'angle cible
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, rotation_speed * delta)
