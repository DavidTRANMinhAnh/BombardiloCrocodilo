extends Camera3D

var shake_strength : float = 0.0
var shake_decay : float = 5.0 # Vitesse à laquelle le tremblement s'arrête

func _process(delta):
	if shake_strength > 0:
		# On réduit la force petit à petit
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		
		# On applique un décalage aléatoire
		h_offset = randf_range(-shake_strength, shake_strength)
		v_offset = randf_range(-shake_strength, shake_strength)
	else:
		# On remet à zéro quand c'est fini
		h_offset = 0
		v_offset = 0

# La fonction qu'on appellera depuis l'explosion
func apply_shake(intensity: float):
	shake_strength = intensity
