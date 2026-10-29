extends Node2D

signal talk

var talkingEnabled=true


func _ready():
	$AnimatedSprite2D.play("default")
	talkingEnabled=true

# Pak Tukang sibuk memperbaiki sumur: tidak bisa diajak bicara (tanda E hilang)
func repair():
	$AnimatedSprite2D.play("repairing")
	talkingEnabled=false
	$talk.interactionEnabled=false

# Selesai memperbaiki: Pak Tukang kembali bisa diajak bicara
func idle():
	$AnimatedSprite2D.play("default")
	talkingEnabled=true
	$talk.interactionEnabled=true

# dipanggil setelah pemain menekan E di dekat Pak Tukang
func _on_talk_playerOpenedDoor():
	if talkingEnabled:
		emit_signal("talk")
