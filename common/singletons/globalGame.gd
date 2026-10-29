extends Node

var _filename=null
var _sceneToLoad=null

# frame saat dialog terakhir ditutup (lihat common/areas/interact.gd)
var dialogEndFrame=-10

const FR='FR'
const EN='EN'
const ID='ID'
const MS='MS'

const TRAD_WORD_VENDEUR='Vendeur'
const TRAD_WORD_HABITANT='Habitant'
const TRAD_WORD_PRESENTATEUR='Presentateur'
const TRAD_WORD_APICULTEUR='Apiculteur'
const TRAD_WORD_ARTISAN='Artisan'
const TRAD_WORD_GORDONMOM='gordon_mom'

const TRAD_TREEVILLAGE_START='tree-village_start'
const TRAD_TREEVILLAGE_PENDING='tree-village_pending'
const TRAD_TREEVILLAGE_END='tree-village_end'

const TRAD_TREEVILLAGE_STARFOUND='tree-village_starfound'

const TRAD_TREEVILLAGE_GEMHOUSE_START='tree-village_gemhouse_start'
const TRAD_TREEVILLAGE_GEMHOUSE_PENDING='tree-village_gemhouse_pending'
const TRAD_TREEVILLAGE_GEMHOUSE_END='tree-village_gemhouse_end'

const TRAD_TREEVILLAGE_SHOP='tree-village_shop'
const TRAD_TREEVILLAGE_GORDONHOME='tree-village_gordonhome'
const TRAD_TREEVILLAGE_ADEK='tree-village_adek'
const TRAD_WORD_ADEK='adek'
const TRAD_WORD_TREESELLER='word_treeseller'
const TRAD_WORD_GEMKEEPER='word_gemkeeper'
const TRAD_WORD_CRABKID='word_crabkid'
const TRAD_WORD_CRABSELLER='word_crabseller'
const TRAD_WORD_BEARSELLER='word_bearseller'
const TRAD_WELL_REPAIRED='well_repaired'

# dialog cerita (format [[pembicara,[baris]],...], lihat addDialogByKey)
const TRAD_HOME_MOM_WELL_1='home_mom_well_1'
const TRAD_HOME_MOM_WELL_2='home_mom_well_2'
const TRAD_HOME_MOM_WELL_READY='home_mom_well_ready'
const TRAD_HOME_MOM_MED_1='home_mom_med_1'
const TRAD_HOME_MOM_MED_2='home_mom_med_2'
const TRAD_HOME_MOM_MED_3='home_mom_med_3'
const TRAD_HOME_MOM_MED_HAVE='home_mom_med_have'
const TRAD_HOME_MOM_DONE='home_mom_done'
const TRAD_HOME_ADEK_WELL_1='home_adek_well_1'
const TRAD_HOME_ADEK_WELL_2='home_adek_well_2'
const TRAD_HOME_ADEK_MED_1='home_adek_med_1'
const TRAD_HOME_ADEK_MED_2='home_adek_med_2'
const TRAD_HOME_ADEK_GIVE='home_adek_give'
const TRAD_HOME_ADEK_GIVE_TABIB='home_adek_give_tabib'
const TRAD_HOME_ADEK_DONE='home_adek_done'
const TRAD_UI_FULL='ui_full'
const TRAD_FIGHT_INVENTORY='fight_inventory'
const TRAD_FIGHT_ITEM_USED='fight_item_used'
const TRAD_FIGHT_NO_ITEM='fight_no_item'
const TRAD_FIGHT_FOOD='fight_food'
const TRAD_FIGHT_MANA_POTION='fight_mana_potion'
const TRAD_FIGHT_MANA_USED='fight_mana_used'
const TRAD_FIGHT_LAKLAK='fight_laklak'
const TRAD_FIGHT_LAKLAK_USED='fight_laklak_used'
const TRAD_FIGHT_PUTU='fight_putu'
const TRAD_FIGHT_PUTU_USED='fight_putu_used'
const TRAD_FIGHT_DEFEND='fight_defend'
const TRAD_FIGHT_FOR='fight_for'
const TRAD_FIGHT_TARGET='fight_target'
const TRAD_FIGHT_VERA_HIT='fight_vera_hit'
const TRAD_FIGHT_VERA_HURT='fight_vera_hurt'
const TRAD_FIGHT_VERA_DOWN='fight_vera_down'
const TRAD_FIGHT_VERA_HEALED='fight_vera_healed'
const TRAD_FIGHT_VERA_THANKS='fight_vera_thanks'
const TRAD_FIGHT_ENEMY_DOWN='fight_enemy_down'
const TRAD_FIGHT_DEFEND_TEXT='fight_defend_text'
const TRAD_FIGHT_EVADE='fight_evade'
const TRAD_FIGHT_RESIST='fight_resist'
const TRAD_FIGHT_SPIRIT='fight_spirit'
const TRAD_FIGHT_POISONED='fight_poisoned'
const TRAD_FIGHT_POISON_TICK='fight_poison_tick'
const TRAD_FIGHT_DRAIN='fight_drain'
const TRAD_FIGHT_CHARGE='fight_charge'
const TRAD_FIGHT_ENRAGE='fight_enrage'
const TRAD_FIGHT_VERA='fight_vera'
const TRAD_FIGHT_HEAL_ATTACK='fight_heal_attack'
const TRAD_FIGHT_DROP='fight_drop'
const TRAD_WORD_VERA='word_vera'
const TRAD_WORD_BANDIT1='word_bandit1'
const TRAD_WORD_BANDIT2='word_bandit2'
const TRAD_BANDIT_TIP='bandit_tip'
const TRAD_BANDIT_SCENE_1='bandit_scene_1'
const TRAD_BANDIT_SCENE_2='bandit_scene_2'
const TRAD_BANDIT_SCENE_3='bandit_scene_3'
const TRAD_BANDIT_SCENE_4='bandit_scene_4'
const TRAD_BANDIT_SCENE_5='bandit_scene_5'
const TRAD_VERA_MAP='vera_map'
const TRAD_VERA_BYE='vera_bye'
const TRAD_WORD_DARKUS='word_darkus'
const TRAD_WORD_TABIB='word_tabib'
const TRAD_TABIB_FIRST='tabib_first'
const TRAD_TABIB_AGAIN='tabib_again'
const TRAD_TABIB_HAVE='tabib_have'
const TRAD_TABIB_DONE='tabib_done'
# v7: alur Tabib -> rumah -> Desa Kepiting -> Bu Kepiting -> Desa Beruang -> jalan ke Ancient Dungeon
const TRAD_TABIB_JOIN_TIP='tabib_join_tip'
const TRAD_HOME_EXAM_1='home_exam_1'
const TRAD_HOME_EXAM_2='home_exam_2'
const TRAD_HOME_EXAM_3='home_exam_3'
const TRAD_HOME_EXAM_TIP='home_exam_tip'
const TRAD_CRAB_GUIDE_1='crab_guide_1'
const TRAD_CRAB_GUIDE_2='crab_guide_2'
const TRAD_CRAB_GUIDE_REMIND='crab_guide_remind'
const TRAD_CRABVILLAGE_AFTER='crabvillage_after'
const TRAD_CRAB_SHOP_INTRO='crab_shop_intro'
const TRAD_CRAB_SHOP_INFO='crab_shop_info'
const TRAD_CRAB_ESCORT_AGAIN='crab_escort_again'
const TRAD_JOURNEY_CAPTION='journey_caption'
const TRAD_JOURNEY_1='journey_1'
const TRAD_JOURNEY_2='journey_2'
const TRAD_BEAR_ARRIVE='bear_arrive'
const TRAD_BEAR_DOOR='bear_door'
const TRAD_BEAR_CHIEF='bear_chief'
const TRAD_BEAR_CHIEF_LOCKED='bear_chief_locked'
const TRAD_BEAR_CHIEF_OPEN='bear_chief_open'
const TRAD_BEAR_CHIEF_TIP='bear_chief_tip'
const TRAD_TABIB_ROAD='tabib_road'
const TRAD_TABIB_ROAD_TIP='tabib_road_tip'
const TRAD_TABIB_HAVE_JOIN='tabib_have_join'
const TRAD_DARKUS_SAVED='darkus_saved'
const TRAD_DARKUS_INTRO='darkus_intro'
const TRAD_DARKUS_OFFER='darkus_offer'
const TRAD_DARKUS_DECLINE='darkus_decline'
const TRAD_DARKUS_CHOSEN_KNIGHT='darkus_chosen_knight'
const TRAD_DARKUS_CHOSEN_ARCHER='darkus_chosen_archer'
const TRAD_DARKUS_CHOSEN_WIZARD='darkus_chosen_wizard'
const TRAD_DARKUS_CHOSEN_ASSASSIN='darkus_chosen_assassin'
const TRAD_DARKUS_CHOSEN_ENGINEER='darkus_chosen_engineer'
const TRAD_DARKUS_CHOSEN_SAGE='darkus_chosen_sage'
const TRAD_DARKUS_LICENSE='darkus_license'
const TRAD_DARKUS_AFTER='darkus_after'
const TRAD_DARKUS_ADVANCE='darkus_advance'
const TRAD_DARKUS_GATE='darkus_gate'
const TRAD_DUNGEON_LOCKED='dungeon_locked'
const TRAD_BOW_RECEIVED='bow_received'
const TRAD_WORD_BARONG='word_barong'
const TRAD_BARONG_INTRO='barong_intro'
const TRAD_BARONG_AGAIN='barong_again'
const TRAD_BOW_REWARD='bow_reward'
const TRAD_CRAB_TIP='crab_tip'
const TRAD_CRAB_PROGRESS='crab_progress'
const TRAD_BANDIT_BACK='bandit_back'
const TRAD_BANDIT_BACK_TIP='bandit_back_tip'
const TRAD_BEAR_TIP='bear_tip'
const TRAD_BEAR_LOCKED='bear_locked'
const TRAD_BEAR_PROGRESS='bear_progress'
const TRAD_BEAR_CLEARED='bear_cleared'
const TRAD_VERA_JOINED='vera_joined'
const TRAD_VERA_STAFF='vera_staff'
const TRAD_INTRO_OPEN='intro_open'
const TRAD_INTRO_ADEK_CALL='intro_adek_call'
const TRAD_INTRO_MOM_CALL='intro_mom_call'
const TRAD_INTRO_MOM_WAIT='intro_mom_wait'
const TRAD_INTRO_TIP_ADEK='intro_tip_adek'
const TRAD_INTRO_TIP_MOM='intro_tip_mom'
const TRAD_FIGHT_FOOD_USED='fight_food_used'
const TRAD_FIGHT_NO_MANA='fight_no_mana'
const TRAD_INTRO_ADEK='intro_adek'
const TRAD_INTRO_MOM='intro_mom'
const TRAD_INTRO_TIP='intro_tip'
const TRAD_WELL_START='well_start'
const TRAD_WELL_PENDING='well_pending'
const TRAD_WELL_READY='well_ready'
const TRAD_WELL_CHEER='well_cheer'
const TRAD_WELL_AFTER='well_after'
const TRAD_WELL_HAVE_MED='well_have_med'
const TRAD_WELL_DONE='well_done'
const TRAD_TREEVILLAGE_SHOP_MED='tree-village_shop_med'
const TRAD_CRABVILLAGE_WELL='crabvillage_well'
const TRAD_CRABVILLAGE_MED='crabvillage_med'
const TRAD_CRABVILLAGE_SHOP_MED='crabvillage_shop_med'
const TRAD_BEARVILLAGE_SHOP='beervillage_shop'
const TRAD_BEARVILLAGE_SHOP_MED='beervillage_shop_med'
const TRAD_ENDING='ending_text'


const TRAD_CRABVILLAGE_SHOP='crabvillage_shop'
const TRAD_CRABVILLAGE='crabvillage'

const TRAD_CRABVILLAGE_GAME1_ALREADYWON='crabvillage_game1'
const TRAD_CRABVILLAGE_GAME1_START='crabvillage_game1_start'
const TRAD_CRABVILLAGE_GAME1_WIN='crabvillage_game1_win'

const TRAD_BEARVILLAGE_BEEPLATFORM='beervillage_beeplatform'
const TRAD_BEARVILLAGE_BEEPLATFORM_START='beervillage_beeplatform_start'
const TRAD_BEARVILLAGE_BEEPLATFORM_WIN='beervillage_beeplatform_win'
const TRAD_BEARVILLAGE_BEVILROOM_START='beervillage_bevilroom_start'
const TRAD_BEARVILLAGE_BEVILROOM_WIN='beervillage_bevilroom_win'
const TRAD_BEE_BONUS='bee_bonus'
const TRAD_BEE_BONUS_NOTIF='bee_bonus_notif'


const TRAD_BUTTON_NEWGAME='button_newgame'
const TRAD_BUTTON_LOADGAME='button_loadgame'
const TRAD_BUTTON_CREATE='button_create'

const TRAD_LABEL_NOM='label_nom'
const TRAD_LABEL_PSEUDO='label_pseudo'
const TRAD_LABEL_PARTIES='label_parties'

const TRAD_LABEL_VOTREPSEUDO='label_votrepseudo'
const TRAD_BUTTON_RETOUR='button_retour'
const TRAD_BUTTON_EFFACER='button_effacer'
const TRAD_BUTTON_VALIDER='button_valider'

const TRAD_LABEL_RETOURAUMENU='label_retouraumenu'

const TRAD_UI_PAUSE='ui_pause'
const TRAD_UI_RESUME='ui_resume'
const TRAD_UI_INVENTORY='ui_inventory'
const TRAD_UI_SAVE='ui_save'
const TRAD_UI_SETTINGS='ui_settings'
const TRAD_UI_QUIT='ui_quit'
const TRAD_UI_QUIT_CONFIRM='ui_quit_confirm'
const TRAD_UI_QUIT_WARNING='ui_quit_warning'
const TRAD_UI_YES='ui_yes'
const TRAD_UI_NO='ui_no'
const TRAD_UI_SAVED='ui_saved'
const TRAD_UI_TOUCH='ui_touch'
const TRAD_UI_DIALOG_ANIMATION='ui_dialog_animation'
const TRAD_UI_CLOSE='ui_close'
const TRAD_UI_MENU='ui_menu'
const TRAD_UI_SHOP='ui_shop'
const TRAD_UI_EQUIP='ui_equip'
const TRAD_UI_DISPLAY='ui_display'
const TRAD_UI_USE='ui_use'
const TRAD_UI_BUY='ui_buy'
const TRAD_UI_OWNED='ui_owned'

const TRAD_FIGHT_ATTACK='fight_attack'
const TRAD_FIGHT_POTION='fight_potion'
const TRAD_FIGHT_FLEE='fight_flee'
const TRAD_FIGHT_BACK='fight_back'
const TRAD_FIGHT_PUNCH='fight_punch'
const TRAD_FIGHT_SPIDER='fight_spider'
const TRAD_FIGHT_APPEAR='fight_appear'
const TRAD_FIGHT_CHOOSE='fight_choose'
const TRAD_FIGHT_PLAYER_ATTACK='fight_player_attack'
const TRAD_FIGHT_CRITICAL='fight_critical'
const TRAD_FIGHT_ENEMY_ATTACK='fight_enemy_attack'
const TRAD_FIGHT_ENEMY_MISS='fight_enemy_miss'
const TRAD_FIGHT_MISS='fight_miss'
const TRAD_FIGHT_POTION_USED='fight_potion_used'
const TRAD_FIGHT_FLEE_OK='fight_flee_ok'
const TRAD_FIGHT_FLEE_FAIL='fight_flee_fail'
const TRAD_FIGHT_VICTORY='fight_victory'
const TRAD_FIGHT_DEFEAT='fight_defeat'



var lang=ID

var traductionsList={

	TRAD_BUTTON_NEWGAME:{
		FR:'Nouvelle partie',
		EN:'New Game'
	},
	TRAD_BUTTON_LOADGAME:{
		FR:'Charger une partie',
		EN:'Load previous Game'
	},
	TRAD_BUTTON_CREATE:{
		FR:'Crééer',
		EN:'Create'
	},
	TRAD_LABEL_NOM:{
		FR:'Nom',
		EN:'Name'
	},
	TRAD_LABEL_PSEUDO:{
		FR:'Pseudo',
		EN:'Nickname'
	},
	TRAD_LABEL_PARTIES:{
		FR:'Partie(s)',
		EN:'Game(s)'
	},

	TRAD_LABEL_VOTREPSEUDO:{
		FR:'Votre pseudo',
		EN:'You nickname'
	},

	TRAD_BUTTON_RETOUR:{
		FR:'RETOUR',
		EN:'BACK'
	},
	TRAD_BUTTON_EFFACER:{
		FR:'EFFACER',
		EN:'ERASE'
	},
	TRAD_BUTTON_VALIDER:{
		FR:'VALIDER',
		EN:'SUBMIT'
	},

	TRAD_LABEL_RETOURAUMENU:{
		FR:'RETOUR AU MENU',
		EN:'BACK TO THE MENU'
	},

	TRAD_UI_PAUSE:{FR:'Pause',EN:'Pause'},
	TRAD_UI_RESUME:{FR:'Reprendre',EN:'Resume'},
	TRAD_UI_INVENTORY:{FR:'Inventaire',EN:'Inventory'},
	TRAD_UI_SAVE:{FR:'Sauvegarder',EN:'Save'},
	TRAD_UI_SETTINGS:{FR:'Paramètres',EN:'Settings'},
	TRAD_UI_QUIT:{FR:'Quitter',EN:'Quit'},
	TRAD_UI_QUIT_CONFIRM:{FR:'Quitter la partie ?',EN:'Quit the game?'},
	TRAD_UI_QUIT_WARNING:{FR:'Pensez à sauvegarder !',EN:'Remember to save!'},
	TRAD_UI_YES:{FR:'Oui',EN:'Yes'},
	TRAD_UI_NO:{FR:'Non',EN:'No'},
	TRAD_UI_SAVED:{FR:'Partie sauvegardée',EN:'Game saved'},
	TRAD_UI_TOUCH:{FR:'Commandes tactiles',EN:'Touch controls'},
	TRAD_UI_DIALOG_ANIMATION:{FR:'Texte animé',EN:'Animated text'},
	TRAD_UI_CLOSE:{FR:'Fermer',EN:'Close'},
	TRAD_UI_MENU:{FR:'Menu',EN:'Menu'},
	TRAD_UI_SHOP:{FR:'Boutique',EN:'Shop'},
	TRAD_UI_EQUIP:{FR:'Equiper',EN:'Equip'},
	TRAD_UI_DISPLAY:{FR:'Afficher',EN:'Show'},
	TRAD_UI_USE:{FR:'Utiliser',EN:'Use'},
	TRAD_UI_BUY:{FR:'Acheter',EN:'Buy'},
	TRAD_UI_OWNED:{FR:'Déjà possédé',EN:'Owned'},

	TRAD_FIGHT_ATTACK:{FR:'Attaquer',EN:'Attack'},
	TRAD_FIGHT_POTION:{FR:'Potion x%d',EN:'Potion x%d'},
	TRAD_FIGHT_FLEE:{FR:'Fuir',EN:'Flee'},
	TRAD_FIGHT_BACK:{FR:'Retour',EN:'Back'},
	TRAD_FIGHT_PUNCH:{FR:'Coup de poing',EN:'Punch'},
	TRAD_FIGHT_SPIDER:{FR:'Araignée',EN:'Spider'},
	TRAD_FIGHT_APPEAR:{FR:'Une araignée surgit !',EN:'A spider appears!'},
	TRAD_FIGHT_CHOOSE:{FR:'Que fait %s ?',EN:'What will %s do?'},
	TRAD_FIGHT_PLAYER_ATTACK:{FR:'%s : %s !',EN:'%s uses %s!'},
	TRAD_FIGHT_CRITICAL:{FR:'Coup critique !',EN:'Critical hit!'},
	TRAD_FIGHT_ENEMY_ATTACK:{FR:"L'araignée attaque !",EN:'The spider attacks!'},
	TRAD_FIGHT_ENEMY_MISS:{FR:"L'araignée rate son coup !",EN:'The spider misses!'},
	TRAD_FIGHT_MISS:{FR:'Raté',EN:'Miss'},
	TRAD_FIGHT_POTION_USED:{FR:'%s boit une potion.',EN:'%s drinks a potion.'},
	TRAD_FIGHT_FLEE_OK:{FR:'Vous prenez la fuite !',EN:'You got away!'},
	TRAD_FIGHT_FLEE_FAIL:{FR:'Impossible de fuir !',EN:"Can't escape!"},
	TRAD_FIGHT_VICTORY:{FR:'Victoire ! +%d XP  +%d gemmes',EN:'Victory! +%d XP  +%d gems'},
	TRAD_FIGHT_DEFEAT:{FR:'%s est épuisé et recule...',EN:'%s is exhausted and retreats...'},


	TRAD_WORD_PRESENTATEUR:{
		FR:"Présentateur",
		EN:"Presenter"
	},
	TRAD_WORD_APICULTEUR:{
		FR:"Apiculteur",
		EN:"Beekeeper"
	},
	TRAD_WORD_VENDEUR:{
		FR:"Vendeur",
		EN:"Seller"
	},
	TRAD_WORD_GORDONMOM:{
		FR:"Maman de Ranbyus",
		EN:"Ranbyus's Mom"
	},
	
	TRAD_WORD_ARTISAN:{
		FR:"Artisan",
		EN:"Craftsman"
	},
	
	TRAD_WORD_HABITANT:{
		FR: "Habitant",
		EN: "Citizen"
	},

	#tree village
	TRAD_TREEVILLAGE_END:{
		FR:[
			["Bonjour Ranbyus !","Tu peux m'aider à réparer le puits ?"],
			[
				"Oui je pense, j'ai",
				"- vos clous;",
				"- le miel pour sceller les pierres;",
				"- et un nouveau seau. :)"
			],
			["Félicitations Ranbyus !","Je vais pouvoir réparer."],

		],
		EN:[
			["Hi Ranbyus !","Can you help me to repair the well ?"],
			[
				"Yes i think, i have",
				"- your nails;",
				"- honey to stick stones;",
				"- and a new bucket. :)"
			],
			["Congratulations Ranbyus !","I can repair now."],

		],
	},
	TRAD_TREEVILLAGE_PENDING:{
		FR:[
			["Bonjour Ranbyus !","Tu peux m'aider à réparer le puits ?"],
			[
				"Bonjour,",
				"Oui je pense, mais il me manque encore des objets...",
				"Il me manque"
				
			],
			"- les clous",
			"- le miel pour sceller les pierres",
			"- le nouveau seau"
		],
		EN:[
			["Hi Ranbyus !","Can you help me to repair the well ?"],
			[
				"Hi,",
				"Yes i think, but i miss some objects...",
				"i miss"
				
			],
			"- nails",
			"- honey, to stick stones",
			"- and a new bucket"
		]
	},
	TRAD_TREEVILLAGE_START:{
		FR:[
			["Bonjour Ranbyus !","Tu peux m'aider à réparer le puits ?"],
			["Bonjour monsieur.","Oui bien sûr, comment ?"],
			[
				"Il me faudrait de quoi sceller les pierres,",
				" des clous pour refixer l'armature en bois",
				" et un nouveau seau."
			],
			["Où puis-je trouver ça ?"],
			[
				"Tu devras parcourir les différents villages autour de nous,",
				" mais fais attention...",
				" des dangers guêtent dans nos forêts..."
			]
		],
		EN:[
			["Hi Ranbyus !","Can you help me to repair the well ?"],
			["Hi","Yes of course, how ?"],
			[
				"I need something to stick stones,",
				" some nails to repair wood structure",
				" and a new bucket."
			],
			["Where can i find it ?"],
			[
				"You should explore some villages around us,",
				" but you should be careful...",
				" there are dangers in woods ..."
			]
		],
	},

	TRAD_TREEVILLAGE_GEMHOUSE_START:{
		FR:[
			["Bonjour Ranbyus","Que puis-je pour toi ?"],
			["Bonjour Monsieur","Je souhaiterais gagner des Gems pour acheter une épée."],
			["Il y a des étoiles de Gormon enterrées dans notre village.","Si tu m'en rapportes, je te les echangerais contre une Gem chacunes","Ça t'intéresse ?"],
			["Oui, ça m'interesse mais comment les trouver ?"],
			["Je vais te donner une carte et une pelle."],
			["Merci pour la pelle et la carte."]
		],
		EN:[
			["Hi Ranbyus","What do you want ?"],
			["Hi","I want earn Gems to buy a sword."],
			["There are some Gormon star buried in our village.","I you give to me, i will give you one Gem per star","You want it ?"],
			["Yes, but how to find them ?"],
			["I will give to you a map and spade."],
			["Thanks, i got it, bye."]
		]
	},

	TRAD_TREEVILLAGE_GEMHOUSE_PENDING:{
		FR:[
			["Bonjour Ranbyus","Tu as trouvé toutes les étoiles ?"],
			[
				"Bonjour Monsieur.",
				"Non pas encore, il m'en reste encore des étoiles à trouver"
			],
			[
				"Bonjour Monsieur.",
				"Oui, je les ai toutes trouver",
				"Les voilà !"
			],
			["Merci pour les étoiles de Gormon.","Voilà tes 10 Gems."]
		],
		EN:[
			["Hi Ranbyus","Do you find all stars ?"],
			[
				"Hi.",
				"No for the moment, i have no find all yet"
			],
			[
				"Hi.",
				"Yes i found all",
				"There it is!"
			],
			["Thanks for Gormon stars.","I give to you 10 Gems."]
		]
	},

	TRAD_TREEVILLAGE_GEMHOUSE_END:{
		FR:[
			["Bonjour Ranbyus.","Désolé, je n'ai plus de mission pour toi ;)"]
		],
		EN:[
			["Hi Ranbyus.","Sorry, i have no mission to you ;)"]
		]
	},

	TRAD_TREEVILLAGE_SHOP:{
		FR:[
			["Bonjour Ranbyus","Que souhaites-tu ?"],
			["Bonjour monsieur","Je souhaiterais acheter un objet"],
			["Je vais t’afficher les produits en vente","Tu n’auras qu’a choisir"]
		],
		EN:[
			["Hi Ranbyus","What do you want ?"],
			["Hi","I want to buy an item"],
			["I will diplay to you some products i sell","You should choose one"]
		]
	},

	TRAD_TREEVILLAGE_GORDONHOME:{
		FR:[
			["Bonjour Ranbyus."],
			["Bonjour Maman, comment va Papa ?"],
			["Il est encore mal en point...",
			"depuis la tempête qui a ravagé le puits..",
			"Le problème c'est qu'en son absence,",
			"personne ne peut aider notre artisan",
			"a réparer notre unique puits...",
			]
		],
		EN:[
			["Hi Ranbyus."],
			["Hi Mom, how do Dad ?"],
			["He is not feeling well...",
			"since the storm which broke the well..",
			"The problem is with his absence,",
			"nobody can help crafsman ",
			"to repair the well...",
			]
		]
	},

	#crab village

	TRAD_CRABVILLAGE:{
		FR:[
			[
				"Bonjour jeune inconnu."
			],
			[
				"Bonjour,",
				"Il me faudrait des clous",
				"Pour réparer notre puits."
			],
			[
				"Tu es au bon endroit,",
				"Remporte les 2 épreuves.",
				"Ils te donneront un jeton",
				"Que tu pourras échanger",
				"Dans la boutique."
			]
		],
		EN:[
			[
				"Hi."
			],
			[
				"Hi,",
				"I want to buy some nails",
				"To repair our well."
			],
			[
				"You have found the right place,",
				"Win this two challenges.",
				"They will give to you  a token",
				"You will exchange it",
				"In the shop."
			]
		]

	},

	TRAD_CRABVILLAGE_GAME1_ALREADYWON:{
		FR:[
			"Re-bonjour,",
			"Désolé, mais vous avez déjà gagné...",
			],
		EN:[
			"Hi,",
			"Sorry but you have already won...",
			]	
	},
	TRAD_CRABVILLAGE_GAME1_START:{
		FR:[
			"Bonjour, pour remporter ce jeu",
			"Vous devez faire traverser",
			"Le crabe, l'algue et la méduse.",
			"Vous pouvez en tranporter un seul à la fois",
			"Attention si vous laissez seuls certains :",
			"Le crabe mange la méduse,",
			"La méduse mange l'algue."
			],
		EN:[
			"Hi, to win this game",
			"You will crosses",
			"The crab, the seaweed and the medusa.",
			"You can carry only one on the wooden raft",
			"Take care, if you let alone :",
			"The crab eat the medusa,",
			"The medusa eat the seaweed."
			],

	},
	TRAD_CRABVILLAGE_GAME1_WIN:{
		FR:[
			"Félicitations, tu remportes ce jeu !",
			"Voici 2 Gems en récompense."
			],
		EN:[
			"Congratulations, you win !",
			"Take 2 Gems."
			],

	},

	
	TRAD_CRABVILLAGE_SHOP:{
		FR:[
		"Bonjour,",
		"Choisis parmi nos produits",
		"Celui de ton choix."
		],
		EN:[
		"Hi,",
		"Choose in list",
		"Product you want."
		]	
	},

	#bear village
	
	TRAD_BEARVILLAGE_BEEPLATFORM:{
		FR:[
			
		],
		EN:[
			
		]
		
	},

	TRAD_BEARVILLAGE_BEEPLATFORM_START:{
		FR:[
			"Bonjour,",
			"Peux-tu m'aider à récuperer mon miel  ?",
			"Il te faudra aller à la ruche et me ramener mes 3 sceaux"
		],
		EN:[
			"Hi,",
			"Can you help me to get the honey  ?",
			"You should go to the honey house and get 3 bucket"
		],
	},

	TRAD_BEARVILLAGE_BEEPLATFORM_WIN:{
		FR:[
			"Bravo,",
			"Merci beaucoup",
			"Voila 4 Gems pour te remercier"
		],
		EN:[
			"Congratulations,",
			"Thanks a lot",
			"I give to you 4 Gems"
		],

	},

	TRAD_BEARVILLAGE_BEVILROOM_START:{
		FR:[
			"Bonjour,",
			"Peux tu m'aider ?",
			"Nous avons depuis quelques jours de méchantes BeVil",
			"Qui nous empêchent d'accéder à la ruche."
		],
		EN:[
			"Hi,",
			"Can you help me ?",
			"There are since few days bad BeVil",
			"They deny us to go to the hive."
		],

	},

	TRAD_BEARVILLAGE_BEVILROOM_WIN:{
		FR:[
			"Bravo,",
			"Un grand merci pour ton aide !",
			"Pour te remercier, voici 4 Gems"
		],
		EN:[
			"Congratulations,",
			"Thanks a lot !",
			"I give to you 4 Gems"
		],

	},

	TRAD_TREEVILLAGE_STARFOUND:{
		FR:"Une étoile de Gormon trouvée !!",
		EN:"One Gormon Star found !!",
		
	}


}

func setLang(lang_):
	lang=lang_

func getLang():
	return lang
	
# Terjemahan Bahasa Indonesia untuk menu, UI, pertarungan, dan nama NPC.
# Dialog cerita yang belum diterjemahkan akan memakai bahasa Inggris sebagai fallback.
var traductionsID = {
	TRAD_BUTTON_NEWGAME: "Mulai Permainan",
	TRAD_BUTTON_LOADGAME: "Muat Permainan",
	TRAD_BUTTON_CREATE: "Buat",
	TRAD_LABEL_NOM: "Nama",
	TRAD_LABEL_PSEUDO: "Nama Panggilan",
	TRAD_LABEL_PARTIES: "Permainan",
	TRAD_LABEL_VOTREPSEUDO: "Masukkan nama pemain",
	TRAD_BUTTON_RETOUR: "KEMBALI",
	TRAD_BUTTON_EFFACER: "HAPUS",
	TRAD_BUTTON_VALIDER: "KONFIRMASI",
	TRAD_LABEL_RETOURAUMENU: "KEMBALI KE MENU",
	TRAD_UI_PAUSE: "Jeda",
	TRAD_UI_RESUME: "Lanjutkan",
	TRAD_UI_INVENTORY: "Inventaris",
	TRAD_UI_SAVE: "Simpan",
	TRAD_UI_SETTINGS: "Pengaturan",
	TRAD_UI_QUIT: "Keluar",
	TRAD_UI_QUIT_CONFIRM: "Keluar dari permainan?",
	TRAD_UI_QUIT_WARNING: "Jangan lupa menyimpan!",
	TRAD_UI_YES: "Ya",
	TRAD_UI_NO: "Tidak",
	TRAD_UI_SAVED: "Permainan berhasil disimpan",
	TRAD_UI_TOUCH: "Kontrol layar sentuh",
	TRAD_UI_DIALOG_ANIMATION: "Animasi teks",
	TRAD_UI_CLOSE: "Tutup",
	TRAD_UI_MENU: "Menu",
	TRAD_UI_SHOP: "Toko",
	TRAD_UI_EQUIP: "Pasang",
	TRAD_UI_DISPLAY: "Tampilkan",
	TRAD_UI_USE: "Gunakan",
	TRAD_UI_BUY: "Beli",
	TRAD_UI_OWNED: "Sudah dimiliki",
	TRAD_FIGHT_ATTACK: "Serang",
	TRAD_FIGHT_POTION: "Ramuan x%d",
	TRAD_FIGHT_FLEE: "Kabur",
	TRAD_FIGHT_BACK: "Kembali",
	TRAD_FIGHT_PUNCH: "Pukulan",
	TRAD_FIGHT_SPIDER: "Laba-laba",
	TRAD_FIGHT_APPEAR: "Seekor laba-laba muncul!",
	TRAD_FIGHT_CHOOSE: "Apa yang akan dilakukan %s?",
	TRAD_FIGHT_PLAYER_ATTACK: "%s menggunakan %s!",
	TRAD_FIGHT_CRITICAL: "Serangan kritis!",
	TRAD_FIGHT_ENEMY_ATTACK: "Laba-laba menyerang!",
	TRAD_FIGHT_ENEMY_MISS: "Laba-laba meleset!",
	TRAD_FIGHT_MISS: "Meleset",
	TRAD_FIGHT_POTION_USED: "%s meminum ramuan.",
	TRAD_UI_FULL: "HP & Mana sudah penuh",
	TRAD_FIGHT_INVENTORY: "Inventaris",
	TRAD_FIGHT_ITEM_USED: "%s memakai %s.",
	TRAD_FIGHT_NO_ITEM: "(tidak ada item)",
	TRAD_FIGHT_FOOD: "Bika x%d",
	TRAD_FIGHT_MANA_POTION: "Ramuan MP x%d",
	TRAD_FIGHT_MANA_USED: "%s meminum ramuan mana. Mana pulih!",
	TRAD_FIGHT_LAKLAK: "Laklak x%d",
	TRAD_FIGHT_PUTU: "Putu x%d",
	TRAD_FIGHT_PUTU_USED: "%s makan kue putu. HP & Mana pulih!",
	TRAD_FIGHT_LAKLAK_USED: "%s makan laklak. HP & Mana pulih!",
	TRAD_FIGHT_FOOD_USED: "%s makan bika ambon. HP & Mana pulih!",
	TRAD_FIGHT_NO_MANA: "Mana kurang!",
	TRAD_FIGHT_FLEE_OK: "Kamu berhasil kabur!",
	TRAD_FIGHT_FLEE_FAIL: "Tidak bisa kabur!",
	TRAD_FIGHT_VICTORY: "Menang! +%d XP  +%d permata",
	TRAD_FIGHT_DEFEAT: "%s kelelahan dan mundur...",

	# --- nama pembicara (setiap NPC punya nama sendiri) ---
	TRAD_WORD_PRESENTATEUR: "Pemandu acara",
	TRAD_WORD_APICULTEUR: "Peternak Lebah",
	TRAD_WORD_VENDEUR: "Penjual",
	TRAD_WORD_GORDONMOM: "Bunda",
	TRAD_WORD_ADEK: "Adek",
	TRAD_WORD_ARTISAN: "Pak Tukang",
	TRAD_WORD_HABITANT: "Penduduk",
	TRAD_WORD_TREESELLER: "Pak Dagang",
	TRAD_WORD_GEMKEEPER: "Penjaga Permata",
	TRAD_WORD_CRABKID: "Anak Desa",
	TRAD_WORD_CRABSELLER: "Bu Kepiting",
	TRAD_WORD_BEARSELLER: "Pak Beruang",

	TRAD_TREEVILLAGE_STARFOUND: "Bintang Gormon ditemukan!",
	TRAD_WELL_REPAIRED: "Sumur kembali berfungsi!",
	TRAD_ENDING: "Ranbyus kembali ke Desa Pohon bersama Darkus, Pak Tabib, Kepala Desa Beruang, dan Bu Kepiting.\n\nWarga berlarian menyambut mereka. Setelah perjalanan panjang, semua akhirnya pulang dengan selamat.\n\nPak Tabib segera memeriksa Adek dan meracik obat dari Buah Suwarga. Ranbyus menggenggam tangan adiknya sambil menunggu.\n\nPerlahan, Adek membuka mata.\nAdek: Kak...? Kakak benar-benar pulang...\nRanbyus: Iya, Dek. Kakak sudah menepati janji. Kamu akan baik-baik saja.\n\nWarga bersorak lega. Kabut dingin mulai menghilang dari utara, dan Desa Pohon kembali dipenuhi harapan.\n\nTAMAT — Terima kasih sudah bermain!",

	# ===== Pertarungan: aksi & efek musuh =====
	TRAD_FIGHT_DEFEND: "Bertahan",
	TRAD_FIGHT_FOR: "Untuk %s",
	TRAD_FIGHT_TARGET: "Serang siapa?",
	TRAD_FIGHT_VERA_HIT: "%s menyerang Vera!",
	TRAD_FIGHT_VERA_HURT: "Vera terluka! Pakai Inventaris untuk menyembuhkannya.",
	TRAD_FIGHT_VERA_DOWN: "Vera kelelahan dan tidak bisa membantu!",
	TRAD_FIGHT_VERA_HEALED: "%s menyembuhkan Vera.",
	TRAD_FIGHT_VERA_THANKS: "Vera berterima kasih dan memberikan Kue Putu!",
	TRAD_FIGHT_ENEMY_DOWN: "%s tumbang!",
	TRAD_FIGHT_DEFEND_TEXT: "%s mengangkat perisai dan bersiap menahan serangan!",
	TRAD_FIGHT_EVADE: "%s menghindar dengan lincah!",
	TRAD_FIGHT_RESIST: "Serangan fisik kurang mempan pada hantu!",
	TRAD_FIGHT_SPIRIT: "Kekuatan suci menghantam keras!",
	TRAD_FIGHT_POISONED: "%s keracunan!",
	TRAD_FIGHT_POISON_TICK: "Racun menggerogoti %s.",
	TRAD_FIGHT_DRAIN: "Tenaga %s tersedot!",
	TRAD_FIGHT_CHARGE: "%s mengumpulkan tenaga besar...",
	TRAD_FIGHT_ENRAGE: "%s mengamuk!",
	TRAD_FIGHT_VERA: "Vera melepaskan sihir gelap!",
	TRAD_FIGHT_HEAL_ATTACK: "%s pulih sedikit.",
	TRAD_FIGHT_DROP: "Mendapat %s.",

	# ===== Bandit, Vera, dan tongkat kayu =====
	TRAD_WORD_VERA: "Vera",
	TRAD_WORD_BANDIT1: "Bandit Merah",
	TRAD_WORD_BANDIT2: "Bandit Biru",
	TRAD_BANDIT_TIP: "Suara benturan terdengar dari sumur. Sebaiknya periksa ke sana.",
	TRAD_BANDIT_SCENE_1: [
		["@bandit1", ["Hahaha! Sumur tua ini sudah hampir roboh!", "Bongkar semua kayu dan besinya, kita jual di kota!"]],
		["@bandit2", ["Warga desa ini mana berani melawan kita, Bos."]],
		["@hero", ["Hei! Berhenti merusak sumur kami!"]],
		["@bandit1", ["Hah? Ada bocah ingusan.", "Pergi sana sebelum kupatahkan kakimu!"]],
		["@hero", ["Sumur itu satu-satunya air bersih di desa ini!", "Adikku sedang sakit, kami butuh air itu!"]],
		["@bandit2", ["Bukan urusan kami. Kalau berani, lawan kami berdua!"]],
		["@hero", ["Kalau begitu... aku akan mengusir kalian!"]]
	],
	TRAD_BANDIT_SCENE_2: [
		["@bandit1", ["Hahaha! Sudah kubilang, bocah.", "Satu lawan dua mana bisa menang!"]],
		["@bandit2", ["Habisi saja dia, Bos. Biar tidak mengganggu lagi."]],
		["@hero", ["Uhh... badanku tidak mau bergerak..."]]
	],
	TRAD_BANDIT_SCENE_3: [
		["@vera", ["Hei! Kalian berani-beraninya sama anak kecil!"]],
		["@bandit1", ["S-siapa itu?! Ada gadis bertanduk melayang...!"]],
		["@vera", ["Dua orang dewasa mengeroyok satu anak kecil?", "Memalukan. Rasakan ini!"]]
	],
	TRAD_BANDIT_SCENE_4: [
		["@bandit2", ["Mu-mundur, Bos! Dia bukan manusia biasa!"]],
		["@bandit1", ["Awas kau! Kami pasti kembali!"]]
	],
	TRAD_BANDIT_SCENE_5: [
		["@vera", ["Kamu tidak apa-apa? Dasar nekat.", "Melawan dua orang sendirian, mana bisa menang."]],
		["@hero", ["Terima kasih sudah menolongku. Siapa namamu?"]],
		["@vera", ["Vera. Aku hanya kebetulan lewat dan mendengar keributan."]],
		["@hero", ["Sumur ini dirusak mereka dan adikku sakit parah.", "Aku harus mencari bahan perbaikan di desa-desa lain."]],
		["@vera", ["Perjalanan yang berbahaya untuk dilakukan sendirian...", "Ambil ini. Tongkat Kayu, bisa dipakai siapa saja."]],
		["", ["{nama} menerima Tongkat Kayu dari Vera.", "Luka dan tenaganya pulih sepenuhnya."]],
		["@vera", ["Dengar baik-baik, tiap senjata punya jenis serangan sendiri.", "Pedang Kayu hanya menghasilkan serangan fisik."]],
		["@vera", ["Tongkat ini lain. Ayunan Tongkat itu serangan fisik biasa,", "tapi sisanya adalah sihir. Lebih kuat dan menembus hantu."]],
		["@hero", ["Tapi sihir pasti butuh tenaga ya?"]],
		["@vera", ["Betul, sihir memakai MP. Kalau MP habis, kamu cuma bisa mengayunkan tongkat.", "MP pulih pelan-pelan selama kamu berjalan, atau lewat makanan dan ramuan."]],
		["@hero", ["Terima kasih, Vera!"]],
		["@vera", ["Aku akan menemanimu sampai desa berikutnya.", "Setelah itu urusanku sendiri. Jangan mati duluan, ya."]]
	],
	TRAD_WORD_DARKUS: "Darkus",
	TRAD_WORD_TABIB: "Pak Tabib",
	TRAD_WORD_BARONG: "Barong",
	TRAD_BARONG_INTRO: [
		["@barong", ["Grrhm... pelanggan! Sudah lama kiosku sepi.", "Aku Barong, penjaga kios tua di depan Ancient Dungeon.", "Ramuan dan makanan, bekal sebelum masuk ke dalam. Silakan pilih."]]
	],
	TRAD_BARONG_AGAIN: [
		["@barong", ["Butuh bekal lagi? Silakan pilih."]]
	],
	TRAD_BOW_RECEIVED: "Mendapat Busur Kayu.",
	TRAD_CRAB_TIP: "Kalahkan 5 monster pantai!",
	TRAD_CRAB_PROGRESS: "Monster pantai dikalahkan: %d/5",
	TRAD_BANDIT_BACK_TIP: "Dua bandit menghadang di tengah desa!",
	TRAD_BANDIT_BACK: [
		["@bandit1", ["Hehehe... akhirnya ketemu juga, bocah sumur!"]],
		["@bandit2", ["Mana si gadis bertanduk itu? Kali ini kamu sendirian!"]],
		["@hero", ["Kalian lagi! Kalian mengikutiku sampai ke sini?"]],
		["@bandit1", ["Kami masih dendam. Hajar dia berdua!"]],
		["@hero", ["Dua lawan satu lagi... tapi aku tidak akan kalah kali ini!"]]
	],
	TRAD_BOW_REWARD: [
		["@anak", ["Kakak! Tunggu!", "Aku lihat semuanya dari jauh. Kakak hebat sekali!"]],
		["@hero", ["Terima kasih. Syukurlah desa ini sudah aman."]],
		["@anak", ["Warga desa mau berterima kasih.", "Ini Busur Kayu peninggalan nelayan tua. Pakailah, Kak!"]],
		["", ["{nama} menerima Busur Kayu."]],
		["@anak", ["Kalau mau berlatih lagi, monster pantai muncul lagi tiap kali Kakak datang."]]
	],
	TRAD_BEAR_LOCKED: [
		["", ["Jalan menuju desa beruang masih terlalu berbahaya.", "Selesaikan dulu urusan di desa kepiting (kalahkan semua monster dan bandit di sana)."]]
	],
	TRAD_BEAR_TIP: "Kalahkan 3 musuh desa. Lihat panel TUJUAN.",
	TRAD_BEAR_PROGRESS: "Musuh desa beruang dikalahkan: %d/3",
	TRAD_BEAR_CLEARED: "Desa aman! Gerbang dungeon terbuka.",
	TRAD_DUNGEON_LOCKED: [
		["", ["Gerbang batu Ancient Dungeon tertutup rapat.", "Gerbang ini baru terbuka setelah semua musuh di desa beruang kamu kalahkan."]]
	],
	TRAD_DARKUS_INTRO: [
		["@darkus", ["Oh? Ada pengunjung. Namaku Darkus. Aku menjaga gerbang dan meneliti reruntuhan ini.", "Kabut dari utara... belakangan aku juga merasakannya."]],
		["@hero", ["Aku {nama}. Aku mencari Buah Suwarga untuk menyelamatkan adikku."]],
		["@darkus", ["Buah Suwarga... nama itu sudah lama tak terdengar. Jika legenda benar, mungkin ia berada di balik segel tua.", "Di dalam ada makhluk yang menjaga ruang terdalam. Kamu belum siap masuk hanya dengan senjata kayu.", "Aku bisa membukakan jalan class untukmu: Ksatria, Pemburu, atau Penyihir."]]
	],
	TRAD_DARKUS_OFFER: [
		["@darkus", ["Pilih dengan hati-hati. Class tidak bisa diganti setelah dibuka."]]
	],
	TRAD_DARKUS_DECLINE: [
		["@darkus", ["Belum yakin? Tidak apa-apa.", "Kembalilah kalau sudah siap. Aku di sini saja."]]
	],
	TRAD_DARKUS_CHOSEN_KNIGHT: [
		["@darkus", ["Ksatria. Tangguh dan berdiri paling depan.", "Terimalah Pedang Ksatria beserta Perisainya."]]
	],
	TRAD_DARKUS_CHOSEN_ARCHER: [
		["@darkus", ["Pemburu. Lincah, dan menyerang dari jauh.", "Terimalah Busur Pemburu ini."]]
	],
	TRAD_DARKUS_CHOSEN_WIZARD: [
		["@darkus", ["Penyihir. Rapuh, tapi sihirnya mematikan.", "Terimalah Tongkat Sihir ini."]]
	],
	TRAD_DARKUS_ADVANCE: [
		["@darkus", ["Ular malam, pocong, leak bara, dan zombie desa... semuanya sudah kamu kalahkan?", "Kamu sudah melewati ujian kecil dungeon ini. Aku melihat jalan lain di dirimu."]],
		["@darkus", ["Pilih jalan lanjutanmu: Asasin atau Engineer. Setelah dipilih, tidak bisa diganti."]]
	],
	TRAD_DARKUS_CHOSEN_ASSASSIN: [
		["@darkus", ["Asasin. Cepat, senyap, dan mematikan.", "Terimalah Belati Bayangan ini."]]
	],
	TRAD_DARKUS_CHOSEN_ENGINEER: [
		["@darkus", ["Engineer. Otakmu yang bekerja, bukan hanya ototmu.", "Terimalah Sci-Fi Wrench ini. Pasang Kotak Mekanik, dan biarkan musuh menyerangnya."]]
	],
	TRAD_DARKUS_LICENSE: [
		["@darkus", ["Kamu membawa Akses Class dari kios Barong, ya?", "Pilih class yang mau diaktifkan. Setelah aktif, aksesnya hilang dan senjatanya langsung terpasang."]]
	],
	TRAD_DARKUS_CHOSEN_SAGE: [
		["@darkus", ["Sage. Menyembuhkan sambil menyerang.", "Terimalah Orb Sage ini."]]
	],
	TRAD_DARKUS_AFTER: [
		["@darkus", ["Kekuatan classmu sudah terbuka dan senjatanya sudah terpasang.", "Gerbang di belakangku menuju Ancient Dungeon. Berhati-hatilah, {nama}."]],
		["@darkus", ["Satu hal lagi. Di ruang terakhir ada penjaga bernama Bhuta Kala.", "Ia menjaga segel sesuatu yang jauh lebih jahat dari dirinya sendiri."]],
		["@hero", ["Kamu sudah lama meneliti segel itu, ya?"]],
		["@darkus", ["Ya... dan belakangan kepalaku sering terasa berat. Seperti ada yang berbisik dari balik batu.", "Setiap kabut datang, suara itu semakin jelas... Ah, lupakan. Kita harus fokus pada perjalananmu."]]
	],
	TRAD_DARKUS_SAVED: [
		["@darkus", ["Kepalaku... akhirnya terasa ringan. Aku... aku sudah sadar kembali.", "Tubuhku bergerak sendiri, dan aku tak bisa menghentikannya. Aku mendengar semuanya, tapi tak mampu melawan Satan."]],
		["@hero", ["Yang penting kamu selamat, Darkus."]],
		["@darkus", ["Maafkan aku, {nama}. Terima kasih sudah membebaskanku dari Satan.", "Segelnya sudah hancur. Sekarang ambil Buah Suwarga itu—kita harus membawanya pulang untuk menolong Adek."]],
		["@darkus", ["Pulanglah. Temui adikmu. Semoga ia lekas sembuh."]]
	],
	TRAD_DARKUS_GATE: [
		["@darkus", ["Tunggu dulu. Kamu belum punya class.", "Bicaralah denganku sebelum masuk."]]
	],
	TRAD_VERA_JOINED: "Vera ikut menemanimu.",
	TRAD_VERA_STAFF: "Mendapat Tongkat Kayu.",
	TRAD_VERA_MAP: [
		["@vera", ["Jalan ini dijaga makhluk-makhluk jahat.", "Aku akan membantumu bertarung. Jangan menjauh dariku."]]
	],
	TRAD_VERA_BYE: [
		["@vera", ["Kita sudah sampai di desa berikutnya.", "Perjalananku cukup sampai di sini."]],
		["@hero", ["Terima kasih atas bantuanmu, Vera.", "Tongkat ini akan kujaga baik-baik."]],
		["@vera", ["Hmph. Jangan terlalu bergantung padaku.", "Selamatkan adikmu. Sampai jumpa, {nama}!"]]
	],

	# ===================== RUMAH RANBYUS =====================
	# Format dialog: [ [pembicara, [baris, baris, ...]], ... ]
	# Pembicara: "@hero" = nama pemain, "@bunda", "@adek", "@tukang", dst. (lihat SPEAKER_KEYS)
	# Kosong ("") = narasi tanpa nama.

	# Bunda - tahap 1 (sumur rusak), pertama kali diajak bicara
	TRAD_HOME_MOM_WELL_1: [
		["@bunda", ["Kamu sudah bangun, {nama}... Semalam badai dingin datang dari arah utara.", "Kabut tebal terlihat di jalan menuju dungeon. Anehnya, udara di sekitar sumur juga terasa dingin. Lalu sumur kita dirusak bandit."]],
		["@hero", ["Lalu air bersihnya bagaimana, Bun?"]],
		["@bunda", ["Air di tempayan tinggal sedikit. Adekmu demam tinggi dan perlu air bersih.", "Bunda khawatir hawa dingin yang datang entah dari mana itu membuat keadaannya semakin buruk."]],
		["@hero", ["Aku akan memperbaiki sumur dan mencari bantuan untuk Adek, Bun."]],
		["@bunda", ["Temui Pak Tukang di dekat sumur. Dia tahu bahan apa yang dibutuhkan.", "Kalau air bersih sudah mengalir lagi, tabib bisa memeriksa Adek dengan benar.", "Hati-hati di luar sana, Nak. Dan ingat janjimu: pulanglah."]]
	],
	TRAD_HOME_MOM_WELL_2: [
		["@bunda", ["Kalau belum, temui Pak Tukang di dekat sumur.", "Bahan-bahannya harus dicari di desa-desa lain."]],
		["@hero", ["Iya, Bun. Aku akan hati-hati."]],
		["@bunda", ["Ada laba-laba dan makhluk jahat di hutan.", "Bawa pedang dan ramuan, ya. Pulanglah dengan selamat."]]
	],
	TRAD_HOME_MOM_WELL_READY: [
		["@bunda", ["Bahannya sudah lengkap, {nama}?!", "Cepat bawa ke Pak Tukang di sumur!"]],
		["@hero", ["Siap, Bun!"]]
	],
	# Bunda - tahap 2 (sumur sudah pulih, cari obat)
	TRAD_HOME_MOM_MED_1: [
		["@bunda", ["Air sumur sudah mengalir lagi. Terima kasih, {nama}...", "Tapi demam adekmu belum turun juga."]],
		["@hero", ["Obat biasa tidak mempan, Bun. Apa tidak ada cara lain?"]],
		["@bunda", ["Ada seorang tabib yang baru singgah di jalan desa, tak jauh dari sumur.", "Temuilah dia. Siapa tahu dia tahu obat yang tepat."]],
		["@hero", ["Aku temui dia sekarang, Bun.", "Aku janji akan menyembuhkan adek."]]
	],
	TRAD_HOME_MOM_MED_2: [
		["@bunda", ["Temui Pak Tabib di jalan desa, Nak. Dia tahu cara menyembuhkan adekmu.", "Bunda yang jaga adekmu di sini."]],
		["@hero", ["Aku tidak akan lama, Bun."]]
	],
	TRAD_HOME_MOM_MED_3: [
		["@bunda", ["Pergilah, Nak. Bunda yang jaga adekmu di sini.", "Pak Tabib bilang mulai dari Desa Kepiting. Hati-hati di jalan."]],
		["@hero", ["Iya, Bun. Aku pasti membawa obatnya."]]
	],
	TRAD_HOME_MOM_MED_HAVE: [
		["@bunda", ["Itu... buah yang dikatakan Pak Tabib?! Cahayanya hangat sekali...", "Cepat berikan pada adekmu, {nama}. Dia ada di ranjangnya."]]
	],
	TRAD_HOME_MOM_DONE: [
		["@bunda", ["Adekmu mulai tersenyum lagi...", "Terima kasih sudah berjuang untuk kami, {nama}."]]
	],

	# Adek (ranjang)
	TRAD_HOME_ADEK_WELL_1: [
		["", ["Adek tertidur dengan kompres di dahinya.", "Napasnya terdengar berat dan cepat..."]],
		["@hero", ["Bertahanlah, Dek.", "Kakak perbaiki sumurnya dulu, ya."]]
	],
	TRAD_HOME_ADEK_WELL_2: [
		["@adek", ["...Kak...?", "Airnya... sudah habis, ya?"]],
		["@hero", ["Belum, Dek. Tidur saja dulu.", "Kakak pergi sebentar."]],
		["@adek", ["Hati-hati... ya, Kak..."]]
	],
	TRAD_HOME_ADEK_MED_1: [
		["@adek", ["Kak... badan Adek panas sekali...", "Sumurnya sudah jadi, ya? Adek dengar suara air."]],
		["@hero", ["Iya, Dek. Sekarang Kakak cari obatmu.", "Tunggu Kakak pulang, ya."]],
		["@adek", ["Janji ya, Kak..."]]
	],
	TRAD_HOME_ADEK_MED_2: [
		["", ["Adek menggigil pelan di balik selimut."]],
		["@hero", ["Sedikit lagi, Dek.", "Kakak pasti membawa obatnya."]]
	],
	TRAD_HOME_ADEK_GIVE: [
		["@hero", ["Dek, bangun sebentar...", "Kakak bawa Buah Suwarga. Makan pelan-pelan, ya."]],
		["", ["{nama} menyuapi Adek potongan Buah Suwarga.", "Cahaya hangat menyebar di tubuh Adek, dan perlahan napasnya terdengar tenang..."]]
	],
	# ===== Intro permainan =====
	# 1) Ranbyus bertanya keadaan adek pada Bunda dan bertekad membantu
	TRAD_INTRO_OPEN: [
		["@hero", ["Bun, bagaimana keadaan Adek pagi ini?"]],
		["@bunda", ["Demamnya masih tinggi, {nama}. Semalam dia susah tidur.", "Air bersih pun hampir habis. Sumur kita dirusak bandit semalam."]],
		["@hero", ["Aku tidak bisa diam saja, Bun.", "Aku akan membantu menyembuhkan Adek."]],
		["@hero", ["Akan kucari bahan untuk memperbaiki sumur,", "lalu kucari obat untuknya."]],
		["@bunda", ["Tapi di luar sana berbahaya, Nak.", "Ada laba-laba dan makhluk jahat di jalan."]],
		["@hero", ["Aku sudah bertekad, Bun. Ini demi Adek."]]
	],
	# 2) Adek mendengar dan memanggil Kakak
	TRAD_INTRO_ADEK_CALL: [
		["@adek", ["...Kak?", "Adek dengar semuanya tadi..."]],
		["@adek", ["Kak, sini sebentar. Adek mau ngomong."]]
	],
	TRAD_INTRO_TIP_ADEK: "Adek memanggilmu. Dekati ranjang Adek lalu tekan E.",
	TRAD_INTRO_ADEK: [
		["@adek", ["Kak... jangan pergi, ya.", "Di luar kan banyak monster."]],
		["@hero", ["Dek, Kakak harus pergi.", "Kalau sumurnya sudah diperbaiki, air bersih ada lagi,", "dan Kakak bisa memanggil tabib untuk membuatkan obat buat Adek."]],
		["@adek", ["Adek nggak peduli sama demamnya...", "Adek takut Kakak kenapa-napa di jalan."]],
		["@adek", ["Kalau Kakak nggak pulang, Adek sendirian di sini..."]],
		["@hero", ["Hei, jangan nangis. Kakak pasti pulang.", "Kakak janji."]],
		["@adek", ["Janji beneran, ya, Kak?", "Kalau gitu... bawa ini."]],
		["@adek", ["Ini Ramuan HP. Diminum kalau Kakak terluka.", "Adek tunggu Kakak di rumah. Hati-hati, ya..."]],
		["@hero", ["Iya, Dek. Makasih. Kakak pulang secepatnya."]]
	],
	TRAD_INTRO_MOM_WAIT: [
		["@bunda", ["Adekmu memanggilmu tadi, {nama}.", "Temui dia dulu sebelum berangkat."]]
	],
	# 3) Saat hendak keluar, Bunda memanggil
	TRAD_INTRO_MOM_CALL: [
		["@bunda", ["{nama}, tunggu sebentar!", "Sini, Nak. Temui Bunda dulu sebelum berangkat."]]
	],
	TRAD_INTRO_TIP_MOM: "Bunda memanggilmu. Dekati Bunda lalu tekan E.",
	TRAD_INTRO_MOM: [
		["@bunda", ["Bunda baru selesai membuat bika ambon.", "Masih hangat. Bawa ya, buat bekal di jalan."]],
		["@hero", ["Wah, harum sekali, Bun. Terima kasih!"]],
		["@bunda", ["Makan kalau kamu lelah. HP dan tenagamu (Mana) akan pulih.", "Jangan dihabiskan sekaligus. Pulanglah dengan selamat, ya."]]
	],
	TRAD_INTRO_TIP: "Buka Menu > Inventaris > Gunakan untuk minum ramuan atau makan bika.",
	TRAD_HOME_ADEK_GIVE_TABIB: [
		["@tabib", ["Air sumur yang bersih, dan buah ini... Suapkan pelan-pelan, {nama}.", "Aku siapkan racikannya."]],
		["@hero", ["Dek, bangun sebentar...", "Kakak bawa Buah Suwarga. Makan pelan-pelan, ya."]],
		["", ["{nama} menyuapi Adek potongan Buah Suwarga.", "Cahaya hangat menyebar di tubuh Adek, dan perlahan napasnya terdengar tenang..."]]
	],
	TRAD_HOME_ADEK_DONE: [
		["@adek", ["Kak... terima kasih sudah pulang.", "Adek sudah tidak panas lagi."]]
	],

	# ===================== DESA POHON =====================
	# Pak Tukang di sumur
	TRAD_WELL_START: [
		["@tukang", ["Kamu {nama}, anak Bunda itu, bukan?", "Maaf, sumur ini sulit kuperbaiki sendirian."]],
		["@hero", ["Apa yang bisa kubantu, Pak?", "Adikku sakit dan kami butuh air bersih."]],
		["@tukang", ["Aku butuh tiga bahan:", "paku untuk menguatkan rangka kayu,", "madu hutan untuk merekatkan batu,", "dan timba baru untuk menimba air."]],
		["@hero", ["Di mana aku bisa mendapatkannya?"]],
		["@tukang", ["Jelajahilah desa-desa di sekitar kita.", "Tapi hati-hati...", "Ada monster yang mengintai di hutan."]]
	],
	TRAD_WELL_PENDING: [
		["@tukang", ["Kamu kembali, {nama}.", "Sudah dapat bahan-bahan untuk sumurnya?"]],
		["@hero", ["Belum semuanya, Pak.", "Masih ada yang kurang."]]
	],
	TRAD_WELL_READY: [
		["@tukang", ["Kamu kembali, {nama}!", "Sudah dapat semua bahannya?"]],
		["@hero", ["Sudah, Pak. Ini paku, madu hutan,", "dan timba barunya!"]],
		["@tukang", ["Luar biasa! Serahkan padaku.", "Sumur ini akan segera berfungsi lagi."]]
	],
	TRAD_WELL_CHEER: [
		["@tukang", ["Selesai! Lihat, airnya mengalir lagi!"]],
		["@hero", ["Akhirnya warga punya air bersih lagi. Tapi aku masih khawatir pada Adek."]],
		["@tukang", ["Sekarang tabib bisa memeriksa adikmu dengan air yang bersih.", "Ada seorang tabib yang singgah di jalan desa. Temuilah dia."]],
		["@hero", ["Terima kasih, Pak. Aku akan mencari tahu apa yang menyebabkan Adek sakit."]]
	],
	TRAD_WELL_AFTER: [
		["@tukang", ["Sumur sudah beres. Sekarang giliran adikmu.", "Temui tabib yang singgah di jalan desa itu."]]
	],
	TRAD_WELL_HAVE_MED: [
		["@tukang", ["Itu buah untuk adikmu?", "Jangan buang waktu, cepat pulang dan berikan padanya!"]]
	],
	# Pak Tabib (muncul di jalan desa pohon setelah sumur pulih)
	TRAD_TABIB_FIRST: [
		["@tabib", ["Kamu yang memperbaiki sumur itu? Bagus.", "Dengan air bersih, aku bisa meracik obat dengan benar."]],
		["@hero", ["Tolong selamatkan Adek, Pak.", "Dia sakit sejak kabut dingin turun dari utara."]],
		["@tabib", ["Kabut dingin... Aku tidak mau menebak-nebak dari cerita saja.", "Antar aku ke rumahmu. Aku harus melihat adikmu sendiri."]],
		["@hero", ["Baik, Pak. Ikuti aku."]]
	],
	TRAD_TABIB_JOIN_TIP: "Pak Tabib ikut denganmu. Antar dia ke rumah untuk memeriksa Adek.",
	TRAD_TABIB_AGAIN: [
		["@tabib", ["Aku menunggu di sini. Jalan di belakangku menuju Ancient Dungeon.", "Aku tidak ikut masuk, tapi racikanku sudah siap."]],
		["@tabib", ["Hati-hati di dalam sana, {nama}. Hawa dinginnya bukan main-main."]]
	],
	TRAD_TABIB_HAVE: [
		["@tabib", ["Itu... Buah Suwarga! Cahayanya hangat sekali."]],
		["@hero", ["Aku mengalahkan penjaganya, Pak."]],
		["@tabib", ["Jangan buang waktu. Aku ikut pulang bersamamu.", "Buah ini harus disuapkan selagi segar, dan racikanku siap dipakai."]]
	],
	TRAD_TABIB_DONE: [
		["@tabib", ["Adikmu sudah sehat? Syukurlah.", "Desa ini berutang budi padamu, {nama}."]]
	],
	# ===== v7: Tabib memeriksa Adek di rumah =====
	TRAD_HOME_EXAM_1: [
		["@bunda", ["Silakan masuk, Pak Tabib. Adek ada di ranjang itu."]],
		["@tabib", ["Terima kasih, Bu. Beri aku ruang sebentar.", "Aku akan memeriksanya dengan teliti."]]
	],
	TRAD_HOME_EXAM_2: [
		["", ["Tabib menempelkan telapak tangan di dahi Adek, lalu memeriksa jari-jarinya satu per satu."]],
		["@tabib", ["Dahinya dingin seperti es, tapi tubuhnya terbakar demam...", "Dan bercak biru pucat ini di ujung jarinya..."]],
		["@hero", ["Pak Tabib? Adek sakit apa?"]],
		["@tabib", ["Ini bukan demam biasa. Ini... ini...", "Racun dingin? Tapi tidak sepekat ini. Tidak pernah sepekat ini."]],
		["@bunda", ["Jadi... tidak ada obatnya, Pak?"]],
		["@tabib", ["Sebentar, Bu. Sebentar... Ramuanku tidak ada yang cocok.", "Tapi ada cerita lama yang samar-samar kuingat..."]]
	],
	TRAD_HOME_EXAM_3: [
		["@tabib", ["Buah... buah apa namanya tadi... Buah yang..."]],
		["@hero", ["Buah Suwarga!"]],
		["", ["{nama} dan Pak Tabib saling menatap. Keduanya teringat dongeng lama itu pada saat yang sama."]],
		["@hero", ["Waktu kecil, Bunda sering bercerita tentang buah di ujung gua tua.", "Buah yang bisa melawan dingin dan racun."]],
		["@bunda", ["Itu hanya dongeng pengantar tidur, Nak..."]],
		["@tabib", ["Dongeng sering lahir dari kenyataan, Bu.", "Dan racun dingin ini jelas bukan kenyataan biasa. Hanya Buah Suwarga yang disebut mampu melawannya."]],
		["@hero", ["Di mana buah itu tumbuh, Pak?"]],
		["@tabib", ["Aku sendiri tidak tahu letaknya. Tapi orang tua di desa pesisir biasanya menyimpan cerita lama.", "Kita mulai dari Desa Kepiting."]],
		["@adek", ["...Kak... Adek tunggu di sini ya..."]],
		["@hero", ["Iya, Dek. Kakak janji pulang membawa obatnya."]]
	],
	TRAD_HOME_EXAM_TIP: "Tujuan: pergi ke Desa Kepiting bersama Pak Tabib.",

	# ===== v7: Bu Kepiting (Ibu Toko) =====
	TRAD_CRAB_SHOP_INFO: [
		["@hero", ["Permisi, Bu. Kami ingin bertanya soal Buah Suwarga."]],
		["@kepiting", ["Buah Suwarga? Sudah lama sekali tidak ada yang menyebut nama itu...", "Siapa yang sakit, Nak?"]],
		["@hero", ["Adikku, Bu. Racun dingin, kata Pak Tabib."]],
		["@kepiting", ["Kasihan sekali. Aku cuma tahu sepotong ceritanya:", "buah itu tumbuh jauh di utara, di tempat yang dijaga."]],
		["@kepiting", ["Tapi yang menyimpan cerita lengkapnya sahabatku, Kepala Desa Beruang.", "Sejak muda dia yang mencatat legenda dari utara."]],
		["@tabib", ["Kepala Desa Beruang... Di mana kami bisa menemuinya?"]],
		["@kepiting", ["Di Desa Beruang. Orangnya kaku kalau bertemu orang asing, jadi biar kuantar sendiri.", "Dia pasti mau bicara kalau aku yang datang."]],
		["@hero", ["Terima kasih banyak, Bu!"]],
		["@kepiting", ["Tidak usah sungkan. Ayo, jangan buang waktu."]]
	],
	TRAD_CRAB_ESCORT_AGAIN: [
		["@kepiting", ["Sudah siap, Nak? Ayo kuantar ke Desa Beruang."]]
	],

	# ===== v7: perjalanan ke Desa Beruang =====
	TRAD_JOURNEY_CAPTION: "Menuju Desa Beruang...",
	TRAD_JOURNEY_1: [
		["@kepiting", ["Dulu aku dan Beruang sering bertukar cerita lewat jalan ini."]],
		["@tabib", ["Jalan ini terasa lebih dingin dari biasanya..."]]
	],
	TRAD_JOURNEY_2: [
		["@hero", ["Kabut itu datang dari utara, kan, Bu?"]],
		["@kepiting", ["Betul. Sejak kabut turun, banyak warga yang sakit.", "Ayo, sedikit lagi sampai."]]
	],

	# ===== v7: Desa Beruang =====
	TRAD_BEAR_ARRIVE: [
		["@kepiting", ["Nah, sudah sampai. Toko Pak Beruang ada di sana, yang banyak guci madunya."]],
		["@tabib", ["Mari, kita temui beliau."]]
	],
	# v7.2: Bu Kepiting mengetuk pintu, Pak Beruang membukanya dan keluar menyambut
	TRAD_BEAR_DOOR: [
		["@beruang", ["Iya, sebentar! ...Oh? Bu Kepiting! Tumben sekali datang jauh-jauh kemari."]],
		["@kepiting", ["Aku membawa tamu, Beruang. Ada hal penting yang harus kau dengar.", "Kita bicara di dalam saja."]],
		["@beruang", ["Tentu, tentu. Mari masuk, mari masuk."]]
	],
	TRAD_BEAR_CHIEF: [
		["@kepiting", ["Nah, Beruang, ini {nama} dan Pak Tabib.", "Adik anak ini sakit racun dingin."]],
		["@beruang", ["Racun dingin... Jadi kabut itu mulai memakan korban."]],
		["@hero", ["Bapak Kepala Desa? Kami mencari Buah Suwarga."]],
		["@beruang", ["Ha ha, orang lebih mengenalku sebagai pak toko. Tapi benar, akulah Kepala Desa Beruang.", "Aku yang menyimpan catatan lama tentang utara."]],
		["@beruang", ["Buah Suwarga tumbuh di ujung Ancient Dungeon, di ujung jalan besar sebelah utara.", "Segel tua menjaganya... dan belakangan kudengar ada yang mengusiknya."]],
		["@tabib", ["Segel itu retak. Pantas kabutnya turun sampai ke desa."]],
		["@beruang", ["Di depan gerbang ada penjaga bernama Darkus. Dia akan membekalimu.", "Tapi dungeon itu bukan tempat sembarang orang."]],
		["@hero", ["Aku akan pergi. Aku sudah berjanji pada Adek."]],
		["@tabib", ["Aku ikut sampai jalan menuju dungeon. Lebih jauh dari itu, aku hanya jadi beban."]],
		["@kepiting", ["Hati-hati, Nak. Pulanglah dengan selamat."]]
	],
	TRAD_BEAR_CHIEF_LOCKED: [
		["@beruang", ["Satu lagi: gerbangnya tidak akan terbuka selama makhluk liar masih berkeliaran di desaku.", "Kalahkan mereka dulu."]]
	],
	TRAD_BEAR_CHIEF_OPEN: [
		["@beruang", ["Kulihat desaku sudah aman. Berarti gerbang dungeon sudah terbuka untukmu."]]
	],
	TRAD_BEAR_CHIEF_TIP: "Tujuan: menuju Ancient Dungeon, ke utara lewat jalan besar. Pak Tabib ikut sampai jalan masuk.",

	# ===== v7: Tabib menunggu di jalan masuk menuju dungeon =====
	TRAD_TABIB_ROAD: [
		["@tabib", ["Sampai di sini saja, {nama}. Jalan di depan itu menuju Ancient Dungeon."]],
		["@tabib", ["Aku tidak akan ikut masuk. Kakiku tidak sekuat dulu,", "dan hawa dingin di dalam sana bisa membekukan orang tua sepertiku."]],
		["@tabib", ["Aku menunggu di sini dan menyiapkan racikan untuk Adek begitu buahnya kau bawa."]],
		["@hero", ["Tunggu aku, Pak. Aku pasti kembali."]],
		["@tabib", ["Hati-hati. Dan jangan lupa makan, {nama}."]]
	],
	TRAD_TABIB_ROAD_TIP: "Pak Tabib menunggu di jalan masuk. Lanjutkan ke utara menuju Ancient Dungeon.",
	TRAD_TABIB_HAVE_JOIN: "Pak Tabib ikut pulang bersamamu. Suapkan Buah Suwarga pada Adek!",

	TRAD_WELL_DONE: [
		["@tukang", ["Sumur lancar, adikmu sehat.", "Bagus sekali, {nama}."]]
	],

	# Toko desa pohon (Pak Dagang)
	TRAD_TREEVILLAGE_SHOP: [
		["@dagang", ["Halo, {nama}.", "Cari apa hari ini?"]],
		["@hero", ["Halo, Pak.", "Aku butuh perlengkapan untuk perjalanan."]],
		["@dagang", ["Silakan lihat barang daganganku.", "Pilih yang kamu perlukan."]]
	],
	TRAD_TREEVILLAGE_SHOP_MED: [
		["@dagang", ["Halo, {nama}. Sumurnya sudah jadi, ya?", "Syukurlah, air bersih kembali mengalir."]],
		["@hero", ["Iya, Pak. Tapi adikku masih demam.", "Apa Bapak punya obat demam?"]],
		["@dagang", ["Wah, di sini tidak ada, Nak.", "Tapi ada tabib yang singgah di jalan desa. Temuilah dia.", "Silakan lihat dulu perlengkapanmu."]]
	],

	# Rumah penjaga permata
	TRAD_TREEVILLAGE_GEMHOUSE_START: [
		["Halo, {nama}.", "Ada yang bisa kubantu?"],
		["Halo, Pak.", "Aku butuh permata untuk membeli pedang dan ramuan", "agar selamat mencari bahan perbaikan sumur."],
		["Ada bintang Gormon yang terkubur di desa kita.", "Bawa padaku, kutukar satu permata untuk tiap bintang.", "Tertarik?"],
		["Ya, aku tertarik. Tapi bagaimana cara menemukannya?"],
		["Aku akan memberimu peta dan sekop.", "Galilah di tempat yang ditandai peta."],
		["Terima kasih untuk sekop dan petanya."]
	],
	TRAD_TREEVILLAGE_GEMHOUSE_PENDING: [
		["Halo, {nama}.", "Sudahkah kamu menemukan semua bintangnya?"],
		["Belum, Pak.", "Masih ada beberapa bintang yang harus kucari."],
		["Sudah, Pak.", "Aku menemukan semuanya.", "Ini dia!"],
		["Terima kasih atas bintang-bintang Gormon itu.", "Ini 10 permata untukmu."]
	],
	TRAD_TREEVILLAGE_GEMHOUSE_END: [
		["Halo, {nama}.", "Maaf, aku sudah tidak punya tugas untukmu.", "Semoga adikmu cepat sembuh. ;)"]
	],

	# ===================== DESA KEPITING =====================
	TRAD_CRABVILLAGE_WELL: [
		["@anak", ["Halo, orang asing!"]],
		["@hero", ["Halo! Aku butuh paku", "untuk memperbaiki sumur desaku."]],
		["@anak", ["Kamu datang ke tempat yang tepat!", "Menangkan tantangan di desa ini untuk dapat permata.", "Tukarkan permatanya dengan paku di toko."]],
		["@anak", ["Tapi hati-hati, ada monster pantai berkeliaran.", "Kalahkan mereka dan warga akan berterima kasih!"]]
	],
	TRAD_CRABVILLAGE_MED: [
		["@anak", ["Kamu yang memperbaiki sumur di desa pohon, kan? Kabarnya sudah sampai ke sini!"]],
		["@hero", ["Iya. Adikku masih sakit, Dik."]],
		["@anak", ["Semoga Adikmu lekas sembuh, Kak!", "Kalau ada yang mau ditanyakan, Ibu Toko banyak tahu cerita lama."]]
	],
	TRAD_CRAB_GUIDE_1: [
		["@anak", ["Kak {nama}! Wah, ada Pak Tabib juga. Ada apa, Kak?"]],
		["@hero", ["Adikku sakit parah, Dik. Kata Pak Tabib, cuma Buah Suwarga yang bisa menyembuhkannya.", "Kamu pernah dengar?"]],
		["@anak", ["Buah Suwarga...? Belum pernah, Kak."]],
		["@tabib", ["Itu legenda lama, Nak. Mungkin orang yang lebih tua pernah mendengarnya."]],
		["@anak", ["Kalau begitu, Ibu Toko pasti tahu! Beliau hafal banyak cerita zaman dulu.", "Ayo, kuantar ke tokonya!"]]
	],
	TRAD_CRAB_GUIDE_2: [
		["@anak", ["Nah, ini tokonya! Ayo masuk, Kak. Biar kuantar sampai ke Ibu Toko."]],
		["@hero", ["Terima kasih, Dik. Ayo masuk bersama."]]
	],
	# v7.2: di dalam toko, Anak Desa memperkenalkan tamu lalu pamit main
	TRAD_CRAB_SHOP_INTRO: [
		["@anak", ["Ibu Toko! Ini Kak {nama} dan Pak Tabib dari desa pohon.", "Mereka mau bertanya soal sesuatu yang penting."]],
		["@kepiting", ["Oh, tamu jauh rupanya. Terima kasih sudah mengantar mereka, Nak."]],
		["@anak", ["Sama-sama, Bu! Tugasku sudah selesai.", "Kak, aku main dulu ya! Semoga Ibu Toko tahu soal buahnya!"]],
		["@hero", ["Iya, Dik. Sekali lagi terima kasih!"]]
	],
	TRAD_CRAB_GUIDE_REMIND: [
		["@anak", ["Ibu Toko ada di dalam tokonya, Kak. Masuk saja!"]]
	],
	TRAD_CRABVILLAGE_AFTER: [
		["@anak", ["Hati-hati di jalan, Kak! Semoga Buah Suwarga cepat ketemu."]]
	],
	TRAD_CRABVILLAGE_SHOP: ["Selamat datang!", "Pilihlah barang yang kamu perlukan."],
	TRAD_CRABVILLAGE_SHOP_MED: ["Wah, tamu dari desa pohon!", "Kudengar adikmu sakit. Semoga cepat sembuh!", "Silakan lihat-lihat dulu daganganku."],
	TRAD_CRABVILLAGE_GAME1_ALREADYWON: [
		"Halo lagi,", "Maaf, kamu sudah pernah menang..."
	],
	TRAD_CRABVILLAGE_GAME1_START: [
		"Halo, untuk memenangkan permainan ini,", "kamu harus menyeberangkan", "kepiting, rumput laut, dan ubur-ubur.", "Kamu hanya boleh membawa satu sekaligus.", "Hati-hati jika meninggalkan mereka berdua saja:", "kepiting akan memakan ubur-ubur,", "dan ubur-ubur akan memakan rumput laut."
	],
	TRAD_CRABVILLAGE_GAME1_WIN: [
		"Selamat, kamu memenangkan permainan ini!", "Ini hadiah 2 permata untukmu."
	],

	# ===================== DESA BERUANG =====================
	TRAD_BEARVILLAGE_SHOP: ["Halo, sahabat!", "Madu hutan dan timba kami yang terbaik.", "Silakan pilih."],
	TRAD_BEARVILLAGE_SHOP_MED: ["Halo lagi! Kudengar sumurmu sudah pulih.", "Buah Suwarga ada di ujung Ancient Dungeon, jauh di utara.", "Hati-hati, Nak. Silakan lihat dulu daganganku."],
	TRAD_BEARVILLAGE_BEEPLATFORM: [],
	TRAD_BEARVILLAGE_BEEPLATFORM_START: [
		"Halo, bisakah kamu membantuku mengambil madu?",
		"Sarang lebahnya ada di ujung kanan. Aku tunggu di sini, di kiri.",
		"Cara bermain: gerak dengan panah kiri / kanan,", "lompat dengan panah atas atau SPASI.",
		"Di sarang, sentuh ember madu untuk mengambilnya,", "lalu bawa kembali dan sentuh aku untuk menyerahkannya.",
		"Antar 3 ember madu. Hati-hati jangan jatuh ke bawah!"
	],
	TRAD_BEARVILLAGE_BEEPLATFORM_WIN: [
		"Bagus sekali!", "Terima kasih banyak.", "Ini 4 permata sebagai tanda terima kasih."
	],
	TRAD_BEARVILLAGE_BEVILROOM_START: [
		"Halo, bisakah kamu membantuku?", "Lebah-lebah jahat (BeVil) menyerbu rumahku.",
		"Cara bermain: gerak dengan panah / WASD,", "dekati lebah, lalu tekan SPASI untuk memukulnya.",
		"Pukul SEMUA lebah sampai habis untuk menang.", "Awas, tiap sengatan mengurangi HP-mu!"
	],
	# hadiah tambahan setelah membantu Peternak Lebah dua kali (usir lebah + antar madu)
	TRAD_BEE_BONUS: [
		"Kamu sudah membantuku dua kali,", "jadi ini hadiah tambahan:", "satu Madu Hutan terbaik dari sarangku!"
	],
	TRAD_BEE_BONUS_NOTIF: "Mendapat Madu Hutan dari Peternak Lebah!",
	TRAD_BEARVILLAGE_BEVILROOM_WIN: [
		"Bagus sekali!", "Terima kasih banyak atas bantuanmu!", "Sebagai tanda terima kasih, ini 4 permata."
	]
}

# Token pembicara yang dipakai di dalam data dialog (lihat addDialogByKey).
var SPEAKER_KEYS = {
	"@bunda": TRAD_WORD_GORDONMOM,
	"@adek": TRAD_WORD_ADEK,
	"@tukang": TRAD_WORD_ARTISAN,
	"@dagang": TRAD_WORD_TREESELLER,
	"@permata": TRAD_WORD_GEMKEEPER,
	"@anak": TRAD_WORD_CRABKID,
	"@kepiting": TRAD_WORD_CRABSELLER,
	"@beruang": TRAD_WORD_BEARSELLER,
	"@vera": TRAD_WORD_VERA,
	"@darkus": TRAD_WORD_DARKUS,
	"@tabib": TRAD_WORD_TABIB,
	"@barong": TRAD_WORD_BARONG,
	"@bandit1": TRAD_WORD_BANDIT1,
	"@bandit2": TRAD_WORD_BANDIT2,
}

# potret yang ditampilkan di kotak dialog untuk pembicara tertentu
const SPEAKER_PORTRAITS = {
	"@vera": "res://common/characters/vera/vera-portrait.png",
	"@darkus": "res://screens/ancient-dungeon/darkus/portrait.png",
	"@barong": "res://screens/ancient-dungeon/shop/barong-portrait.png"
}

func getSpeakerName(token_):
	if token_ == "@hero":
		return getHeroName()
	if SPEAKER_KEYS.has(token_):
		return getTraductionById(SPEAKER_KEYS[token_])
	return token_

# Mengisi simpleDialog dengan dialog berformat [[pembicara,[baris...]], ...]
func addDialogByKey(dialog_, key_):
	dialog_.multiDialogList = []
	dialog_.currentDiscussionPage = 0
	dialog_.currentDiscussionLine = 0
	for page in getTraductionById(key_):
		dialog_.addDiscussion(getSpeakerName(page[0]), page[1], SPEAKER_PORTRAITS.get(page[0],""))

# ---- tahap cerita (tersimpan di file save lewat GlobalScenes) ----
const STAGE_WELL = 0      # sumur rusak: kumpulkan paku, madu hutan, timba
const STAGE_MEDICINE = 1  # sumur pulih: temui Pak Tabib, cari Buah Suwarga di Ancient Dungeon
const STAGE_DONE = 2      # adek sudah makan Buah Suwarga (tamat)

# obat adek = Buah Suwarga (Obat Demam lama tetap diterima agar save lama tidak macet)
func hasCure():
	return GlobalPlayer.hasItem(GlobalItems.ID.HEAVEN_FRUIT) or GlobalPlayer.hasItem(GlobalItems.ID.MEDICINE)

func consumeCure():
	if GlobalPlayer.hasItem(GlobalItems.ID.HEAVEN_FRUIT):
		GlobalPlayer.removeItem(GlobalItems.ID.HEAVEN_FRUIT)
	else:
		GlobalPlayer.removeItem(GlobalItems.ID.MEDICINE)

func getStoryStage():
	return int(GlobalScenes.getParamForSceneOr("story", "stage", STAGE_WELL))

func setStoryStage(stage_):
	GlobalScenes.saveParamForScene("story", "stage", stage_)

# ---- v7: perjalanan bersama Pak Tabib (tersimpan di save lewat GlobalScenes, param "tq") ----
const TQ_NONE = 0      # Tabib masih berdiri di jalan desa pohon
const TQ_JOINED = 1    # Tabib ikut Ranbyus; antar dia ke rumah (adegan periksa Adek)
const TQ_HOME_DONE = 2 # Adek sudah diperiksa; pergi ke Desa Kepiting (Anak Desa -> Bu Kepiting)
const TQ_GUIDED = 3    # Bu Kepiting mengantar ke Desa Beruang (Kepala Desa = Pak Beruang)
const TQ_CHIEF = 4     # Kepala Desa memberi tahu: Buah Suwarga ada di Ancient Dungeon
const TQ_WAIT = 5      # Tabib menunggu di jalan masuk menuju dungeon (tidak ikut masuk)
const TQ_RETURN = 6    # Ranbyus membawa Buah Suwarga; Tabib ikut pulang

# save lama (sebelum v7) tidak punya param ini: kalau Buah Suwarga sudah dipegang, anggap Tabib menunggu
func getTabibQuest():
	var v = int(GlobalScenes.getParamForSceneOr("story", "tq", -1))
	if v < 0:
		return TQ_WAIT if hasCure() else TQ_NONE
	return v

func setTabibQuest(v_):
	GlobalScenes.saveParamForScene("story", "tq", v_)

# Tabib mengikuti pemain (non-petarung) pada tahap ini
func isTabibFollowing():
	if getStoryStage() != STAGE_MEDICINE:
		return false
	var q = getTabibQuest()
	return (q >= TQ_JOINED and q <= TQ_CHIEF) or q == TQ_RETURN

# Vera: 0 belum bertemu, 1 menemani pemain, 2 sudah berpisah di desa kedua (kepiting / beruang), tidak muncul lagi
const VERA_NONE = 0
const VERA_WITH = 1
const VERA_GONE = 2

func getVeraState():
	return int(GlobalScenes.getParamForSceneOr("story", "vera", VERA_NONE))

func setVeraState(state_):
	GlobalScenes.saveParamForScene("story", "vera", state_)

func isVeraWithPlayer():
	return getVeraState() == VERA_WITH

# gerbang Ancient Dungeon terbuka setelah musuh desa beruang dikalahkan
func isBearVillageCleared():
	return int(GlobalScenes.getParamForSceneOr("story", "bear_cleared", 0)) == 1

# ---- hadiah Peternak Lebah ----
# Dua bantuan: usir lebah di rumahnya (bv_bees_done) dan antar 3 ember madu (bv_honey_done).
# Setiap bantuan = 4 permata; setelah KEDUANYA selesai ada bonus satu Madu Hutan (sekali saja).
func isBeeBonusGiven():
	return int(GlobalScenes.getParamForSceneOr("story", "bv_bonus_given", 0)) == 1

# true kalau bantuan lain sudah selesai sehingga bantuan yang sedang dikerjakan akan memberi bonus madu
func willBeeBonusFollow(otherFlag_):
	return int(GlobalScenes.getParamForSceneOr("story", otherFlag_, 0)) == 1 and !isBeeBonusGiven()

# dipanggil setelah flag bantuan disimpan; memberi Madu Hutan kalau kedua bantuan sudah selesai
func giveBeeBonusIfReady():
	var both = int(GlobalScenes.getParamForSceneOr("story", "bv_bees_done", 0)) == 1 and int(GlobalScenes.getParamForSceneOr("story", "bv_honey_done", 0)) == 1
	if both and !isBeeBonusGiven():
		GlobalScenes.saveParamForScene("story", "bv_bonus_given", 1)
		GlobalPlayer.addItemEvenIfExist(GlobalItems.ID.HONEY)
		return true
	return false

# 0 = belum terjadi, 1 = bandit sudah diusir Vera
func isBanditEventDone():
	return int(GlobalScenes.getParamForSceneOr("story", "bandit", 0)) == 1

func setBanditEventDone():
	GlobalScenes.saveParamForScene("story", "bandit", 1)

# penghitung sederhana (berapa kali NPC sudah diajak bicara), ikut tersimpan
func getTalkCount(npc_):
	return int(GlobalScenes.getParamForSceneOr("talk", npc_, 0))

func addTalkCount(npc_):
	GlobalScenes.saveParamForScene("talk", npc_, getTalkCount(npc_) + 1)

# Nama tokoh utama (kakak) = nama yang diketik pemain saat mulai permainan.
func getHeroName():
	var n=GlobalPlayer.getNickname()
	if n==null or str(n).strip_edges()=="":
		return "Ranbyus"
	return str(n)

# Mengganti {nama} di dalam teks dialog (termasuk array bersarang).
func _fillPlaceholders(v_):
	if v_ is String:
		return v_.replace("{nama}",getHeroName())
	if v_ is Array:
		var out=[]
		for x in v_:
			out.append(_fillPlaceholders(x))
		return out
	return v_

var traductionsMS = {
	TRAD_BUTTON_NEWGAME: "Permainan Baharu", TRAD_BUTTON_LOADGAME: "Muat Permainan",
	TRAD_BUTTON_CREATE: "Cipta", TRAD_LABEL_NOM: "Nama", TRAD_LABEL_PSEUDO: "Nama Panggilan",
	TRAD_LABEL_PARTIES: "Permainan", TRAD_LABEL_VOTREPSEUDO: "Masukkan nama pemain",
	TRAD_BUTTON_RETOUR: "KEMBALI", TRAD_BUTTON_EFFACER: "PADAM", TRAD_BUTTON_VALIDER: "SAHKAN",
	TRAD_LABEL_RETOURAUMENU: "KEMBALI KE MENU", TRAD_UI_PAUSE: "Jeda", TRAD_UI_RESUME: "Sambung",
	TRAD_UI_INVENTORY: "Inventori", TRAD_UI_SAVE: "Simpan", TRAD_UI_SETTINGS: "Tetapan",
	TRAD_UI_QUIT: "Keluar", TRAD_UI_QUIT_CONFIRM: "Keluar daripada permainan?",
	TRAD_UI_QUIT_WARNING: "Jangan lupa simpan!", TRAD_UI_YES: "Ya", TRAD_UI_NO: "Tidak",
	TRAD_UI_SAVED: "Permainan berjaya disimpan", TRAD_UI_TOUCH: "Kawalan sentuh",
	TRAD_UI_DIALOG_ANIMATION: "Animasi teks", TRAD_UI_CLOSE: "Tutup", TRAD_UI_MENU: "Menu",
	TRAD_UI_SHOP: "Kedai", TRAD_UI_EQUIP: "Lengkapkan", TRAD_UI_DISPLAY: "Papar",
	TRAD_UI_USE: "Guna", TRAD_UI_BUY: "Beli", TRAD_UI_OWNED: "Sudah dimiliki",
	TRAD_FIGHT_ATTACK: "Serang", TRAD_FIGHT_POTION: "Ramuan x%d", TRAD_FIGHT_FLEE: "Lari",
	TRAD_FIGHT_BACK: "Kembali", TRAD_FIGHT_PUNCH: "Tumbukan", TRAD_FIGHT_SPIDER: "Labah-labah",
	TRAD_FIGHT_APPEAR: "Seekor labah-labah muncul!", TRAD_FIGHT_CHOOSE: "Apakah tindakan %s?",
	TRAD_FIGHT_PLAYER_ATTACK: "%s menggunakan %s!", TRAD_FIGHT_CRITICAL: "Serangan kritikal!",
	TRAD_FIGHT_ENEMY_ATTACK: "Labah-labah menyerang!", TRAD_FIGHT_ENEMY_MISS: "Labah-labah tersasar!",
	TRAD_FIGHT_MISS: "Tersasar", TRAD_FIGHT_POTION_USED: "%s meminum ramuan.",
	TRAD_FIGHT_VICTORY: "Menang! +%d XP  +%d permata", TRAD_FIGHT_DEFEAT: "%s keletihan lalu berundur..."
}

func getTraductionById(id_):
	if lang == MS:
		if traductionsMS.has(id_):
			return _fillPlaceholders(traductionsMS[id_])
		if traductionsList.has(id_) and traductionsList[id_].has(EN):
			return traductionsList[id_][EN]
		if traductionsID.has(id_):
			return _fillPlaceholders(traductionsID[id_])
		return str(id_)
	if lang == ID:
		if traductionsID.has(id_):
			return _fillPlaceholders(traductionsID[id_])
		# Fallback aman jika ada kunci terjemahan yang belum tersedia.
		if traductionsList.has(id_):
			if traductionsList[id_].has(EN):
				return traductionsList[id_][EN]
		push_warning("Terjemahan tidak ditemukan: " + str(id_))
		return str(id_)
	if traductionsList.has(id_) and traductionsList[id_].has(lang):
		return traductionsList[id_][lang]
	if traductionsID.has(id_):
		return _fillPlaceholders(traductionsID[id_])
	push_warning("Terjemahan tidak ditemukan untuk bahasa " + str(lang) + ": " + str(id_))
	return str(id_)

func getSceneToLoad():
	return _sceneToLoad

func create(nickname_,class_="novice"):
	var scene='screens/tree-village/gordon-home.tscn'
	_filename=getNewFilename(nickname_)
	# permainan baru mulai bersih (item & penanda cerita dari permainan sebelumnya dibuang)
	GlobalScenes.scenesData={}
	GlobalPlayer.resetForNewGame()
	GlobalPlayer.setNickname(nickname_)
	GlobalPlayer.setPlayerClass(class_)
	GlobalPlayer.savePosition(Vector2(48,75))
	save(scene)
	loadFile(_filename)

func saveWithPosition(scene_,position_):
	GlobalPlayer.savePosition(position_)
	save(scene_)

func save(scene_):
	print("save :"+_filename)
	var gameData=getDataToSave(scene_)
	var saveFile = FileAccess.open("user://"+_filename, FileAccess.WRITE)
	if saveFile == null:
		push_error("Erreur lors de l'ecriture de la sauvegarde user://"+_filename)
		return
	saveFile.store_line(JSON.stringify(gameData))
	saveFile.close()

func getNewFilename(nickname_):
	var filePattern=nickname_+"_"
	var newId=1
	var saveList=getList()
	for saveFile in saveList:
		if(saveFile.substr(0,nickname_.length())==nickname_):
			newId+=1
	return filePattern+str(newId)+".save"

func getFilteredSaveList(fileList_):
	var filterSaveList=[]
	for file in fileList_:
		if file.ends_with('.save'):
			filterSaveList.append(file)
	return filterSaveList	
	

func getList():
	var path="user://"
	var fileList=[]
	var dir = DirAccess.open(path)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if(file_name.substr(0,1)!="."):
				fileList.append(file_name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		push_error("Erreur lors de l'access au repertoire user://")
	
	return getFilteredSaveList(fileList)

func convertObjectToSave(object_,fieldList_):
	var saveData={}
	for field in fieldList_:
		saveData[field]=object_.get(field)
	return saveData


func gotoMenu():
	SceneTransition.change_scene("res://screens/game/menu.tscn")


func getDataToSave(scene_):
	var gameData= {
		"scene" : scene_,
		"player":GlobalPlayer.convertToSave(),
		"scenes":GlobalScenes.convertToSave(),
	}
	return gameData
	
		
func loadFile(file_):
	_filename=file_
	var saveFilename="user://"+file_
	if not FileAccess.file_exists(saveFilename):
		return # Error! We don't have a save to load.
	
	var saveFile = FileAccess.open(saveFilename, FileAccess.READ)
	while saveFile.get_position() < saveFile.get_length():
		# Get the saved dictionary from the next line in the save file
		var saveData = JSON.parse_string(saveFile.get_line())
		if not saveData is Dictionary:
			continue
		for field in saveData.keys():
			if field=="scene":
				_sceneToLoad=saveData[field]
			elif field=="player":
				GlobalPlayer.loadFromSave(saveData[field])
			elif field=="scenes":
				GlobalScenes.loadFromSave(saveData[field])
		
	saveFile.close()


	
