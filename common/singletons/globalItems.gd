extends Node

var itemClass=preload("res://common/class/item_class.gd")
var attackClass=preload("res://common/class/item/attack_class.gd")
var potionClass=preload("res://common/class/item/potion_class.gd")

enum ID {
	#weapons
	WOOD_SWORD,
	#potions 
	HEALTH_POTION_10,
	#maps
	GORMON_STAR_MAP,
	#tools
	SPADE,
	
	#things
	GORDMON_STAR,
	
	NAILS,

	HONEY,

	BUCKET,

	# obat demam untuk adek (tahap 2 cerita)
	MEDICINE,

	# Ramuan HP dari adek & Bika Ambon buatan Bunda (ditambah di akhir agar save lama tetap valid)
	HP_POTION,

	BIKA_AMBON,

	# dijual di toko (ditambah di akhir agar save lama tetap valid)
	MANA_POTION,

	LAKLAK,

	KUE_PUTU,

	# senjata tiap class
	KNIGHT_SWORD,

	HUNTER_BOW,

	MAGIC_STAFF,

	SHADOW_DAGGER,

	ALCHEMY_FLASK,

	EXORCIST_PAPER,

	ORB_SUCI,

	# perlengkapan Ksatria
	KNIGHT_SHIELD,

	# tongkat pemberian Vera (bisa dipakai semua class)
	WOODEN_STAFF,

	# busur hadiah Bhuta Kala (bisa dipakai semua class; ditambah di akhir agar save lama tetap valid)
	WOODEN_BOW,

	# obat adek: dijatuhkan Darkus (dirasuki Satan) di Ancient Dungeon (ditambah di akhir agar save lama tetap valid)
	HEAVEN_FRUIT,

	# makanan spesial kios Barong (ditambahkan di akhir agar ID save lama tetap aman)
	SOTO,

	# tanda pembuka class Sage, dibeli di kios Barong
	SAGE_LICENSE,

	# ramuan serba guna (HP + MP + Serangan++ dua ronde), dijual di kios Barong
	JAMU_OJO_LALI,

	# senjata khas Engineer (ditambah di akhir agar save lama tetap valid)
	SCIFI_WRENCH,

	# tanda pembuka class Asasin / Engineer yang tidak dipilih Darkus, dibeli di kios Barong
	# (ditambah di akhir agar save lama tetap valid)
	ASSASSIN_LICENSE,
	ENGINEER_LICENSE,

	# v9.24: Kelapa muda (pulih + perisai 1 ronde)
	# (ditambah di akhir agar save lama tetap valid)
	KELAPA,

	# v9.30: senjata khas Dukun (ditambah di akhir agar save lama tetap valid)
	DUKUN_STAFF   # senjata Dukun = "Hiolo Sesat" (nama enum dipertahankan supaya save lama aman)
	
	}

var itemList={
	
	ID.WOOD_SWORD:itemClass.new(
		"Pedang Kayu",
		"Pedang sederhana dari kayu.",
		"common/items/weapons/wood-sword.png",
		itemClass.TYPE.WEAPON,
		[
			attackClass.new(
				"Serangan Biasa",
				"attack_wood-sword_simple",
				10,
				0
			),
			attackClass.new(
				"Serangan Lanjutan",
				"attack_wood-sword_advanced",
				20,
				10,
				5
			),
			attackClass.new(
				"Serangan Api",
				"attack_wood-sword_onfire",
				50,
				50,
				20
			)
		]
	),

	ID.KNIGHT_SWORD:itemClass.new(
		"Pedang Ksatria",
		"Pedang baja Ksatria. Tebasan kuat.",
		"common/items/weapons/knight-sword.png",
		itemClass.TYPE.WEAPON,
		[
			attackClass.new("Tebasan","attack_simple",10,0),
			attackClass.new("Tebasan Kuat","attack_advanced",20,10,4),
			attackClass.new("Pedang Api","attack_special",50,50,20)
		]
	),
	ID.HUNTER_BOW:itemClass.new(
		"Busur Pemburu",
		"Busur Pemburu. Menembak dari jauh.",
		"common/items/weapons/hunter-bow.png",
		itemClass.TYPE.WEAPON,
		[
			attackClass.new("Tembakan","attack_simple",9,0,0,0,attackClass.RANGED),
			attackClass.new("Tembak Ganda","attack_advanced",20,10,5,0,attackClass.RANGED),
			attackClass.new("Panah Api","attack_special",48,50,18,0,attackClass.RANGED)
		]
	),
	ID.MAGIC_STAFF:itemClass.new(
		"Tongkat Sihir",
		"Tongkat Penyihir. Sihir api dan petir.",
		"common/items/weapons/magic-staff.png",
		itemClass.TYPE.WEAPON,
		[
			attackClass.new("Bola Sihir","attack_simple",8,0,0,0,attackClass.MAGIC),
			attackClass.new("Petir Sihir","attack_advanced",22,10,6,0,attackClass.MAGIC),
			attackClass.new("Bola Api","attack_special",55,50,22,0,attackClass.MAGIC)
		]
	),
	ID.HEALTH_POTION_10:itemClass.new(
		"Ramuan HP",
		"Memulihkan 12 HP.",
		"common/items/magicpotion/hp-potion.png",
		itemClass.TYPE.MAGICPOTION,
		[	
			potionClass.new("increaseLife",12)
		]
	),
	ID.SPADE:itemClass.new(
		"Sekop",
		"Untuk menggali.",
		"common/items/tools/spade.png",
		itemClass.TYPE.TOOL
	),
	ID.GORMON_STAR_MAP:itemClass.new(
		"Peta",
		"Peta harta karun Gormon.",
		"common/items/maps/gormon-star-map.png",
		itemClass.TYPE.MAP
	),
	ID.GORDMON_STAR:itemClass.new(
		"Bintang",
		"Bintang Gormon.",
		"common/items/things/gordon-star.png",
		itemClass.TYPE.THING
	),
	ID.NAILS:itemClass.new(
		"Paku",
		"Menguatkan rangka sumur.",
		"common/items/things/nails.png",
		itemClass.TYPE.THING
	),
	ID.HONEY:itemClass.new(
		"Madu Hutan",
		"Merekatkan batu sumur.",
		"common/items/things/honey.png",
		itemClass.TYPE.THING
	),
	ID.BUCKET:itemClass.new(
		"Timba Baru",
		"Timba baru untuk sumur.",
		"common/items/things/bucket.png",
		itemClass.TYPE.THING
	),
	ID.MEDICINE:itemClass.new(
		"Obat Demam",
		"Menurunkan demam adek.",
		"common/items/things/medicine.png",
		itemClass.TYPE.THING
	),
	ID.HP_POTION:itemClass.new(
		"Ramuan HP",
		"Pemberian adek. Pulih 12 HP.",
		"common/items/magicpotion/hp-potion.png",
		itemClass.TYPE.MAGICPOTION,
		[
			potionClass.new("increaseLife",12)
		]
	),
	ID.BIKA_AMBON:itemClass.new(
		"Bika Ambon",
		"Buatan Bunda. Pulih 12 HP, 8 MP.",
		"common/items/food/bika-ambon.png",
		itemClass.TYPE.FOOD,
		[
			potionClass.new("increaseLife",12),
			potionClass.new("increaseMana",8)
		]
	),
	ID.MANA_POTION:itemClass.new(
		"Ramuan Mana",
		"Memulihkan 12 MP.",
		"common/items/magicpotion/mana-potion.png",
		itemClass.TYPE.MAGICPOTION,
		[
			potionClass.new("increaseMana",12)
		]
	),
	ID.LAKLAK:itemClass.new(
		"Laklak",
		"Pulih 20 HP, 14 MP.",
		"common/items/food/laklak.png",
		itemClass.TYPE.FOOD,
		[
			potionClass.new("increaseLife",20),
			potionClass.new("increaseMana",14)
		]
	),
	ID.KUE_PUTU:itemClass.new(
		"Kue Putu",
		"Pulih 16 HP, 10 MP.",
		"common/items/food/kue-putu.png",
		itemClass.TYPE.FOOD,
		[
			potionClass.new("increaseLife",16),
			potionClass.new("increaseMana",10)
		]
	),
	ID.SHADOW_DAGGER:itemClass.new(
		"Belati Bayangan",
		"Belati Asasin. Kritis tinggi, bisa elak dan balas.",
		"common/items/weapons/belati-bayangan.png",
		itemClass.TYPE.WEAPON,
		[
			attackClass.new("Tusukan","attack_simple",14,0),
			attackClass.new("Tebas Kilat","attack_advanced",30,10,6,0,attackClass.PHYSICAL,"",0.0,attackClass.DODGE),
			attackClass.new("Serangan Bayangan","attack_special",85,50,20,0,attackClass.PHYSICAL,attackClass.BLEED,0.85)
		]
	),
	ID.ALCHEMY_FLASK:itemClass.new(
		"Tabung Alkemi",
		"Tabung Alkemis. Mencipta Golem atau Mecha secara acak, lempar tabung reaksi.",
		"common/items/weapons/tabung-alkemi.png",
		itemClass.TYPE.WEAPON,
		[
			attackClass.new("Lempar Ramuan","attack_simple",9,0,0,0,attackClass.MAGIC),
			# v9.30/9.31: skill 2 memanggil Golem atau Mecha secara ACAK (gacha, tanpa menu pilih); skill 3 melempar tabung reaksi (Blizzard atau Racun)
			attackClass.new("Cipta Makhluk (Acak)","attack_advanced",0,10,12,0,attackClass.SUMMON,"",0.0,"",attackClass.SPECIAL_SUMMON_ALCHEMY),
			attackClass.new("Tabung Reaksi","attack_special",52,50,20,0,attackClass.MAGIC,"",0.0,"",attackClass.SPECIAL_TUBE),
			attackClass.new("ULTI: Reaksi Kiamat","attack_ultimate",105,100,35,0,attackClass.MAGIC)
		]
	),
	ID.EXORCIST_PAPER:itemClass.new(
		"Kertas Jimat",
		"Jimat Exorcist. Panggil Banaspati, kadang memunculkan Barrier.",
		"common/items/weapons/kertas-Exorcist.png",
		itemClass.TYPE.WEAPON,
		[
			# v9.30: Jimat Pengusir bisa memunculkan Barrier / Perisai Suci; skill 2 memanggil Banaspati
			attackClass.new("Jimat Pengusir","attack_simple",8,0,0,0,attackClass.MAGIC,"",0.0,"",attackClass.SPECIAL_BARRIER),
			attackClass.new("Panggil Banaspati","attack_advanced",0,10,10,0,attackClass.SUMMON,"",0.0,"",attackClass.SPECIAL_SUMMON_BANASPATI),
			attackClass.new("Pengusiran","attack_special",60,50,22,0,attackClass.MAGIC),
			attackClass.new("ULTI: Segel Penghakiman","attack_ultimate",115,100,38,0,attackClass.MAGIC)
		]
	),
	ID.ORB_SUCI:itemClass.new(
		"Orb Suci",
		"Orb Sage. Serangan ikut menyembuhkan.",
		"common/items/weapons/orb-suci_sage.png",
		itemClass.TYPE.WEAPON,
		[
			attackClass.new("Cahaya Suci","attack_simple",8,0,0,2,attackClass.MAGIC),
			attackClass.new("Berkah Cahaya","attack_advanced",18,10,6,6,attackClass.MAGIC),
			attackClass.new("Ledakan Suci","attack_special",44,50,20,12,attackClass.MAGIC)
		]
	),
	ID.KNIGHT_SHIELD:itemClass.new(
		"Perisai Ksatria",
		"Perisai Ksatria. Menahan 25% serangan.",
		"common/items/weapons/perisai-ksatria.png",
		itemClass.TYPE.THING
	),
	ID.WOODEN_STAFF:itemClass.new(
		"Tongkat Kayu",
		"Pemberian Vera, untuk semua class.",
		"common/items/weapons/tongkat-kayu.png",
		itemClass.TYPE.WEAPON,
		[
			attackClass.new("Ayunan Tongkat","attack_simple",12,0,0,0,attackClass.PHYSICAL),
			attackClass.new("Percikan Sihir","attack_simple",16,0,4,0,attackClass.MAGIC),
			attackClass.new("Ledakan Sihir","attack_advanced",30,10,10,0,attackClass.MAGIC)
		]
	),
	ID.SOTO:itemClass.new(
		"Soto Ayam",
		"Pulih 30 HP, 22 MP. Efek++ 2 ronde.",
		"common/items/food/soto.png",
		itemClass.TYPE.FOOD,
		[
			potionClass.new("increaseLife",30),
			potionClass.new("increaseMana",22),
			potionClass.new("effectBuff",2)
		]
	),
	ID.JAMU_OJO_LALI:itemClass.new(
		"Jamu Ojo Lali",
		"Pulih 20 HP, 14 MP. Serangan++ 2 ronde.",
		"common/items/food/jamu-ojo-lali.png",
		itemClass.TYPE.MAGICPOTION,
		[
			potionClass.new("increaseLife",20),
			potionClass.new("increaseMana",14),
			potionClass.new("attackBuff",2)
		]
	),
	ID.SAGE_LICENSE:itemClass.new(
		"Akses Class Sage",
		"Membuka class Sage di Darkus. Hilang setelah dipakai.",
		"common/items/weapons/orb-suci_sage.png",
		itemClass.TYPE.THING
	),
	ID.ASSASSIN_LICENSE:itemClass.new(
		"Akses Class Asasin",
		"Aktifkan class Asasin di Darkus. Hilang setelah dipakai.",
		"common/items/weapons/belati-bayangan.png",
		itemClass.TYPE.THING
	),
	ID.ENGINEER_LICENSE:itemClass.new(
		"Akses Class Engineer",
		"Aktifkan class Engineer di Darkus. Hilang setelah dipakai.",
		"common/items/weapons/sci-fi-wrench.png",
		itemClass.TYPE.THING
	),
	ID.KELAPA:itemClass.new(
		"Kelapa",
		"Pulih 20 HP, 19-21 MP. Perisai 1 ronde: damage masuk -10 sampai 26%.",
		"common/items/food/kelapa.png",
		itemClass.TYPE.FOOD,
		[
			potionClass.new("increaseLife",20),
			# MP dasar sama dengan Laklak (14) + bonus acak 5-7 (jadi 19-21 MP)
			potionClass.new("increaseMana",14),
			potionClass.new("bonusMana",Vector2i(5,7)),
			potionClass.new("shieldBuff",1)
		]
	),
	ID.DUKUN_STAFF:itemClass.new(
		"Hiolo Sesat",
		"Hiolo (tempat dupa) Dukun. Memanggil makhluk acak: Mumi, Lampor, atau Randa.",
		"common/items/weapons/hiolo-sesat-dukun.png",
		itemClass.TYPE.WEAPON,
		[
			attackClass.new("Mantra Pengusik","attack_simple",9,0,0,0,attackClass.MAGIC),
			attackClass.new("Racun Santet","attack_advanced",20,10,8,0,attackClass.MAGIC,attackClass.POISON,0.7),
			attackClass.new("Panggil Makhluk (Acak)","attack_special",0,50,20,0,attackClass.SUMMON,"",0.0,"",attackClass.SPECIAL_SUMMON_DUKUN),
			attackClass.new("ULTI: Kutukan Tujuh Alam","attack_ultimate",110,100,36,0,attackClass.MAGIC,attackClass.POISON,0.8)
		]
	),
	ID.HEAVEN_FRUIT:itemClass.new(
		"Buah Suwarga",
		"Buah langka untuk menyembuhkan adek.",
		"common/items/things/heaven-fruit.png",
		itemClass.TYPE.THING
	),
	ID.WOODEN_BOW:itemClass.new(
		"Busur Kayu",
		"Hadiah Bhuta Kala, untuk semua class.",
		"common/items/weapons/bow-wood.png",
		itemClass.TYPE.WEAPON,
		[
			attackClass.new("Tembakan Kayu","attack_simple",9,0,0,0,attackClass.RANGED),
			attackClass.new("Tembak Ganda","attack_advanced",18,10,4,0,attackClass.RANGED),
			attackClass.new("Panah Api","attack_special",42,50,16,0,attackClass.RANGED)
		]
	),
	ID.SCIFI_WRENCH:itemClass.new(
		"Sci-Fi Wrench",
		"Senjata Engineer. Kotak Mekanik, Turet, Hantaman Berat.",
		"common/items/weapons/sci-fi-wrench.png",
		itemClass.TYPE.WEAPON,
		[
			attackClass.new("Pukulan Kunci","attack_simple",12,0,0,0,attackClass.PHYSICAL),
			attackClass.new("Teknik Mesin","attack_advanced",0,10,8,0,attackClass.GADGET),
			attackClass.new("Hantaman Berat","attack_special",38,50,14,0,attackClass.PHYSICAL,attackClass.CONFUSE,0.6)
		]
	)
}

func getItem(key_):
	return itemList[int(key_)]
	
	

# urutan kelompok item di inventaris (angka kecil tampil lebih dulu)
func getSortGroup(key_):
	match getItem(key_).type:
		itemClass.TYPE.WEAPON:
			return 0
		itemClass.TYPE.TOOL:
			return 1
		itemClass.TYPE.MAGICPOTION:
			return 2
		itemClass.TYPE.FOOD:
			return 3
		itemClass.TYPE.THING:
			return 4
	return 5

# daftar id unik, diurutkan per kelompok lalu menurut id
func sortedUniqueIds(list_):
	var unique=[]
	for id in list_:
		if !unique.has(id):
			unique.append(id)
	unique.sort_custom(func(a,b):
		var ga=getSortGroup(a)
		var gb=getSortGroup(b)
		if ga!=gb:
			return ga<gb
		return int(a)<int(b))
	return unique
