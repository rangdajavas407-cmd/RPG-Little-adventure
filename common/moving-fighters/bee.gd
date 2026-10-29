extends CharacterBody2D

# dulu 10 (hampir diam, lebah tidak terasa mengejar); sekarang mengejar dengan jelas tapi masih bisa dihindari
var speed = 34
const CHASE_RANGE = 150
const KNOCKBACK = 22.0

var player

var directionBack=Vector2.ZERO

var shouldGoBack=false


func setPlayer(player_):
	player=player_

func getPlayer():
	return player

func _ready():
	add_to_group("Enemy")
	
	$AnimatedSprite2D.play()


func _process(delta):
	if shouldGoBack:
		move_and_collide(directionBack)
		shouldGoBack=false
		return
		
	
	var player_relative_position = getPlayer().getPlayerPosition() - position
	
	var direction = Vector2.ZERO
	
	if player_relative_position.length() <= 1:
		direction = Vector2.ZERO
	elif player_relative_position.length() <= CHASE_RANGE:
		direction = player_relative_position.normalized()
	
	move_and_collide(direction*delta*speed)
	
	if player_relative_position.length() > 10:
		directionBack=-1*direction*KNOCKBACK


func goBack():
	shouldGoBack=true

