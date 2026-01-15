extends Area3D

func _ready():
	# On attend que le joueur entre dans le portail
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Victoire !")
		var hud = get_tree().current_scene.find_child("HUD", true)
		if hud:
			hud.show_victory_screen()
