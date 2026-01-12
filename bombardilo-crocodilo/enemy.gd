extends CharacterBody3D

@export var speed : float = 2.0
@export var tile_size : float = 1.0

@onready var ray = $RayCast3D
@onready var hitbox = $Area3D

var directions = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]
var current_dir = Vector3.FORWARD

func _ready():
	add_to_group("enemies") # Pour que l'explosion le reconnaisse
	hitbox.body_entered.connect(_on_player_touched)
	# Aligne l'ennemi sur la grille au départ
	global_position = global_position.snapped(Vector3(tile_size, 0, tile_size)) + Vector3(tile_size/2, 0, tile_size/2)

func _physics_process(delta):
	# On déplace l'ennemi
	velocity = current_dir * speed
	move_and_slide()
	
	# Mise à jour du RayCast pour regarder devant
	ray.target_position = current_dir * 0.6
	ray.force_raycast_update()
	
	# Si on va toucher un mur ou une brique
	if ray.is_colliding():
		change_direction()

func change_direction():
	# On mélange les directions et on en prend une nouvelle
	directions.shuffle()
	current_dir = directions[0]

func _on_player_touched(body):
	if body.is_in_group("player"):
		if body.has_method("die"):
			body.die()

func die():
	# Dans bomb.gd, au moment où la brique explose
	var hud = get_tree().current_scene.find_child("HUD", true)
	if hud:
		hud.add_score(100)
	print("Ennemi éliminé !")
	queue_free()
