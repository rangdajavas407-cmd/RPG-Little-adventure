extends Node

# Cutscene terpisah setelah Satan kalah. Tidak memakai sistem giliran / HUD battle.
signal finished

const EnemySprites = preload("res://common/fighters/enemySprites.gd")
const DefaultTheme = preload("res://common/themes/default.tres")
# v9.14: sprite Darkus khusus cutscene (jalan masuk, terikat benang merah, terangkat)
const DarkusSprites = preload("res://screens/ancient-dungeon/darkus/darkusCutsceneSprites.gd")
# Telapak kaki Darkus lama kira-kira 30 px di bawah titik tengah; sprite baru 46 px. Selisihnya dipakai sebagai offset.
# v9.18: Darkus setinggi Bunda (44 px x 0.75 = 33 px). Offset dihitung supaya telapak tetap 30 px di bawah titik tengah.
const DARKUS_SCALE = 0.75
const DARKUS_OFFSET_Y = 30.0 / DARKUS_SCALE - DarkusSprites.FEET_BELOW_CENTER

# v9.18: sprite Darkus diperkecil (badan 54 -> 44 px), efek lilitan ikut diperkecil
const FX_K = 0.82
const SATAN_POS = Vector2(864, 78)
const DARKUS_START = Vector2(620, 92)
const DARKUS_STOP = Vector2(760, 80)
const TOP_BAR_H = 22.0
const BOTTOM_BAR_H = 42.0
const TEXT_COLOR = Color(0.92, 0.94, 1.0)
const SATAN_COLOR = Color(1.0, 0.32, 0.28)

var dungeon
var cameraNode
var ui
var topBar
var bottomBar
var dialogue
var flash
var fade
var darkusSprite
var satanSprite
var bindingFx
var rng = RandomNumberGenerator.new()

func setup(scene_):
    dungeon = scene_

func play():
    rng.randomize()
    var player = dungeon.getPlayer()
    player.disableNavigation()
    _hideGameUi(player)
    _buildUi()
    _makeCamera(player)

    var bars = create_tween()
    bars.tween_property(topBar, "position:y", 0.0, 0.55)
    bars.parallel().tween_property(bottomBar, "position:y", _screenSize().y - BOTTOM_BAR_H, 0.55)
    await _panCamera(SATAN_POS + Vector2(0, 14), 0.9)

    await _say("Satan meraung, suaranya mengguncang seluruh ruangan. ‘Tidak… aku tidak mungkin kalah!’", SATAN_COLOR, 1.5)
    _shake(3.0, 1.1)
    _flash(Color(0.85, 0.06, 0.08), 0.65, 0.7)
    _smokeBurst(SATAN_POS + Vector2(0, 16), 24)
    await _say("Tubuh Satan runtuh menjadi asap hitam. Debu berjatuhan dari langit-langit. Untuk sesaat, dungeon itu sunyi…", TEXT_COLOR, 1.7)

    # Darkus masuk dari lorong setelah mendengar gemuruh.
    darkusSprite = AnimatedSprite2D.new()
    darkusSprite.sprite_frames = DarkusSprites.build()
    darkusSprite.position = DARKUS_START
    darkusSprite.z_index = 25
    darkusSprite.scale = Vector2(DARKUS_SCALE, DARKUS_SCALE)
    darkusSprite.offset = Vector2(0, DARKUS_OFFSET_Y)
    dungeon.get_node("sorted").add_child(darkusSprite)
    darkusSprite.play("walk")
    await _panCamera((DARKUS_START + SATAN_POS) * 0.5 + Vector2(0, 12), 0.8)
    await _say("Dari lorong terdengar langkah kaki yang tergesa. Darkus berlari masuk, lalu berhenti saat melihat bekas pertarungan.", TEXT_COLOR, 1.0)
    var run = create_tween()
    run.tween_method(_runDarkus, 0.0, 1.0, 2.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    await run.finished
    darkusSprite.position = DARKUS_STOP
    darkusSprite.play("idle")
    var landing = darkusSprite.create_tween()
    landing.tween_property(darkusSprite, "position:y", DARKUS_STOP.y + 3.0, 0.12)
    landing.tween_property(darkusSprite, "position:y", DARKUS_STOP.y, 0.16)
    await landing.finished
    _addIdleBreath(darkusSprite)
    # Kamera mendekat sebentar ke wajah Darkus sebelum dialog, lalu kembali ke dua karakter.
    await _panCamera(DARKUS_STOP + Vector2(-8, -5), 0.42)
    await _say("Darkus: ‘Aku mendengar gemuruh sampai ke luar! Ranbyus, kau tidak apa-apa? Apa yang terjadi di sini?’", TEXT_COLOR, 1.8)
    await _say("Ranbyus: ‘Aku baru saja mengalahkan—’", TEXT_COLOR, 1.1)

    # Satan muncul kembali dari sisa asap dan mengenali Darkus.
    satanSprite = AnimatedSprite2D.new()
    satanSprite.sprite_frames = EnemySprites.build("satan")
    satanSprite.position = SATAN_POS
    satanSprite.scale = Vector2(0.72, 0.72)
    satanSprite.modulate = Color(1.0, 0.18, 0.16, 0.0)
    satanSprite.z_index = 30
    dungeon.get_node("sorted").add_child(satanSprite)
    satanSprite.play("idle")
    _smokeBurst(SATAN_POS + Vector2(0, 18), 20)
    var satanIn = satanSprite.create_tween()
    satanIn.tween_property(satanSprite, "modulate", Color(1.35, 0.3, 0.26, 0.96), 0.9)
    satanIn.parallel().tween_property(satanSprite, "scale", Vector2(1.05, 1.05), 0.9)
    await satanIn.finished
    _addIdleBreath(satanSprite)
    await _panCamera(SATAN_POS + Vector2(-20, 12), 0.55)
    await _say("Satan: ‘Akhirnya… kau datang juga, Darkus. Inilah wadah yang selama ini kucari.’", SATAN_COLOR, 1.5)
    _shake(1.8, 0.8)
    await _say("Bayangan hitam merayap dari kaki Darkus. Ia mencoba mundur, tetapi aura merah telah melilit kedua lengannya.", SATAN_COLOR, 1.5)

    # Benang merah melilit Darkus (sprite terikat): berdiri -> terlilit -> lingkaran ritual -> mulai terangkat.
    _stopIdleBreath(darkusSprite)
    darkusSprite.offset = Vector2(0, DARKUS_OFFSET_Y)
    _smokeBurst(darkusSprite.position + Vector2(0, -8), 18)
    darkusSprite.play("bind")
    await _wait(0.85)
    darkusSprite.play("float")

    # Lingkaran ritual menyala, Darkus diangkat dan ditarik ke Satan.
    var sigil = dungeon.ritual.sigil if dungeon.ritual != null else null
    if sigil != null:
        var energyTween = create_tween()
        energyTween.tween_property(sigil, "energy", 1.0, 0.8)
    _shake(2.6, 1.8)
    _flash(Color(0.9, 0.05, 0.08), 0.35, 0.6)
    await _say("Simbol ritual menyala merah. Ikatan energi membelit tubuh Darkus dan mengangkatnya dari lantai. ‘Apa—?! Lepaskan aku!’", TEXT_COLOR, 1.5)
    _makeBindings()
    var pull = create_tween()
    pull.tween_method(_pullDarkus, 0.0, 1.0, 1.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
    pull.parallel().tween_property(darkusSprite, "modulate", Color(1.3, 0.85, 0.85), 1.0)
    for i in 4:
        _smokeFlow(DARKUS_STOP + Vector2(0, -10), SATAN_POS + Vector2(0, 4), 10, 0.8)
        await _wait(0.18)
    await pull.finished
    _shake(3.2, 0.9)
    if is_instance_valid(bindingFx):
        var snap = bindingFx.create_tween()
        snap.tween_property(bindingFx, "scale", Vector2(1.8, 1.8), 0.22)
        snap.parallel().tween_property(bindingFx, "modulate:a", 0.0, 0.22)
        await snap.finished
        bindingFx.queue_free()
        bindingFx = null
    _flash(Color(1.0, 0.05, 0.08), 0.4, 0.45)
    await _say("Darkus: ‘Tidak! Lepaskan aku! Aku tidak akan menjadi wadahmu!’", TEXT_COLOR, 1.7)
    _smokeBurst(darkusSprite.position + Vector2(0, -18), 24)
    await _say("Cahaya merah mengunci tubuh Darkus. Asap hitam menyusup ke dadanya, sementara suaranya perlahan berubah menjadi geraman.", SATAN_COLOR, 1.4)

    # Satan menjadi asap dan masuk ke Darkus; lalu perubahan wujud.
    var satanFade = satanSprite.create_tween()
    satanFade.tween_property(satanSprite, "modulate:a", 0.0, 0.8)
    satanFade.parallel().tween_property(satanSprite, "scale", Vector2(0.15, 0.15), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    _smokeFlow(SATAN_POS + Vector2(0, 4), darkusSprite.position + Vector2(0, -14), 48, 0.9)
    _smokeBurst(darkusSprite.position + Vector2(0, -12), 22)
    await satanFade.finished
    satanSprite.queue_free()
    _flash(Color(0.92, 0.03, 0.1), 0.8, 0.75)
    _shake(4.0, 1.2)

    # URUTAN PENTING: Darkus normal -> animasi MORPH -> baru wujud iblis.
    # Sprite sheet morph berisi tahap perubahan dari Darkus biasa sampai Darkus iblis.
    var possessedFrames = EnemySprites.build("darkus_iblis", true)
    DarkusSprites.addIblisCast(possessedFrames)
    possessedFrames.set_animation_speed("morph", 2.4)
    _stopIdleBreath(darkusSprite)
    # telapak iblis (sheet 64 px, kaki 29 px di bawah titik tengah) tetap di tanah yang sama setelah skala berubah
    darkusSprite.offset = Vector2(0, 30.0 / 0.85 - 29.0)
    darkusSprite.sprite_frames = possessedFrames
    darkusSprite.scale = Vector2(0.85, 0.85)
    darkusSprite.modulate = Color(0.18, 0.02, 0.08, 1.0)
    darkusSprite.play("morph")

    # Aura hitam menyelimuti perubahan, lalu kilatan merah menandai tahap akhir.
    _smokeBurst(darkusSprite.position + Vector2(0, -12), 26)
    var morphAura = darkusSprite.create_tween()
    morphAura.tween_property(darkusSprite, "modulate", Color(1.45, 0.12, 0.2, 1.0), 0.75)
    await morphAura.finished
    await darkusSprite.animation_finished

    # Baru setelah seluruh frame morph selesai, tampilkan sprite iblis final.
    darkusSprite.play("idle")
    darkusSprite.modulate = Color(1.6, 0.18, 0.22, 1.0)
    _flash(Color(1.0, 0.02, 0.08), 0.5, 0.55)
    _smokeBurst(darkusSprite.position + Vector2(0, -12), 20)
    var settle = darkusSprite.create_tween()
    settle.tween_property(darkusSprite, "modulate", Color.WHITE, 0.9)
    await settle.finished
    await _say("Sosok Satan lenyap. Darkus terdiam—lalu mengangkat kepala dengan tatapan yang bukan lagi miliknya. Satan telah mengambil alih tubuhnya.", SATAN_COLOR, 1.4)
    # v9.18: Darkus iblis melepas benang merah (sprite baru) sebelum judul boss
    darkusSprite.play("cast")
    _shake(2.0, 1.2)
    _flash(Color(0.9, 0.05, 0.08), 0.3, 0.5)
    _smokeBurst(darkusSprite.position + Vector2(10, -14), 18)
    await darkusSprite.animation_finished
    await _say("BOSS TERAKHIR\nDARKUS — WADAH SATAN", SATAN_COLOR, 1.8)

    var out = create_tween()
    out.tween_property(fade, "color:a", 1.0, 0.75)
    await out.finished
    finished.emit()


func _makeBindings():
    # Tiga lilitan energi merah + garis silang, menempel pada Darkus saat ia terangkat.
    bindingFx = Node2D.new()
    bindingFx.name = "DarkusEnergyBindings"
    bindingFx.z_index = 45
    darkusSprite.add_child(bindingFx)
    for ringIndex in 3:
        var ring = Line2D.new()
        ring.width = 2.8 if ringIndex == 1 else 2.0
        ring.default_color = Color(1.0, 0.025, 0.09, 0.96)
        ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
        ring.end_cap_mode = Line2D.LINE_CAP_ROUND
        ring.joint_mode = Line2D.LINE_JOINT_ROUND
        var radius = (25.0 + ringIndex * 3.0) * FX_K
        var yCenter = (-12.0 + ringIndex * 18.0) * FX_K
        for pointIndex in 33:
            var angle = TAU * float(pointIndex) / 32.0
            ring.add_point(Vector2(cos(angle) * radius, yCenter + sin(angle) * 7.0 * FX_K))
        bindingFx.add_child(ring)
    for crossIndex in 2:
        var chain = Line2D.new()
        chain.width = 2.0
        chain.default_color = Color(1.0, 0.08, 0.13, 0.88)
        chain.add_point(Vector2(-25, -42 if crossIndex == 0 else 30) * FX_K)
        chain.add_point(Vector2(0, -8) * FX_K)
        chain.add_point(Vector2(25, 30 if crossIndex == 0 else -42) * FX_K)
        bindingFx.add_child(chain)
    var spin = bindingFx.create_tween()
    spin.set_loops()
    spin.tween_property(bindingFx, "rotation", TAU, 1.15).from(0.0)
    var pulse = bindingFx.create_tween()
    pulse.set_loops()
    pulse.tween_property(bindingFx, "scale", Vector2(1.08, 1.08), 0.24)
    pulse.tween_property(bindingFx, "scale", Vector2(0.96, 0.96), 0.24)

func _runDarkus(t):
    # v9.18: tanpa goyangan vertikal buatan; naik-turun badan sudah ada di animasi jalan
    darkusSprite.position = DARKUS_START.lerp(DARKUS_STOP, t)

func _pullDarkus(t):
    # sprite terikat sudah melayang sendiri dan membawa lingkaran ritualnya, jadi cukup bergeser sedikit ke arah Satan
    darkusSprite.position = DARKUS_STOP.lerp(SATAN_POS + Vector2(0, -22), t * 0.2) + Vector2(0, -sin(t * PI) * 8.0)

# Napas/ayunan mikro pada karakter diam agar adegan terasa hidup tanpa mengubah sprite sheet.
func _addIdleBreath(sprite_):
    if sprite_ == null or !is_instance_valid(sprite_):
        return
    var baseY = sprite_.offset.y
    var breath = sprite_.create_tween().set_loops()
    breath.tween_property(sprite_, "offset:y", baseY - 1.0, 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    breath.tween_property(sprite_, "offset:y", baseY, 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    sprite_.set_meta("breathTween", breath)

func _stopIdleBreath(sprite_):
    if sprite_ == null or !is_instance_valid(sprite_) or !sprite_.has_meta("breathTween"):
        return
    var breath = sprite_.get_meta("breathTween")
    if breath != null and breath.is_valid():
        breath.kill()
    sprite_.remove_meta("breathTween")


func _screenSize():
    return get_viewport().get_visible_rect().size

func _wait(seconds_):
    return get_tree().create_timer(seconds_).timeout

func _buildUi():
    var size = _screenSize()
    ui = CanvasLayer.new()
    ui.layer = 80
    dungeon.add_child(ui)
    topBar = ColorRect.new()
    topBar.color = Color.BLACK
    topBar.size = Vector2(size.x, TOP_BAR_H)
    topBar.position = Vector2(0, -TOP_BAR_H)
    topBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(topBar)
    bottomBar = ColorRect.new()
    bottomBar.color = Color.BLACK
    bottomBar.size = Vector2(size.x, BOTTOM_BAR_H)
    bottomBar.position = Vector2(0, size.y)
    bottomBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(bottomBar)
    dialogue = Label.new()
    dialogue.theme = DefaultTheme
    dialogue.position = Vector2(10, size.y - BOTTOM_BAR_H + 3)
    dialogue.size = Vector2(size.x - 20, BOTTOM_BAR_H - 6)
    dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    dialogue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue.add_theme_font_size_override("font_size", 7)
    dialogue.add_theme_color_override("font_outline_color", Color.BLACK)
    dialogue.add_theme_constant_override("outline_size", 3)
    dialogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(dialogue)
    flash = ColorRect.new()
    flash.color = Color(1, 1, 1, 0)
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(flash)
    fade = ColorRect.new()
    fade.color = Color(0.01, 0, 0.02, 0)
    fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fade.mouse_filter = Control.MOUSE_FILTER_STOP
    ui.add_child(fade)

func _hideGameUi(player_):
    for nodeName in ["HUD", "navigation"]:
        var node = player_.get_node_or_null(nodeName)
        if node != null:
            node.visible = false

func _makeCamera(player_):
    var playerCam = player_.getPlayerBody().get_node_or_null("Camera2D")
    if playerCam == null:
        return
    cameraNode = Camera2D.new()
    cameraNode.position = playerCam.get_screen_center_position()
    cameraNode.limit_left = playerCam.limit_left
    cameraNode.limit_top = playerCam.limit_top
    cameraNode.limit_right = playerCam.limit_right
    cameraNode.limit_bottom = playerCam.limit_bottom
    dungeon.add_child(cameraNode)
    cameraNode.enabled = true
    cameraNode.make_current()

func _panCamera(target_, seconds_):
    if cameraNode == null:
        return
    var tw = create_tween()
    tw.tween_property(cameraNode, "position", target_, seconds_).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    await tw.finished

func _say(text_, color_, hold_):
    dialogue.text = text_
    dialogue.add_theme_color_override("font_color", color_)
    if !GlobalPlayer.isDialogAnimationEnabled():
        dialogue.visible_ratio = 1.0
    else:
        dialogue.visible_ratio = 0.0
        var tw = create_tween()
        tw.tween_property(dialogue, "visible_ratio", 1.0, 0.018 * text_.length() + 0.12)
        await tw.finished
    await _wait(hold_)

func _shake(strength_, seconds_):
    var elapsed = 0.0
    while elapsed < seconds_ and cameraNode != null and is_instance_valid(cameraNode):
        cameraNode.offset = Vector2(rng.randf_range(-strength_, strength_), rng.randf_range(-strength_, strength_))
        await get_tree().process_frame
        elapsed += get_process_delta_time()
    if cameraNode != null and is_instance_valid(cameraNode):
        cameraNode.offset = Vector2.ZERO

func _flash(color_, alpha_, seconds_):
    flash.color = Color(color_.r, color_.g, color_.b, alpha_)
    var tw = create_tween()
    tw.tween_property(flash, "color:a", 0.0, seconds_)

func _smokeBurst(center_, count_):
    for i in count_:
        var puff = ColorRect.new()
        var size = rng.randf_range(4.0, 8.0)
        var shade = rng.randf_range(0.03, 0.16)
        puff.color = Color(shade, shade * 0.3, shade * 0.65, 0.88)
        puff.size = Vector2(size, size)
        puff.position = center_ + Vector2(rng.randf_range(-18, 18), rng.randf_range(-6, 8))
        puff.z_index = 35
        dungeon.get_node("sorted").add_child(puff)
        var tw = puff.create_tween()
        tw.tween_interval(rng.randf_range(0.0, 0.25))
        tw.tween_property(puff, "position", puff.position + Vector2(rng.randf_range(-22, 22), -rng.randf_range(24, 56)), rng.randf_range(0.8, 1.4))
        tw.parallel().tween_property(puff, "modulate:a", 0.0, 1.1)
        tw.tween_callback(puff.queue_free)

func _smokeFlow(from_, to_, count_, duration_):
    for i in count_:
        var puff = ColorRect.new()
        var size = rng.randf_range(3.0, 6.0)
        puff.size = Vector2(size, size)
        puff.color = Color(0.08, 0.01, 0.07, 0.92).lerp(Color(0.8, 0.05, 0.12, 0.9), rng.randf())
        puff.position = from_ + Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10))
        puff.z_index = 36
        dungeon.get_node("sorted").add_child(puff)
        var control = (from_ + to_) * 0.5 + Vector2(rng.randf_range(-28, 28), rng.randf_range(-46, -12))
        var tw = puff.create_tween()
        tw.tween_interval(rng.randf_range(0.0, 0.25))
        tw.tween_method(func(t): puff.position = from_.lerp(control, t).lerp(control.lerp(to_, t), t), 0.0, 1.0, duration_)
        tw.parallel().tween_property(puff, "modulate:a", 0.0, duration_)
        tw.tween_callback(puff.queue_free)
