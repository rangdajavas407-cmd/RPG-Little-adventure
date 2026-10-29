extends StaticBody2D

# Darkus, peneliti di depan Ancient Dungeon. Menekan E -> sinyal talk
# (scene ancient-dungeon.gd mengurus dialog dan pemilihan class).

signal talk


func _on_talk_playerOpenedDoor():
	emit_signal("talk")

var _walk_tween: Tween = null
var _step_tween: Tween = null

# Bisa dipakai cutscene kapan pun NPC ini perlu berjalan ke titik tertentu.
func walk_to_global(target: Vector2, duration: float = 1.8) -> void:
	if _walk_tween and _walk_tween.is_running():
		_walk_tween.kill()
	_stop_step_animation()
	var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
	if sprite:
		var delta_x = target.x - global_position.x
		if abs(delta_x) > 1.0:
			sprite.flip_h = delta_x < 0.0
		_start_step_animation()
	_walk_tween = create_tween()
	_walk_tween.tween_property(self, "global_position", target, max(duration, 0.1)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _walk_tween.finished
	_stop_step_animation()

func _start_step_animation() -> void:
	var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		return
	if _step_tween and _step_tween.is_running():
		_step_tween.kill()
	sprite.offset = Vector2.ZERO
	sprite.scale = Vector2.ONE
	_step_tween = create_tween().set_loops()
	_step_tween.tween_property(sprite, "offset:y", -1.4, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_step_tween.parallel().tween_property(sprite, "scale", Vector2(1.02, 0.98), 0.14)
	_step_tween.tween_property(sprite, "offset:y", 0.5, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_step_tween.parallel().tween_property(sprite, "scale", Vector2(0.99, 1.01), 0.14)

func _stop_step_animation() -> void:
	if _step_tween and _step_tween.is_running():
		_step_tween.kill()
	var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
	if sprite:
		var settle = create_tween()
		settle.tween_property(sprite, "offset", Vector2.ZERO, 0.1)
		settle.parallel().tween_property(sprite, "scale", Vector2.ONE, 0.1)

