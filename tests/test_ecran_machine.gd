## Verifie le cablage complet de l'ecran, du bouton au verdict du banc.
##
## Ce test monte reellement la scene dans l'arbre et fait le parcours du joueur :
## relever des points, remplir la fiche, envoyer au banc. Le dessin lui-meme ne
## s'execute pas en headless — c'est le cablage qui est verifie ici, pas le rendu.
extends "res://tests/support/test_base.gd"

const SCENE: String = "res://src/presentation/machines/peson/peson.tscn"


func _monter() -> EcranMachine:
	var ecran: EcranMachine = (load(SCENE) as PackedScene).instantiate() as EcranMachine
	var arbre: SceneTree = Engine.get_main_loop() as SceneTree
	arbre.root.add_child(ecran)
	return ecran


func _demonter(ecran: EcranMachine) -> void:
	(Engine.get_main_loop() as SceneTree).root.remove_child(ecran)
	ecran.free()


func _remplir(ecran: EcranMachine, valeurs: Dictionary) -> void:
	var fiche: FicheTechnique = ecran.get("_fiche")
	var champs: Dictionary = fiche.get("_champs")
	for nom: String in valeurs:
		champs[nom].text = String.num(float(valeurs[nom]), 6)


func test_scene_montee_et_cablee() -> void:
	var ecran: EcranMachine = _monter()
	verifier(ecran.get("_simulation") != null, "la simulation est construite")
	verifier(ecran.get("_graphe") != null, "le graphe est en place")
	verifier(ecran.get("_fiche") != null, "la fiche technique est en place")
	verifier(ecran.get("_banc") != null, "le banc est en place")
	verifier(ecran.get("_plan") != null, "le plan du peson est en place")
	_demonter(ecran)


func test_une_mesure_depose_un_point_sur_le_graphe() -> void:
	var ecran: EcranMachine = _monter()
	var barre: BarrePrimitives = ecran.get("_barre")
	var graphe: Graphe = ecran.get("_graphe")

	barre.mesure_demandee.emit(50.0)
	var plage: Vector2 = graphe.plage_relevee()
	verifier_proche(plage.x, 70.0, "le releve arrive sur le graphe")

	barre.mesure_demandee.emit(500.0)
	verifier_proche(graphe.plage_relevee().y, 151.0, "un second point elargit la plage")
	_demonter(ecran)


func test_le_modele_se_trace_en_direct() -> void:
	var ecran: EcranMachine = _monter()
	var fiche: FicheTechnique = ecran.get("_fiche")
	var graphe: Graphe = ecran.get("_graphe")

	_remplir(ecran, {"a": 5.0})
	fiche.modele_modifie.emit(fiche.valeurs())
	verifier_egal(graphe.get("_modele").size(), 0, "une fiche incomplete ne trace rien")

	_remplir(ecran, {"a": 5.0, "b": -300.0})
	fiche.modele_modifie.emit(fiche.valeurs())
	verifier(graphe.get("_modele").size() > 1, "le modele complet se trace")
	_demonter(ecran)


func test_champ_vide_n_est_pas_un_zero() -> void:
	var ecran: EcranMachine = _monter()
	var fiche: FicheTechnique = ecran.get("_fiche")
	verifier(not fiche.est_complete(), "fiche vide au depart")
	_remplir(ecran, {"a": 5.5})
	verifier(not fiche.est_complete(), "un seul champ rempli ne suffit pas")
	verifier_egal(fiche.valeurs().size(), 1, "le champ vide est absent, pas a zero")
	_demonter(ecran)


func test_virgule_acceptee_comme_separateur() -> void:
	var ecran: EcranMachine = _monter()
	var fiche: FicheTechnique = ecran.get("_fiche")
	var champs: Dictionary = fiche.get("_champs")
	champs["a"].text = "5,556"
	champs["b"].text = "-341,3"
	verifier(fiche.est_complete(), "la fiche accepte la virgule decimale")
	verifier_proche(float(fiche.valeurs()["a"]), 5.556, "valeur lue", 1e-5)
	_demonter(ecran)


func test_parcours_complet_jusqu_au_verdict() -> void:
	var ecran: EcranMachine = _monter()
	var barre: BarrePrimitives = ecran.get("_barre")
	var fiche: FicheTechnique = ecran.get("_fiche")
	var graphe: Graphe = ecran.get("_graphe")
	var simulation: SimulationMachine = ecran.get("_simulation")

	# Relever les deux etalons extremes, calibrer, soumettre.
	barre.mesure_demandee.emit(5.0)
	barre.mesure_demandee.emit(500.0)
	var releves: Array[Vector2] = simulation.releves()
	var a: float = (releves[1].y - releves[0].y) / (releves[1].x - releves[0].x)
	var b: float = releves[0].y - a * releves[0].x

	var resultats: Array[ResultatBanc] = []
	simulation.specification_evaluee.connect(func(r: ResultatBanc) -> void: resultats.append(r))

	_remplir(ecran, {"a": a, "b": b})
	fiche.soumission_demandee.emit(fiche.valeurs())

	verifier_egal(resultats.size(), 1, "le banc a rendu un verdict")
	if resultats.is_empty():
		_demonter(ecran)
		return
	verifier_egal(resultats[0].etoiles, 3, "le parcours complet atteint trois etoiles")
	verifier(
		graphe.get("_reelle").size() > 1, "la machine reelle est revelee apres la soumission"
	)
	verifier_egal(simulation.matiere_restante(), 11, "une matiere consommee")
	_demonter(ecran)


func test_axes_nommes_depuis_le_catalogue() -> void:
	verifier_egal(Catalogue.libelle_axe(&"longueur"), "Longueur (mm)", "libelle d'axe")
	verifier_egal(Catalogue.unite(&"masse"), "g", "unite de la masse")
	verifier(Catalogue.grandeurs().size() == 14, "les quatorze grandeurs sont au catalogue")
	verifier(Catalogue.primitives().size() == 8, "les huit primitives sont au catalogue")
