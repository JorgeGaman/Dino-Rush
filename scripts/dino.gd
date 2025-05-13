extends CharacterBody2D

signal jumped

const GRAVITY : int = 4200
const JUMP_SPEED : int = -1800
@onready var jump_sound = $JumpSound
var is_jumping = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	velocity.y += GRAVITY * delta
	
	if is_on_floor():
		is_jumping = false
		if not get_parent().game_running:
			$AnimatedSprite2D.play("idle")
		else:
			$RunCol.disabled = false
			if Input.is_action_just_pressed("ui_accept"):  # Cambiado a is_action_just_pressed
				velocity.y = JUMP_SPEED
				is_jumping = true
				if not $JumpSound.playing:  # Solo reproducir si no está sonando
					$JumpSound.stop()       # Detener cualquier sonido previos
					$JumpSound.play()
			elif Input.is_action_pressed("duck"):
				$AnimatedSprite2D.play("duck")
				$RunCol.disabled = true
			else:
				$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("jump")
		# Eliminado el sonido de salto en el aire para evitar repeticiones

		
	move_and_slide()
