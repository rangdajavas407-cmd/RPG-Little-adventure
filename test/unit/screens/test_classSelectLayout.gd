extends GutTest

# v9.17: sprite class di layar pilih class harus ada di dalam kartunya (tidak menimpa judul / subjudul /
# kartu sebelah) dan kakinya harus di atas label nama.

const ClassSelect=preload("res://screens/game/classSelect.gd")
const HeroClass=preload("res://common/class/hero_class.gd")
const FRAME=64
const SHEETS={"idle":4,"attack-simple":5,"attack-advanced":7}
const ALL_CLASSES=["knight","archer","wizard","sage","assassin","engineer","exorcist","alchemist","dukun"]

# bounding box piksel terpakai dari semua pose yang diputar layar ini
func _art(class_):
	var box=null
	for sheet in SHEETS.keys():
		var image=load(HeroClass.FRAMES_PATH+class_+"-"+sheet+".png").get_image()
		for i in SHEETS[sheet]:
			var used=image.get_region(Rect2i(i*FRAME,0,FRAME,FRAME)).get_used_rect()
			if used.size==Vector2i.ZERO:
				continue
			box=used if box==null else box.merge(used)
	return box

func _cardWidth(count_):
	return ClassSelect.cardWidthFor(count_)

func test_everyPoseStaysInsideCardAboveName():
	for class_ in ALL_CLASSES:
		var art=_art(class_)
		assert_not_null(art,class_)
		for count in [2,3,4]:
			var cardW=_cardWidth(count)
			var k=ClassSelect.SPRITE_SCALE
			var left=cardW/2.0+(art.position.x-FRAME/2.0)*k
			var right=cardW/2.0+(art.end.x-FRAME/2.0)*k
			var top=ClassSelect.SPRITE_Y+(art.position.y-FRAME/2.0)*k
			var bottom=ClassSelect.SPRITE_Y+(art.end.y-FRAME/2.0)*k
			assert_true(left>=0 and right<=cardW,"%s (%d kartu) muat lebar kartu: %s..%s dari %s" % [class_,count,left,right,cardW])
			assert_true(top>=0,"%s (%d kartu) tidak keluar dari atas kartu: %s" % [class_,count,top])
			assert_true(bottom<=ClassSelect.NAME_Y,"%s (%d kartu) kaki di atas label nama: %s <= %s" % [class_,count,bottom,ClassSelect.NAME_Y])

func test_verticalBandsDoNotOverlapAndHaveBreathingRoom():
	# judul 5..15, subjudul 16..24, lalu kartu, panel dan tombol berurutan dengan jarak antar bagian
	assert_true(ClassSelect.CARD_TOP>=ClassSelect.SUBTITLE_Y+8+3,"jarak subjudul ke kartu")
	assert_true(ClassSelect.CARD_TOP+ClassSelect.CARD_H+4<=ClassSelect.PANEL_Y,"jarak kartu ke panel")
	assert_true(ClassSelect.PANEL_Y+ClassSelect.PANEL_H+4<=ClassSelect.FOOTER_Y,"jarak panel ke tombol")
	assert_true(ClassSelect.FOOTER_Y+ClassSelect.FOOTER_H+6<=180,"margin bawah")
	assert_true(ClassSelect.NAME_Y+ClassSelect.NAME_H<=ClassSelect.CARD_H)

func test_horizontalMarginsAndGaps():
	assert_eq(320,ClassSelect.CONTENT_W+2*ClassSelect.MARGIN_X)
	for count in [2,3,4]:
		var total=_cardWidth(count)*count+ClassSelect.CARD_GAP*(count-1)
		assert_true(total<=ClassSelect.CONTENT_W,"%d kartu muat dalam margin" % count)
