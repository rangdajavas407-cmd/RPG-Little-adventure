extends GutTest

class TestSimpleProperties:
	extends GutTest
	var Player=load("res://common/singletons/globalPlayer.gd")
	
	func test_life():
		#Arrange
		var player=Player.new()
		#Act
		player.setLife(100)
		player.damage(20)
		var lifeLeft=player.getLife()
		#Assert
		var expectedLifeLeft=80
		assert_eq(expectedLifeLeft, lifeLeft, "devrait afficher 80: 100-20")

	func test_lifeNeverNegative():
		var player=Player.new()
		player.setLife(10)
		player.damage(25)
		assert_eq(0, player.getLife(), "la vie ne descend pas sous 0")

	func test_xp():
		#Arrange
		var player=Player.new()
		#Act
		player.setXp(20)
		player.addXp(10)
		var newXp=player.getXp()
		#Assert
		var expectedNewXp=30
		assert_eq(expectedNewXp,newXp,"devrait afficher 30: 20+10")
		
		#Act 2
		var life=player.getLife()
		#Assert
		var expectedLife=100
		assert_eq(expectedLife,life,"devrait etre a 100 (confirme l'isolation des tests)")


class TestLittleIntelligence:
	extends GutTest
	var Player=load("res://common/singletons/globalPlayer.gd")
	
	func test_savePosition():
		var player=Player.new()
		player.savePosition(Vector2(10,50))
		var savedPosition=player.getPosition()
		player.queue_free()
		assert_eq(Vector2(10,50),savedPosition)

		
	func test_loadPosition():
		var player=Player.new()
		player.savePosition(Vector2(10,50))
		var savedPosition=player.loadPosition()
		assert_eq(Vector2(10,50),savedPosition,"devrait retourner les coord")
		var savedPositionAfterLoad=player.loadPosition()
		assert_eq(null,savedPositionAfterLoad,"devrait retourner vide")
	
	func test_shouldLoadPosition():
		var player=Player.new()
		assert_false(player.shouldLoadPosition(),"doit retourner faux car pas de position")
		player.savePosition(Vector2(10,50))	
		assert_true(player.shouldLoadPosition(),"devrait retourner vrai car une position a ete sauvée")
		player.resetPosition()
		assert_false(player.shouldLoadPosition(),"devrait retourner faux car la position a ete effacée")
		
	func test_items():
		#Arrange
		var player=Player.new()
		#Act
		player.addItem(4)
		#Assert
		assert_eq([4],player.getItemsList(),"devrait afficher [4]")
		assert_eq(true,player.hasItem(4),"devrait afficher true")
		
		player.addItemIfNotExist(4)
		
		assert_eq([4],player.getItemsList(),"devrait toujours afficher [4]")
		


class TestManaAndConsumables:
	extends GutTest
	var Player=load("res://common/singletons/globalPlayer.gd")

	func test_manaClamped():
		var player=Player.new()
		player.setMana(100)
		assert_eq(40, player.getMana(), "mana tidak melebihi maksimum")
		player.useMana(100)
		assert_eq(0, player.getMana(), "mana tidak negatif")

	func test_hpPotionHeals12():
		var player=Player.new()
		player.setLife(30)
		player.addItemEvenIfExist(GlobalItems.ID.HP_POTION)
		player.useItem(GlobalItems.ID.HP_POTION)
		assert_eq(42, player.getLife())
		assert_false(player.hasItem(GlobalItems.ID.HP_POTION), "ramuan habis dipakai")

	func test_bikaRestoresLifeAndMana():
		var player=Player.new()
		player.setLife(50)
		player.setMana(5)
		player.addItemEvenIfExist(GlobalItems.ID.BIKA_AMBON)
		var result=player.useItem(GlobalItems.ID.BIKA_AMBON)
		assert_eq(62, player.getLife())
		assert_eq(13, player.getMana())
		assert_eq(12, result.life)
		assert_eq(8, result.mana)

	func test_jamuRestoresLifeAndMana():
		var player=Player.new()
		player.setLife(50)
		player.setMana(5)
		player.addItemEvenIfExist(GlobalItems.ID.JAMU_OJO_LALI)
		var result=player.useItem(GlobalItems.ID.JAMU_OJO_LALI)
		assert_eq(70, player.getLife())
		assert_eq(19, player.getMana())
		assert_false(result.has("attackBuff"), "Serangan++ hanya aktif di pertarungan")

	func test_jamuRestoresLessThanSoto():
		var soto=GlobalItems.getItem(GlobalItems.ID.SOTO).actionList
		var jamu=GlobalItems.getItem(GlobalItems.ID.JAMU_OJO_LALI).actionList
		assert_lt(jamu[0].value, soto[0].value, "HP jamu lebih kecil dari soto")
		assert_lt(jamu[1].value, soto[1].value, "MP jamu lebih kecil dari soto")

	func test_jamuGivesAttackBuffInBattle():
		var player=Player.new()
		player.setLife(50)
		player.addItemEvenIfExist(GlobalItems.ID.JAMU_OJO_LALI)
		var result=player.useItem(GlobalItems.ID.JAMU_OJO_LALI,true)
		assert_eq(2, result.attackBuff, "Serangan++ dua ronde")

	func test_sageLicenseDisappearsWhenSageChosen():
		var player=Player.new()
		player.addItemEvenIfExist(GlobalItems.ID.SAGE_LICENSE)
		assert_true(player.hasItem(GlobalItems.ID.SAGE_LICENSE))
		player.chooseClass("sage")
		assert_false(player.hasItem(GlobalItems.ID.SAGE_LICENSE), "akses hilang setelah class Sage terbuka")

	func test_sageLicenseStaysForOtherClass():
		var player=Player.new()
		player.addItemEvenIfExist(GlobalItems.ID.SAGE_LICENSE)
		player.chooseClass("knight")
		player.consumeSageLicenseIfUsed()
		assert_true(player.hasItem(GlobalItems.ID.SAGE_LICENSE) or player.isSageUnlocked(), "kunci tetap ada sampai Sage terbuka")

	func test_advanceLicenseDisappearsWhenClassActivated():
		GlobalScenes.saveParamForScene("dungeon","assassin_unlocked",false)
		var player=Player.new()
		player.chooseClass("knight")
		player.addItemEvenIfExist(GlobalItems.ID.ASSASSIN_LICENSE)
		assert_true(player.getLicensedClasses().has("assassin"), "akses belum diaktifkan")
		assert_true(player.hasItem(GlobalItems.ID.ASSASSIN_LICENSE))
		assert_true(player.chooseClass("assassin"))
		assert_false(player.hasItem(GlobalItems.ID.ASSASSIN_LICENSE), "akses hilang setelah class aktif")
		assert_true(player.hasItem(GlobalItems.ID.SHADOW_DAGGER), "senjata class masuk inventaris")
		assert_false(player.getLicensedClasses().has("assassin"))

	func test_advanceLicenseStaysWhenActivatingOtherClass():
		GlobalScenes.saveParamForScene("dungeon","engineer_unlocked",false)
		var player=Player.new()
		player.chooseClass("knight")
		player.addItemEvenIfExist(GlobalItems.ID.ENGINEER_LICENSE)
		player.chooseClass("archer")
		assert_true(player.hasItem(GlobalItems.ID.ENGINEER_LICENSE), "akses Engineer tetap ada sampai Engineer diaktifkan")

	func test_advancePickedRemembersEvenAfterSacrifice():
		GlobalScenes.saveParamForScene("dungeon","engineer_unlocked",false)
		GlobalScenes.saveParamForScene("dungeon","assassin_unlocked",false)
		var player=Player.new()
		player.chooseClass("knight")
		assert_false(player.hasPickedAdvanceClass())
		player.chooseClass("engineer")
		assert_true(player.hasPickedAdvanceClass())
		assert_true(player.isClassUnlocked("engineer"))

	func test_jamuUsableInBattleEvenWhenFull():
		var player=Player.new()
		player.addItemEvenIfExist(GlobalItems.ID.JAMU_OJO_LALI)
		assert_false(player.canUseItem(GlobalItems.ID.JAMU_OJO_LALI), "di luar pertarungan tidak dipakai saat penuh")
		assert_true(player.canUseItem(GlobalItems.ID.JAMU_OJO_LALI,true), "di pertarungan tetap bisa untuk Serangan++")

	func test_sotoGivesEffectBuffInBattle():
		var player=Player.new()
		player.setLife(50)
		player.addItemEvenIfExist(GlobalItems.ID.SOTO)
		var result=player.useItem(GlobalItems.ID.SOTO,true)
		assert_eq(2, result.effectBuff, "Efek++ dua ronde")
		assert_false(result.has("attackBuff"))

	func test_sotoHasNoEffectBuffOutsideBattle():
		var player=Player.new()
		player.setLife(50)
		player.addItemEvenIfExist(GlobalItems.ID.SOTO)
		var result=player.useItem(GlobalItems.ID.SOTO)
		assert_false(result.has("effectBuff"), "Efek++ hanya aktif di pertarungan")
		assert_eq(80, player.getLife())

	func test_sotoUsableInBattleEvenWhenFull():
		var player=Player.new()
		player.addItemEvenIfExist(GlobalItems.ID.SOTO)
		assert_false(player.canUseItem(GlobalItems.ID.SOTO))
		assert_true(player.canUseItem(GlobalItems.ID.SOTO,true))

	func test_itemNotWastedWhenFull():
		var player=Player.new()
		player.addItemEvenIfExist(GlobalItems.ID.BIKA_AMBON)
		player.useItem(GlobalItems.ID.BIKA_AMBON)
		assert_true(player.hasItem(GlobalItems.ID.BIKA_AMBON), "tidak terpakai saat HP & Mana penuh")


class TestHeroClass:
	extends GutTest
	var Player=load("res://common/singletons/globalPlayer.gd")
	var HeroClass=load("res://common/class/hero_class.gd")
	var ClassSprites=load("res://common/fighters/classSprites.gd")

	func _attackNames(player_):
		return player_.getWeaponAttackList().map(func(a): return a.name)

	func test_wizardHasMoreManaLessLife():
		var player=Player.new()
		player.setPlayerClass("wizard")
		assert_eq(80, player.getMaxLife())
		assert_eq(60, player.getMaxMana())

	func test_everyClassStartsWithOnlyWoodSword():
		for class_ in HeroClass.ORDER:
			var player=Player.new()
			player.setPlayerClass(class_)
			assert_eq([GlobalItems.ID.WOOD_SWORD], player.getItemsList(), class_+" hanya membawa Pedang Kayu")
			assert_eq(GlobalItems.ID.WOOD_SWORD, player.getActiveWeaponId())
			assert_false(player.hasShieldReady(), class_+" belum punya perisai di awal")

	func test_startingSkinIsPlainHeroNotClass():
		var player=Player.new()
		player.setPlayerClass("knight")
		assert_eq(HeroClass.HERO, ClassSprites.getSkin("knight", player.getActiveWeaponId()))

	func test_attackListOnlyFromEquippedWeapon():
		var player=Player.new()
		player.setPlayerClass("knight")
		player.addItem(GlobalItems.ID.WOODEN_STAFF)

		player.setEquipment(GlobalItems.ID.WOODEN_STAFF)
		assert_true(_attackNames(player).has("Ayunan Tongkat"))
		assert_false(_attackNames(player).has("Serangan Biasa"), "pegang tongkat: serangan pedang hilang")

		player.setEquipment(GlobalItems.ID.WOOD_SWORD)
		assert_true(_attackNames(player).has("Serangan Biasa"))
		assert_false(_attackNames(player).has("Ayunan Tongkat"), "pegang pedang: serangan tongkat hilang")

	func test_equippingToolKeepsLastWeapon():
		var player=Player.new()
		player.setPlayerClass("archer")
		player.addItem(GlobalItems.ID.WOODEN_STAFF)
		player.addItem(GlobalItems.ID.SPADE)
		player.setEquipment(GlobalItems.ID.WOODEN_STAFF)
		player.setEquipment(GlobalItems.ID.SPADE)
		assert_eq(GlobalItems.ID.WOODEN_STAFF, player.getActiveWeaponId(), "memegang sekop tidak mengganti senjata tempur")

	func test_otherClassWeaponCannotBeUsed():
		var player=Player.new()
		player.setPlayerClass("archer")
		player.addItem(GlobalItems.ID.KNIGHT_SWORD)
		player.setEquipment(GlobalItems.ID.KNIGHT_SWORD)
		assert_eq(GlobalItems.ID.WOOD_SWORD, player.getActiveWeaponId(), "Pemanah tidak bisa memakai pedang Ksatria")

	func test_classWeaponGivesClassSkin():
		var player=Player.new()
		player.setPlayerClass("archer")
		player.addItem(GlobalItems.ID.HUNTER_BOW)
		player.setEquipment(GlobalItems.ID.HUNTER_BOW)
		assert_eq("archer", ClassSprites.getSkin("archer", player.getActiveWeaponId()))
		assert_true(_attackNames(player).has("Tembakan"))

	func test_knightSwordComesWithShield():
		var knight=Player.new()
		knight.setPlayerClass("knight")
		assert_false(knight.hasShieldReady())
		knight.addItem(GlobalItems.ID.KNIGHT_SWORD)
		assert_true(knight.hasItem(GlobalItems.ID.KNIGHT_SHIELD))
		assert_true(knight.hasShieldReady())

	func test_invalidClassFallsBackToKnight():
		var player=Player.new()
		player.setPlayerClass("tidak-ada")
		assert_eq("knight", player.getPlayerClass())

	func test_resetForNewGameClearsOldItems():
		var player=Player.new()
		player.setPlayerClass("knight")
		player.addItem(GlobalItems.ID.WOODEN_STAFF)
		player.resetForNewGame()
		assert_eq([], player.getItemsList())
		assert_eq(-1, player.getActiveWeaponId())

	func test_newGameStartsAsNoviceWithoutClass():
		var player=Player.new()
		player.setPlayerClass(HeroClass.NOVICE)
		assert_eq(HeroClass.NOVICE, player.getPlayerClass())
		assert_false(player.hasChosenClass())
		assert_eq([GlobalItems.ID.WOOD_SWORD], player.getItemsList())
		assert_eq(GlobalItems.ID.WOOD_SWORD, player.getActiveWeaponId())
		assert_eq(-1, player.getClassWeaponId(), "Petualang tidak punya senjata class")

	func test_darkusChooseClassGivesWeaponAndStats():
		var player=Player.new()
		player.setPlayerClass(HeroClass.NOVICE)
		assert_true(player.chooseClass("knight"))
		assert_true(player.hasChosenClass())
		assert_eq(120, player.getMaxLife())
		assert_eq(GlobalItems.ID.WOOD_SWORD, player.getActiveWeaponId(), "upgrade pertama Ksatria = Pedang Kayu")
		assert_true(player.hasItem(GlobalItems.ID.WOOD_SWORD), "pedang kayu tetap disimpan")

	func test_firstClassSwapsToMatchingWoodenWeapon():
		var wizard=Player.new()
		wizard.setPlayerClass(HeroClass.NOVICE)
		assert_true(wizard.chooseClass("wizard"))
		assert_eq(GlobalItems.ID.WOODEN_STAFF, wizard.getActiveWeaponId(), "Penyihir -> Tongkat Kayu")
		var hunter=Player.new()
		hunter.setPlayerClass(HeroClass.NOVICE)
		assert_true(hunter.chooseClass("archer"))
		assert_eq(GlobalItems.ID.WOODEN_BOW, hunter.getActiveWeaponId(), "Pemburu -> Busur Kayu")

	func _novicePlayerWith(classes_):
		var player=Player.new()
		player.setPlayerClass(HeroClass.NOVICE)
		for class_ in classes_:
			assert_true(player.chooseClass(class_))
		return player

	func test_secondClassAddsItsWeaponToInventory():
		var player=_novicePlayerWith(["knight","wizard"])
		assert_eq(["knight","wizard"], player.getOwnedClasses())
		assert_true(player.hasItem(GlobalItems.ID.MAGIC_STAFF), "senjata class kedua langsung masuk inventaris")
		assert_true(player.hasItem(GlobalItems.ID.WOOD_SWORD), "item lama tetap ada")

	func test_cannotOwnMoreThanFourClasses():
		var player=_novicePlayerWith(["knight","wizard","exorcist","assassin"])
		assert_eq(4, player.getOwnedClasses().size())
		assert_false(player.chooseClass("alchemist"), "slot penuh: wajib memilih class yang dikorbankan")
		assert_false(player.chooseClass("alchemist","archer"), "class yang dikorbankan harus dimiliki")
		assert_false(player.ownsClass("alchemist"))
		assert_eq(4, player.getOwnedClasses().size())

	func test_sacrificeReplacesClassAndRemovesItsWeapon():
		var player=_novicePlayerWith(["knight","wizard","exorcist","assassin"])
		player.addItem(GlobalItems.ID.KNIGHT_SWORD)
		assert_true(player.chooseClass("alchemist","knight"))
		assert_eq(4, player.getOwnedClasses().size())
		assert_false(player.ownsClass("knight"))
		assert_true(player.ownsClass("alchemist"))
		assert_false(player.hasItem(GlobalItems.ID.KNIGHT_SWORD), "senjata class korban dihapus")
		assert_false(player.hasItem(GlobalItems.ID.KNIGHT_SHIELD), "perisai Ksatria ikut dihapus")
		assert_true(player.hasItem(GlobalItems.ID.ALCHEMY_FLASK), "senjata class baru masuk inventaris")
		assert_true(player.hasItem(GlobalItems.ID.WOOD_SWORD), "senjata kayu tetap")
		assert_true(player.hasItem(GlobalItems.ID.MAGIC_STAFF), "senjata class lain tetap")

	func test_ownedClassWeaponSwitchesActiveClass():
		var player=_novicePlayerWith(["knight","wizard"])
		assert_eq("wizard", player.getPlayerClass())
		player.addItem(GlobalItems.ID.KNIGHT_SWORD)
		assert_true(player.canEquip(GlobalItems.ID.KNIGHT_SWORD), "Ksatria dimiliki: pedangnya boleh dipasang")
		player.setEquipment(GlobalItems.ID.KNIGHT_SWORD)
		assert_eq("knight", player.getPlayerClass())
		assert_eq(120, player.getMaxLife())
		assert_eq(GlobalItems.ID.KNIGHT_SWORD, player.getActiveWeaponId())
		assert_true(player.hasShieldReady())

	func test_weaponOfUnownedClassStillRejected():
		var player=_novicePlayerWith(["knight","wizard"])
		assert_false(player.canEquip(GlobalItems.ID.HUNTER_BOW))

	func test_advancedClassDetectedEvenWhenNotActive():
		var player=_novicePlayerWith(["knight","engineer","exorcist"])
		assert_eq("exorcist", player.getPlayerClass())
		assert_true(player.hasAdvancedClass(), "Engineer dimiliki walau class aktif Exorcist")

	func test_chooseClassRejectsUnknownClass():
		var player=Player.new()
		player.setPlayerClass(HeroClass.NOVICE)
		assert_false(player.chooseClass(HeroClass.NOVICE))
		assert_false(player.chooseClass("tidak-ada"))
		assert_false(player.hasChosenClass())

	func test_darkusOffersKnightHunterWizardThenAdvanceChoices():
		assert_eq(["knight","archer","wizard"], HeroClass.CHOICES)
		assert_eq(["assassin","engineer"], HeroClass.ADVANCE_CHOICES)

	func test_woodenBowUsableByEveryoneAndGivesBowSkin():
		for class_ in [HeroClass.NOVICE,"knight","archer","wizard"]:
			var player=Player.new()
			player.setPlayerClass(class_)
			player.addItem(GlobalItems.ID.WOODEN_BOW)
			player.setEquipment(GlobalItems.ID.WOODEN_BOW)
			assert_eq(GlobalItems.ID.WOODEN_BOW, player.getActiveWeaponId(), class_)
			assert_true(_attackNames(player).has("Tembakan Kayu"), class_)
			assert_eq(HeroClass.HERO, ClassSprites.getSkin(class_, player.getActiveWeaponId()))


	# ---------- v9.24: Kelapa, akses Exorcist / Alkemis, mana Engineer / Sage ----------

	func test_kelapaHealsLikeLaklakAndGivesShieldOnlyInBattle():
		var kelapa=GlobalItems.getItem(GlobalItems.ID.KELAPA).actionList
		var laklak=GlobalItems.getItem(GlobalItems.ID.LAKLAK).actionList
		assert_eq(laklak[0].value, kelapa[0].value, "HP sama dengan laklak")
		assert_eq(laklak[1].value, kelapa[1].value, "MP dasar sama dengan laklak")
		assert_eq(Vector2i(5,7), kelapa[2].value, "bonus MP acak 5-7")
		var outside=Player.new()
		outside.setLife(50)
		outside.addItemEvenIfExist(GlobalItems.ID.KELAPA)
		assert_false(outside.useItem(GlobalItems.ID.KELAPA,false).has("shieldBuff"), "perisai hanya di pertarungan")
		var inBattle=Player.new()
		inBattle.addItemEvenIfExist(GlobalItems.ID.KELAPA)
		assert_true(inBattle.canUseItem(GlobalItems.ID.KELAPA,true), "bisa dipakai di pertarungan walau HP penuh")
		assert_eq(1, inBattle.useItem(GlobalItems.ID.KELAPA,true).get("shieldBuff",0))

	func test_kelapaRestoresFiveToSevenMoreManaThanLaklak():
		for i in 30:
			var player=Player.new()
			player.setPlayerClass("knight")
			player.setMana(0)
			player.addItemEvenIfExist(GlobalItems.ID.KELAPA)
			var result=player.useItem(GlobalItems.ID.KELAPA,false)
			assert_between(result.mana, 19, 21, "14 MP laklak + 5-7")

	func test_exorcistAndAlchemistAreLimitedNotLicensed():
		var player=Player.new()
		assert_false(player.LICENSE_CLASSES.has("exorcist"), "Exorcist eksklusif drop Bhuta Kala")
		assert_false(player.LICENSE_CLASSES.has("alchemist"), "Alkemis eksklusif drop Bhuta Kala")
		assert_eq(-1, player.getLicenseItemId("exorcist"))
		assert_eq(["exorcist","alchemist","dukun"], HeroClass.BOSS_DROP_CHOICES)
		assert_false(player.LICENSE_CLASSES.has("dukun"), "Dukun juga eksklusif drop Bhuta Kala")

	func test_engineerAndSageMana():
		assert_eq(45, HeroClass.getInfo(HeroClass.ENGINEER).mana)
		assert_gt(HeroClass.getInfo(HeroClass.SAGE).mana, HeroClass.getInfo(HeroClass.WIZARD).mana, "Sage lebih besar dari Penyihir")
