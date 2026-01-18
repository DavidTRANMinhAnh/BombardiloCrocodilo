extends Area3D

func _ready():
	# On attend que le joueur entre dans le portail
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# On vérifie si c'est bien le joueur qui entre
	if body.has_method("win"):
		body.win() # On appelle la fonction win() du joueur
