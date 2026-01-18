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
@onready var restart_button = $Control/RestartButton

func _ready():
	game_over_panel.hide()
	update_ui()
	
	# Connexion des boutons du Panel (si tu ne l'as pas fait via l'éditeur)
	Retry_Button.pressed.connect(_on_retry_button_pressed)
	Menu_Button.pressed.connect(_on_menu_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)

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
	var lost_sound = AudioStreamPlayer.new()
	add_child(lost_sound)
	lost_sound.stream = load("res://assets/audio/tu-as-perdu.mp3")
	lost_sound.volume_db = -15.0 # On le met un peu moins fort que l'explosion
	lost_sound.play()

func show_victory_screen():
	victory_panel.show()
	var victory_sound = AudioStreamPlayer.new()
	add_child(victory_sound)
	victory_sound.stream = load("res://assets/audio/victory.wav")
	victory_sound.volume_db = -15.0 # On le met un peu moins fort que l'explosion
	victory_sound.play()

func _on_retry_button_pressed():
	# get_tree().paused = false
	var retry_sound = AudioStreamPlayer.new()
	add_child(retry_sound)
	retry_sound.stream = load("res://assets/audio/okay-naps.mp3")
	retry_sound.volume_db = -15.0 # On le met un peu moins fort que l'explosion
	retry_sound.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()

func _on_next_level_button_pressed():
	# On appelle la classe globale directement
	LevelManager.current_level += 1 
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	# get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_restart_button_pressed():
	# On joue le petit son de confirmation
	var s = AudioStreamPlayer.new()
	add_child(s)
	s.stream = load("res://assets/audio/okay-naps.mp3") # Ton son de retry
	s.volume_db = -15.0
	s.play()
	s.finished.connect(s.queue_free)
	
	# On attend un tout petit peu que le son commence
	await get_tree().create_timer(0.5).timeout
	
	# Comme on utilise LevelManager.current_level (static), 
	# reload_current_scene va relancer le bon niveau tout seul !
	get_tree().reload_current_scene()
