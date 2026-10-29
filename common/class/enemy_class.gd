extends Resource

# Data musuh di pertarungan. Pakai lewat  const EnemyClass=preload("res://common/class/enemy_class.gd")

const SPIDER="spider"
const BAT="bat"
const SNAKE="snake"
const IMP="imp"
const LEAK="leak"
const BOSS="boss"
# fase akhir Ancient Dungeon: Bhuta Kala ritual pengorbanan (nyawa 70) -> Satan dipanggil -> Satan merasuki Darkus
# -> Darkus (wujud iblis) kalah dan menjatuhkan Buah Suwarga, obat untuk adek
const SATAN="satan"
# hantu Ancient Dungeon
const KUNTI="kunti"
const POCI="poci"
const DARKUS_BOSS="darkus_boss"
# musuh khusus desa kepiting (leveling): hewan pantai & mutan rumput laut
const BEACH_CRAB="beach_crab"
const JELLYFISH="jellyfish"
const URCHIN="urchin"
const SEAWEED="seaweed"
const SEAGULL="seagull"
# dua bandit dari desa pohon (bertarung sekaligus dalam satu layar)
const BANDIT_RED="bandit_red"
const BANDIT_BLUE="bandit_blue"
const BANDITS="bandits"
# harimau di jalan antara desa kepiting dan desa beruang
const TIGER="tiger"
# musuh desa beruang
const WASP="wasp"
const WOLF="wolf"
const MUSHROOM="mushroom"
# musuh khusus Ancient Dungeon (varian warna lebih kuat)
const CAVE_BAT="cave_bat"
const NIGHT_SNAKE="night_snake"
const FROST_IMP="frost_imp"
const FLAME_LEAK="flame_leak"
# zombie warga desa beruang (sprite: zombie)
const ZOMBIE="zombie_warga"

# bleed = peluang membuat pemain berdarah saat kena (opsional)
# kind: "beast" = hewan biasa, "ghost" = hantu (serangan fisik kurang mempan), "demon" = iblis
# hits = jumlah serangan per giliran, evade = peluang menghindar serangan pemain
# poison = peluang meracuni saat kena, drain = MP yang disedot saat kena
# charge = tiap berapa giliran musuh mengumpulkan tenaga (serangan berikutnya x chargeMul)
const DATA={
	SPIDER:{
		"name":"Laba-laba","kind":"beast","sprite":"",
		"life":50,"damage":10,"hits":1,"miss":0.15,"evade":0.0,
		"poison":0.0,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.75,
		"xp":3,"gemsMin":2,"gemsMax":4,
		"appear":"Seekor laba-laba muncul!","attack":"Laba-laba menyerang!","miss_text":"Laba-laba meleset!"
	},
	BAT:{
		"name":"Kelelawar Hitam","kind":"beast","sprite":"bat",
		"life":32,"damage":6,"hits":2,"miss":0.15,"evade":0.2,
		"poison":0.0,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.8,
		"xp":4,"gemsMin":2,"gemsMax":4,
		"appear":"Kelelawar Hitam menyambar dari kegelapan!","attack":"Kelelawar Hitam menyambar!","miss_text":"Sambarannya meleset!"
	},
	SNAKE:{
		"name":"Ular Hijau","kind":"beast","sprite":"snake",
		"life":44,"damage":8,"hits":1,"miss":0.15,"evade":0.0,
		"poison":0.5,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.75,
		"xp":5,"gemsMin":3,"gemsMax":5,
		"appear":"Ular Hijau berdesis di tengah jalan!","attack":"Ular Hijau mematuk!","miss_text":"Patukan Ular meleset!"
	},
	IMP:{
		"name":"Celuluk","kind":"demon","sprite":"imp",
		"life":60,"damage":11,"hits":1,"miss":0.15,"evade":0.0,
		"poison":0.0,"drain":5,"charge":0,"chargeMul":1.0,"flee":0.7,
		"xp":6,"gemsMin":4,"gemsMax":6,
		"appear":"Celuluk terkekeh dan menjulurkan lidahnya!","attack":"Celuluk mencakar dan menyedot tenagamu!","miss_text":"Cakar Celuluk meleset!"
	},
	LEAK:{
		"name":"Hantu Leak","kind":"ghost","sprite":"leak",
		"life":55,"damage":12,"hits":1,"miss":0.2,"evade":0.0,
		"poison":0.0,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.7,
		"xp":7,"gemsMin":5,"gemsMax":7,
		"appear":"Hantu Leak melayang keluar dari kabut!","attack":"Hantu Leak menerjang!","miss_text":"Terjangan Leak menembus udara kosong!"
	},
	KUNTI:{
		"name":"Kuntilanak","kind":"ghost","sprite":"kunti",
		"life":66,"damage":13,"hits":1,"miss":0.2,"evade":0.15,
		"poison":0.0,"drain":6,"charge":0,"chargeMul":1.0,"flee":0.65,
		"xp":9,"gemsMin":6,"gemsMax":9,
		"appear":"Tawa melengking terdengar... Kuntilanak melayang turun!","attack":"Kuntilanak mencakar dan menyedot tenagamu!","miss_text":"Cakar Kuntilanak menembus udara kosong!"
	},
	POCI:{
		"name":"Pocong","kind":"ghost","sprite":"poci",
		"life":80,"damage":11,"hits":1,"miss":0.25,"evade":0.0,
		"poison":0.0,"drain":0,"charge":3,"chargeMul":2.0,"flee":0.7,
		"xp":9,"gemsMin":6,"gemsMax":9,
		"appear":"Pocong melompat-lompat menghadang jalan!","attack":"Pocong menyeruduk!","miss_text":"Seruduk Pocong meleset!"
	},
	BOSS:{
		"name":"Bhuta Kala","kind":"demon","sprite":"boss",
		"life":230,"damage":15,"hits":1,"miss":0.1,"evade":0.0,
		"poison":0.0,"drain":0,"charge":3,"chargeMul":2.2,"flee":0.35,
		"enrageBelow":0.5,"enrageMul":1.25,
		"xp":25,"gemsMin":18,"gemsMax":24,
		"appear":"Bhuta Kala menghadang jalan dengan gadanya!","attack":"Bhuta Kala mengayunkan gada!","miss_text":"Gada Bhuta Kala menghantam tanah kosong!",
		# saat nyawa tinggal 70: ritual pengorbanan untuk memanggil Satan (pemain kena 20 damage dari ledakannya)
		"suicideAt":70,"suicideDamage":20,"summon":SATAN,
		"suicideText":"Bhuta Kala meraung: 'Seluruh kekuatanku kupersembahkan padamu, Tuanku!' Ia menancapkan gadanya ke tanah dan mulai merapal ritual terlarang!",
		"ritualText":"Tanah berdenyut merah! Bhuta Kala mengorbankan seluruh kekuatannya, ritual pengorbanan untuk memanggil Satan!",
		"summonText":"Tubuh Bhuta Kala hancur menjadi asap hitam... tanah di bawah kakimu mulai bergetar!"
	},
	SATAN:{
		"name":"Satan","kind":"demon","sprite":"satan",
		"life":260,"damage":17,"hits":1,"miss":0.1,"evade":0.0,
		"poison":0.0,"drain":6,"charge":3,"chargeMul":2.0,"flee":0.0,
		"enrageBelow":0.4,"enrageMul":1.25,
		"xp":30,"gemsMin":20,"gemsMax":28,
		"appear":"Satan muncul dari api neraka!","attack":"Satan mencakar dan menyedot tenagamu!","miss_text":"Cakar Satan menembus bayangan!",
		# saat nyawa habis: Satan meraung tidak terima kalah (tubuh merah gemetar, layar bergetar), baru tumbang
		"dyingText":"Satan menjerit: 'ARGHHH...! Apa... AKU KALAH dari makhluk tak jelas seperti KAMU?!'",
		"dyingText2":"Tubuh Satan retak! Cahaya merah menyembur dari celah-celahnya!",
		# Satan kalah, Darkus datang memeriksa pemain, lalu Satan menarik dan merasuki tubuhnya.
		"possess":DARKUS_BOSS,
		"lingerText":"Tubuh Satan retak dan runtuh. Namun, dari balik asap hitamnya terdengar tawa yang belum berakhir...",
		"possessText":"Satan: 'Nah... ini dia yang kucari.' Energi gelap mencengkeram Darkus dan menyeretnya ke udara!"
	},
	DARKUS_BOSS:{
		"name":"Darkus (Dirasuki Satan)","kind":"demon","sprite":"darkus_iblis",
		# muncul dulu sebagai Darkus biasa, lalu berubah wujud (animasi morph)
		"preSprite":"darkus",
		"enterText":"Langkah kaki tergesa terdengar dari lorong. Darkus berlari masuk, terkejut melihat ruangan yang porak-poranda.",
		"enterSpeech":"Darkus: 'Kamu tidak apa-apa? Aku mendengar suara gemuruh di luar... Apa yang terjadi di sini?'",
		"possessSpeech":"Darkus: 'T-tidak! Lepaskan aku! Aku tidak akan jadi wadahmu!!'",
		"preText":"Asap hitam Satan menyelimuti Darkus. Tubuhnya terangkat, dan cahaya merah mulai menyala di matanya!",
		"life":300,"damage":19,"hits":1,"miss":0.1,"evade":0.1,
		"poison":0.0,"drain":8,"charge":3,"chargeMul":2.2,"flee":0.0,
		"enrageBelow":0.5,"enrageMul":1.3,
		"xp":45,"gemsMin":30,"gemsMax":40,
		"appear":"Darkus bangkit dengan mata menyala merah. 'Lari... aku tak bisa menahannya!' Ini bos terakhir!","attack":"Darkus menebas dengan kekuatan Satan!","miss_text":"Tebasan Darkus meleset!",
		"dieText":"Asap hitam Satan terlepas dari tubuh Darkus dan lenyap. Darkus jatuh pingsan, dan sebuah buah bercahaya jatuh di dekatnya..."
	},
	BEACH_CRAB:{
		"name":"Kepiting Karang","kind":"beast","sprite":"crab",
		"life":40,"damage":7,"hits":1,"miss":0.15,"evade":0.1,
		"poison":0.0,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.8,
		"xp":5,"gemsMin":2,"gemsMax":4,
		"appear":"Kepiting Karang menjepit pasir dengan capitnya!","attack":"Kepiting Karang menjepit!","miss_text":"Jepitannya meleset!"
	},
	JELLYFISH:{
		"name":"Ubur-ubur Listrik","kind":"beast","sprite":"jellyfish",
		"life":36,"damage":6,"hits":1,"miss":0.15,"evade":0.0,
		"poison":0.5,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.8,
		"xp":5,"gemsMin":2,"gemsMax":4,
		"appear":"Ubur-ubur Listrik melayang di atas pasir, berkilat!","attack":"Ubur-ubur Listrik menyengat!","miss_text":"Sengatannya meleset!"
	},
	URCHIN:{
		"name":"Bulu Babi","kind":"beast","sprite":"urchin",
		"life":50,"damage":9,"hits":1,"miss":0.2,"evade":0.0,
		"poison":0.0,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.75,
		"xp":6,"gemsMin":3,"gemsMax":5,
		"appear":"Bulu Babi raksasa menggelinding dengan duri-durinya!","attack":"Bulu Babi menusukkan duri!","miss_text":"Duri-durinya meleset!"
	},
	SEAWEED:{
		"name":"Mutan Rumput Laut","kind":"beast","sprite":"seaweed",
		"life":62,"damage":10,"hits":1,"miss":0.15,"evade":0.0,
		"poison":0.3,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.7,
		"enrageBelow":0.4,"enrageMul":1.3,
		"xp":7,"gemsMin":4,"gemsMax":6,
		"appear":"Mutan Rumput Laut menyeret tubuh lengketnya keluar dari ombak!","attack":"Mutan Rumput Laut mencambuk dengan sulurnya!","miss_text":"Cambukan sulurnya meleset!"
	},
	SEAGULL:{
		"name":"Camar Ganas","kind":"beast","sprite":"seagull",
		"life":34,"damage":5,"hits":2,"miss":0.15,"evade":0.3,
		"poison":0.0,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.85,
		"xp":5,"gemsMin":2,"gemsMax":4,
		"appear":"Camar Ganas menukik sambil berteriak nyaring!","attack":"Camar Ganas mematuk!","miss_text":"Patukannya meleset!"
	},
	BANDIT_RED:{
		"name":"Bandit Merah","kind":"human","sprite":"bandit_red",
		"life":60,"damage":11,"hits":1,"miss":0.15,"evade":0.0,
		"poison":0.0,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.6,
		"xp":9,"gemsMin":5,"gemsMax":8,
		"appear":"Bandit Merah menghunus pedangnya!","attack":"Bandit Merah menebas!","miss_text":"Tebasan Bandit Merah meleset!"
	},
	BANDIT_BLUE:{
		"name":"Bandit Biru","kind":"human","sprite":"bandit_blue",
		"life":52,"damage":9,"hits":1,"miss":0.12,"evade":0.1,
		"poison":0.0,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.6,
		"xp":8,"gemsMin":5,"gemsMax":8,
		"appear":"Bandit Biru memutar belatinya!","attack":"Bandit Biru menusuk!","miss_text":"Tusukan Bandit Biru meleset!"
	},
	TIGER:{
		"name":"Harimau Belang","kind":"beast","sprite":"tiger",
		"life":110,"damage":14,"hits":1,"miss":0.12,"evade":0.0,
		"poison":0.0,"bleed":0.35,"drain":0,"charge":4,"chargeMul":2.0,"flee":0.4,
		"enrageBelow":0.4,"enrageMul":1.25,
		"xp":14,"gemsMin":8,"gemsMax":12,
		"appear":"Harimau Belang menggeram dan menghadang jalan!","attack":"Harimau Belang menerkam!","miss_text":"Terkaman Harimau meleset!"
	},
	WASP:{
		"name":"Lebah Pengamuk","kind":"beast","sprite":"wasp",
		"life":38,"damage":6,"hits":2,"miss":0.15,"evade":0.25,
		"poison":0.3,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.8,
		"xp":6,"gemsMin":3,"gemsMax":5,
		"appear":"Lebah Pengamuk berdengung marah!","attack":"Lebah Pengamuk menyengat!","miss_text":"Sengatannya meleset!"
	},
	WOLF:{
		"name":"Serigala Hutan","kind":"beast","sprite":"wolf",
		"life":72,"damage":12,"hits":1,"miss":0.12,"evade":0.1,
		"poison":0.0,"bleed":0.3,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.6,
		"xp":9,"gemsMin":5,"gemsMax":8,
		"appear":"Serigala Hutan melolong dan mengendap mendekat!","attack":"Serigala Hutan menggigit!","miss_text":"Gigitan Serigala meleset!"
	},
	MUSHROOM:{
		"name":"Jamur Racun","kind":"beast","sprite":"mushroom",
		"life":58,"damage":8,"hits":1,"miss":0.2,"evade":0.0,
		"poison":0.7,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.75,
		"xp":8,"gemsMin":4,"gemsMax":7,
		"appear":"Jamur Racun menyebar spora hijau beracun!","attack":"Jamur Racun menyemburkan spora!","miss_text":"Sporanya tertiup angin!"
	},
	CAVE_BAT:{
		"name":"Kelelawar Gua","kind":"beast","sprite":"cavebat",
		"life":42,"damage":8,"hits":2,"miss":0.15,"evade":0.25,
		"poison":0.0,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.75,
		"xp":6,"gemsMin":4,"gemsMax":6,
		"appear":"Kelelawar Gua berhamburan dari langit-langit!","attack":"Kelelawar Gua menyambar!","miss_text":"Sambarannya meleset!"
	},
	NIGHT_SNAKE:{
		"name":"Ular Malam","kind":"beast","sprite":"nightsnake",
		"life":58,"damage":11,"hits":1,"miss":0.15,"evade":0.0,
		"poison":0.6,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.7,
		"xp":8,"gemsMin":5,"gemsMax":7,
		"appear":"Ular Malam merayap keluar dari bayangan!","attack":"Ular Malam mematuk!","miss_text":"Patukan Ular Malam meleset!"
	},
	FROST_IMP:{
		"name":"Celuluk Es","kind":"demon","sprite":"frostimp",
		"life":78,"damage":14,"hits":1,"miss":0.15,"evade":0.0,
		"poison":0.0,"drain":6,"charge":0,"chargeMul":1.0,"flee":0.65,
		"xp":10,"gemsMin":6,"gemsMax":9,
		"appear":"Celuluk Es terkekeh, napasnya membeku!","attack":"Celuluk Es mencakar dan menyedot tenagamu!","miss_text":"Cakar Celuluk Es meleset!"
	},
	ZOMBIE:{
		"name":"Zombie Warga Desa","kind":"beast","sprite":"zombie",
		"life":66,"damage":10,"hits":1,"miss":0.2,"evade":0.0,
		"poison":0.4,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.7,
		"xp":8,"gemsMin":5,"gemsMax":7,
		"appear":"Zombie Warga Desa terhuyung-huyung dengan topi anyamannya!","attack":"Zombie Warga Desa mencakar!","miss_text":"Cakaran Zombie meleset!"
	},
	FLAME_LEAK:{
		"name":"Leak Bara","kind":"ghost","sprite":"flameleak",
		"life":70,"damage":16,"hits":1,"miss":0.2,"evade":0.0,
		"poison":0.0,"drain":0,"charge":0,"chargeMul":1.0,"flee":0.65,
		"xp":11,"gemsMin":7,"gemsMax":10,
		"appear":"Leak Bara melayang keluar dari kobaran api!","attack":"Leak Bara menerjang!","miss_text":"Terjangan Leak Bara menembus udara kosong!"
	}
}

# beberapa musuh sekaligus dalam satu pertarungan (maksimal 2 per layar)
const GROUPS={
	BANDITS:{"name":"Dua Bandit","members":[BANDIT_RED,BANDIT_BLUE],"appear":"Bandit Merah dan Bandit Biru menghadang! Dua lawan satu!"}
}

static func isGroup(id_):
	return GROUPS.has(id_)

# daftar id musuh untuk satu pertarungan ([id] untuk musuh tunggal)
static func getGroup(id_):
	if GROUPS.has(id_):
		return GROUPS[id_].members
	return [id_]

static func getEnemy(id_):
	return DATA[id_] if DATA.has(id_) else DATA[SPIDER]

# hadiah barang saat musuh kalah
static func getDrops(id_):
	# Busur Kayu tidak lagi dijatuhkan Bhuta Kala: hadiah dari Anak Desa setelah desa kepiting bersih
	if id_==DARKUS_BOSS:
		# Buah Suwarga = obat untuk adek (kata Pak Tabib)
		return [GlobalItems.ID.HEAVEN_FRUIT,GlobalItems.ID.LAKLAK,GlobalItems.ID.LAKLAK,GlobalItems.ID.MANA_POTION]
	# Bandit Merah menjatuhkan Paku (bahan sumur) kalau pemain belum punya
	if id_==BANDIT_RED and GlobalGame.getStoryStage()==GlobalGame.STAGE_WELL and !GlobalPlayer.hasItem(GlobalItems.ID.NAILS):
		return [GlobalItems.ID.NAILS]
	return []
