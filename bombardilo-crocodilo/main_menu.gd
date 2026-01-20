extends Node3D

# On récupère l'AnimationPlayer du modèle 3D
# Si ton Panda est dans un sous-nœud, ajuste le chemin (ex: $Panda/AnimationPlayer)
@onready var anim_player = $Panda/AnimationPlayer 

@onready var play_button = $UI/Control/MarginContainer/HBoxContainer/MenuButtons/PlayButton
@onready var quit_button = $UI/Control/MarginContainer/HBoxContainer/MenuButtons/QuitButton

func _ready():
	# --- ANIMATION DU PANDA ---
	if anim_player and anim_player.has_animation("Wave"):
		# On récupère la ressource d'animation pour la mettre en boucle
		var wave_anim = anim_player.get_animation("Wave")
		wave_anim.loop_mode = Animation.LOOP_LINEAR # Force la lecture en boucle
		
		# On lance l'animation
		anim_player.play("Wave")
	
	# --- CONNEXION DES BOUTONS ---
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	# On réinitialise le niveau à 1 si on recommence une partie
	LevelManager.current_level = 1
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit_pressed():
	var quit_sound = AudioStreamPlayer.new()
	add_child(quit_sound)
	quit_sound.stream = load("res://assets/audio/bombexplosion.wav") 
	quit_sound.volume_db = 0
	quit_sound.play()
	await get_tree().create_timer(1.0).timeout
	
	get_tree().quit()
