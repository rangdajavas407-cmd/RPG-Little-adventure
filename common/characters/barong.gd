extends StaticBody2D

# Barong, penjual di kios depan Ancient Dungeon. Menekan E -> sinyal talk
# (scene ancient-dungeon.gd membuka dialog lalu toko).

signal talk


func _on_talk_playerOpenedDoor():
	emit_signal("talk")
