extends Area3D

# On définit les types possibles
enum BonusType { BOMB_COUNT, EXPLOSION_RANGE }

@export var type : BonusType = BonusType.BOMB_COUNT
@onready var mesh = $MeshInstance3D

func _ready():
	body_entered.connect(_on_body_entered)
	setup_appearance()

func setup_appearance():
	# On crée un matériau unique pour changer la couleur selon le type
	var material = StandardMaterial3D.new()
	
	if type == BonusType.BOMB_COUNT:
		material.albedo_color = Color.BLUE # Bleu pour les bombes
	else:
		material.albedo_color = Color.RED  # Rouge pour la portée
		
	mesh.set_surface_override_material(0, material)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if type == BonusType.BOMB_COUNT:
			body.bomb_stock += 3  # On donne 3 bombes
			body.update_hud_bombs() # On rafraîchit l'affichage
			print("Munitions ajoutées ! Total : ", body.bomb_stock)
		elif type == BonusType.EXPLOSION_RANGE:
			body.explosion_range += 1
		
		queue_free()
