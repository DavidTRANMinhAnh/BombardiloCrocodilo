extends CanvasLayer

var score : int = 0
var lives : int = 3 # On commence avec 3 vies

@onready var score_label = $Control/ScoreLabel
@onready var lives_label = $Control/LivesLabel
@onready var bomb_label = $Control/BombLabel
@onready var game_over_panel = $GameOverPanel
@onready var victory_panel = $VictoryPanel
@onready var Retry_Button = $GameOverPanel/VBoxContainer/RetryButton
@onready var Menu_Button = $GameOverPanel/VBoxContainer/MenuButton

func _ready():
	game_over_panel.hide()
	update_ui()
	
	# Connexion des boutons du Panel (si tu ne l'as pas fait via l'éditeur)
	Retry_Button.pressed.connect(_on_retry_button_pressed)
	Menu_Button.pressed.connect(_on_menu_button_pressed)

func add_score(points):
	score += points
	update_ui()
	
func update_bomb_count(amount):
	bomb_label.text = "Bombes : " + str(amount)

func remove_life():
	lives -= 1
	update_ui()
	if lives <= 0:
		game_over()

func update_ui():
	score_label.text = "Score : " + str(score)
	lives_label.text = "Vies : " + str(lives)

func game_over():
	game_over_panel.show() # On affiche l'écran de fin

func show_victory_screen():
	victory_panel.show()

func _on_retry_button_pressed():
	# get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	# get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
