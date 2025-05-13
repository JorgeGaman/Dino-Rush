extends Control

func _ready():
	# Conecta las señales de los botones
	$StartButton.pressed.connect(_on_start_button_pressed)
	$ExitButton.pressed.connect(_on_exit_button_pressed)

func _on_start_button_pressed():
	# Cambia a la escena del juego
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_exit_button_pressed():
	# Cierra el juego
	get_tree().quit()
