extends Node3D

func _ready():
	# 1. On récupère le nœud AnimationPlayer
	var anim_player = $AnimationPlayer
	
	# 2. On vérifie si l'animation existe
	if anim_player.has_animation("fisherman2_from_mix"):
		# On récupère la ressource d'animation elle-même
		var anim_res = anim_player.get_animation("fisherman2_from_mix")
		
		# 3. On force le mode boucle par code
		# Animation.LOOP_LINEAR (valeur 1) : boucle normale
		# Animation.LOOP_PINGPONG (valeur 2) : va-et-vient
		anim_res.loop_mode = Animation.LOOP_LINEAR
		
		# 4. On lance l'animation
		anim_player.play("fisherman2_from_mix")
		
		# Optionnel : Tu peux aussi régler la vitesse ici
		# anim_player.speed_scale = 1.2
