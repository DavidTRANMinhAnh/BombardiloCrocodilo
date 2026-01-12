extends Control

func _on_level_1_button_pressed():
	# Remplace "main.tscn" par le nom exact de ta scène de jeu
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
