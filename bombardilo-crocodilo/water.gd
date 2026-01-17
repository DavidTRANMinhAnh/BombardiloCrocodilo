extends MeshInstance3D

func _process(delta):
	# On fait défiler la texture pour simuler le courant
	var mat = get_active_material(0)
	mat.uv1_offset.x += delta * 0.05
	mat.uv1_offset.y += delta * 0.05
