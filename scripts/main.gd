extends Node

@onready var background_music = $BackgroundMusic
var music_playing := false
					  
# Carga previa de escena de obstáculos
var stump_scene = preload("res://scenes/stump.tscn")
var rock_scene = preload("res://scenes/rock.tscn")
var barrel_scene = preload("res://scenes/barrel.tscn")
var bird_scene = preload("res://scenes/bird.tscn")
var box_scene = preload("res://scenes/box.tscn")

var obstacle_types := [stump_scene, rock_scene, barrel_scene, box_scene]
var obstacles : Array
var bird_heights := [200, 390] # Alturas posibles para los pájaros

# Configuración del juego
const DINO_START_POS := Vector2i(150, 485)
const CAM_START_POS := Vector2i(576, 324)
const MAX_DIFFICULTY : int = 2
const SCORE_MODIFIER : int = 10
const START_SPEED : float = 6      
const MAX_SPEED : int = 25
const SPEED_MODIFIER : int = 5000

# Variables del juego
var difficulty : int
var score : int
var high_score : int
var speed : float
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var last_obs
	
func _ready():
	setup_game()

func setup_game():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	init_music()
	connect_buttons()
	new_game()
	
func init_music():
	background_music.stream = load("res://assets/sound/8-bit-Surf.ogg")
	background_music.volume_db = -10
	background_music.play()
	
func connect_buttons():
	$GameOver.get_node("Restart").pressed.connect(new_game)
	$GameOver.get_node("Menu").pressed.connect(main_menu)
	
func new_game(reset_high_score: bool = true):
	background_music.play()  # Reinicia la música
	# Reset variables
	score = 0
	game_running = false
	get_tree().paused = false
	difficulty = 0
	
	# Clear obstacles
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	# Reiniciar posiciones
	$Dino.position = DINO_START_POS
	$Dino.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)
	
	# Reset high score solo si se indica
	if reset_high_score:
		high_score = 0
	
	# Actualizar UI
	show_score()
	$HUD.get_node("StartLabel").show()
	$HUD.get_node("Controls").show()
	$GameOver.hide()
	
func main_menu():
	# Solo llama a new_game sin resetear el high score
	new_game(false)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	

func _process(delta):
	if game_running:

		# Aumenta la velocidad y ajusta la dificultad
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		adjust_difficulty()
		
		# Genera nuevos obstáculos
		generate_obs()
		
		# Mueve el dinosaurio y la cámara
		$Dino.position.x += speed
		$Camera2D.position.x += speed
		
		# Actualiza la puntuación
		score += speed
		show_score()
		
		# Reposiciona el suelo cuando sale de pantalla
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
			
		# Elimina obstáculos que ya no son visibles
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
	else:
		# Inicia el juego al presionar la tecla de acción
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()
			$HUD.get_node("Controls").hide()

func generate_obs():
	## Genera obstáculos en el suelo
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 5
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		# En máxima dificultad, posibilidad de generar pájaros
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2) == 0: # 50% de probabilidad
				# Generar aves de obstaculos
				obs = bird_scene.instantiate()
				var obs_x : int = screen_size.x + score + 100
				var obs_y : int = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)

func add_obs(obs, x, y):
	## Añade un obstáculo al juego
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)

func remove_obs(obs):
	## Elimina un obstáculo del juego
	obs.queue_free()
	obstacles.erase(obs)
	
func hit_obs(body):
	## Maneja la colisión con obstáculos
	if body.name == "Dino":
		game_over()

func show_score():
	## Muestra la puntuación en el HUD
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)

func check_high_score():
	## Comprueba y actualiza el récord
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(high_score / SCORE_MODIFIER)

func adjust_difficulty():
	## Ajusta la dificultad basada en la puntuación
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func game_over():
	## Maneja el fin del juego
	check_high_score()
	get_tree().paused = true
	game_running = false
	$GameOver.show()
	background_music.stop()
