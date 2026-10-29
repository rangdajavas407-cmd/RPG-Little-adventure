extends Node2D

signal attackFinished
signal damageFinished
signal dieFinished

var currentAnim=TYPE_ANIM.IDLE

enum TYPE_ANIM {ATTACK,DAMAGE,IDLE,DIE}

# point au-dessus de la tete (pour les degats affiches)
const HEAD_OFFSET=Vector2(0, -4)

const HeroClass=preload("res://common/class/hero_class.gd")
const ClassSprites=preload("res://common/fighters/classSprites.gd")
const WeaponFx=preload("res://common/fighters/weaponFx.gd")

const PROJECTILE_TIME=0.28

# sasaran proyektil (diisi oleh scene pertarungan)
var targetPosition=null
# tampilan yang dipakai (class atau HeroClass.HERO), menentukan gaya proyektil
var skin=HeroClass.HERO
var currentAttack=""
# jenis serangan yang sedang dimainkan: physical / magic / ranged
var currentKind="physical"
# senjata yang dipegang (menentukan gaya efek) dan efek visualnya (lihat weaponFx.gd)
var weaponId=-1
var fx=WeaponFx.new()
# gerak badan saat menyerang digeser lewat sprite (bukan node ini) supaya posisi petarung tetap aman
var _spriteHome=Vector2.ZERO
var _pose=null

func _ready():
	# tampilan & animasi mengikuti SENJATA yang sedang dipakai (pedang kayu, tongkat kayu, atau senjata class)
	var playerClass=GlobalPlayer.getPlayerClass()
	weaponId=GlobalPlayer.getActiveWeaponId()
	skin=ClassSprites.getSkin(playerClass,weaponId)
	$AnimatedSprite2D.sprite_frames=ClassSprites.buildForWeapon(playerClass,weaponId)
	_spriteHome=$AnimatedSprite2D.position
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	playIdle()

# nama animasi dari data serangan -> animasi class (simple / advanced / special)
func _resolveAttack(animation_):
	var name=str(animation_)
	if name.contains("ultimate"):
		return "attack_special"
	if name.contains("advanced"):
		return "attack_advanced"
	if name.contains("onfire") or name.contains("special"):
		return "attack_special"
	return "attack_simple"

# proyektil dilepas pada frame tertentu (khusus Pemanah & Penyihir)
func _on_frame_changed():
	if currentAnim!=TYPE_ANIM.ATTACK:
		return
	fx.onFrame(self,weaponId,currentAttack,currentKind,$AnimatedSprite2D.frame)
	if HeroClass.getLaunchFrames(skin,currentAttack,currentKind).has($AnimatedSprite2D.frame):
		_launchProjectile()

func _launchProjectile():
	var path=HeroClass.getProjectilePath(skin,currentAttack,currentKind)
	if path=="" or get_parent()==null:
		return
	var sprite=Sprite2D.new()
	sprite.texture=load(path)
	sprite.z_index=50
	get_parent().add_child(sprite)
	var from=global_position+HeroClass.getProjectileOrigin(skin,currentKind)
	var to=targetPosition if targetPosition!=null else global_position+Vector2(110,-40)
	sprite.global_position=from
	var flaming=currentAttack=="attack_special"
	var style=HeroClass.getProjectileStyle(skin,currentKind)
	fx.onLaunch(self,from,weaponId,currentAttack,currentKind)
	if style=="aim":
		sprite.rotation=(to-from).angle()
	var tween=sprite.create_tween()
	if style=="arc":
		# botol ramuan dilempar melengkung sambil berputar
		var time=PROJECTILE_TIME*1.4
		tween.tween_method(_arcStep.bind(sprite,from,to),0.0,1.0,time)
		tween.parallel().tween_property(sprite,"rotation",TAU*2,time)
	else:
		tween.tween_property(sprite,"global_position",to,PROJECTILE_TIME).set_trans(Tween.TRANS_LINEAR)
		if style=="spin":
			tween.parallel().tween_property(sprite,"rotation",TAU*(2 if flaming else 1),PROJECTILE_TIME)
	tween.tween_callback(_impact.bind(sprite,to,flaming))
	# jejak di belakang proyektil selama terbang
	var flight=PROJECTILE_TIME*(1.4 if style=="arc" else 1.0)
	var trailTween=sprite.create_tween()
	trailTween.tween_method(fx.trail.bind(get_parent(),sprite,fx.styleOf(weaponId,currentKind),fx.level(currentAttack)),0.0,1.0,flight)

func _arcStep(t_,sprite_,from_,to_):
	if !is_instance_valid(sprite_):
		return
	sprite_.global_position=from_.lerp(to_,t_)+Vector2(0,-sin(t_*PI)*30.0)

# percikan kecil saat proyektil mengenai sasaran
func _impact(sprite_,pos_,flaming_):
	var parent=sprite_.get_parent()
	sprite_.queue_free()
	if parent==null:
		return
	fx.impact(parent,pos_,weaponId,currentAttack,currentKind)
	var colors=HeroClass.getImpactColors(skin,flaming_,currentKind)
	for i in 7:
		var spark=ColorRect.new()
		spark.size=Vector2(2,2)
		spark.color=colors[i%3]
		spark.z_index=60
		parent.add_child(spark)
		spark.global_position=pos_
		var angle=TAU*float(i)/7.0
		var t=spark.create_tween()
		t.tween_property(spark,"global_position",pos_+Vector2(cos(angle),sin(angle))*randf_range(8,16),0.3)
		t.parallel().tween_property(spark,"modulate:a",0.0,0.3)
		t.tween_callback(spark.queue_free)

func playAttack(animation_, kind_="physical"):
	currentAttack=_resolveAttack(animation_)
	currentKind=kind_
	$AnimatedSprite2D.play(currentAttack)
	currentAnim=TYPE_ANIM.ATTACK
	fx.windup(self,global_position+HeroClass.getProjectileOrigin(skin,currentKind),weaponId,str(animation_),currentKind)

# geser tampilan petarung (menerjang / menarik badan); Vector2.ZERO = kembali ke tempat semula
func poseSprite(offset_, time_=0.1):
	if _pose!=null and _pose.is_valid():
		_pose.kill()
	_pose=create_tween()
	_pose.tween_property($AnimatedSprite2D,"position",_spriteHome+offset_,time_).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func playDamage():
	poseSprite(Vector2.ZERO,0.05)
	$AnimatedSprite2D.play("damage")
	currentAnim=TYPE_ANIM.DAMAGE

func playIdle():
	$AnimatedSprite2D.play("idle")
	currentAnim=TYPE_ANIM.IDLE

func playDie():
	# pas d'animation "die" pour le joueur : on signale directement la fin
	if !$AnimatedSprite2D.sprite_frames.has_animation("die"):
		currentAnim=TYPE_ANIM.DIE
		stop()
		emit_signal("dieFinished")
		return
	$AnimatedSprite2D.play("die")
	currentAnim=TYPE_ANIM.DIE

func stop():
	$AnimatedSprite2D.stop()

func _on_AnimatedSprite_animation_finished():
	stop()
	# retour en garde avant de prevenir : le combat peut enchainer une autre animation
	if currentAnim==TYPE_ANIM.ATTACK:
		poseSprite(Vector2.ZERO,0.12)
		playIdle()
		emit_signal("attackFinished")
	elif currentAnim==TYPE_ANIM.DAMAGE:
		playIdle()
		emit_signal("damageFinished")
	elif currentAnim==TYPE_ANIM.DIE:
		emit_signal("dieFinished")
	elif currentAnim==TYPE_ANIM.IDLE:
		playIdle()

func getHeadPosition():
	return position+HEAD_OFFSET
