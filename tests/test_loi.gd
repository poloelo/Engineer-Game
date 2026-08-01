## Verifie qu'une loi entierement declaree en donnee est evaluable et inversible.
##
## C'est le test qui valide le pari central de l'architecture : aucune ligne de
## GDScript n'est ecrite pour Hooke, tout vient de hooke.tres.
extends "res://tests/support/test_base.gd"

const HOOKE: String = "res://src/contenu/data/lois/hooke.tres"
const PESON: String = "res://src/contenu/data/lois/peson_ressort.tres"


func test_loi_chargee_depuis_donnee() -> void:
	var loi: Loi = load(HOOKE) as Loi
	verifier(loi != null, "hooke.tres se charge en Loi")
	if loi == null:
		return
	verifier_egal(loi.id, &"hooke", "id")
	verifier_egal(loi.forme, Forme.Type.LINEAIRE, "forme")
	verifier_egal(Forme.nom(loi.forme), "lineaire", "libelle de forme")
	verifier(loi.est_inversible(), "hooke est inversible")


func test_evaluation_directe() -> void:
	var loi: Loi = load(HOOKE) as Loi
	# l0 + force / k, avec l0 = 60 et k = 0.5
	verifier_proche(loi.evaluer({"force": 0.0}), 60.0, "a vide")
	verifier_proche(loi.evaluer({"force": 2.0}), 64.0, "sous 2 N")


func test_parametres_surchargeables_par_la_machine() -> void:
	var loi: Loi = load(HOOKE) as Loi
	verifier_proche(loi.evaluer({"force": 2.0, "k": 1.0}), 62.0, "raideur surchargee")
	verifier_proche(loi.evaluer({"force": 2.0}), 64.0, "surcharge non persistante")


func test_inversion() -> void:
	var loi: Loi = load(HOOKE) as Loi
	verifier_proche(loi.inverser({"longueur": 64.0}), 2.0, "inverse de Hooke")
	# Aller-retour sur une valeur quelconque : c'est ce qui prouve que les deux
	# formules declarees separement sont bien coherentes entre elles.
	var force: float = 3.7
	verifier_proche(
		loi.inverser({"longueur": loi.evaluer({"force": force})}), force, "aller-retour"
	)


func test_variable_manquante_est_une_erreur() -> void:
	var loi: Loi = load(HOOKE) as Loi
	# Pas de zero implicite : une entree absente doit echouer bruyamment.
	verifier_nan(loi.evaluer({}), "force absente")
	verifier(not loi.derniere_erreur().is_empty(), "l'erreur est expliquee")


func test_physique_cachee_du_peson() -> void:
	var loi: Loi = load(PESON) as Loi
	verifier(loi != null, "peson_ressort.tres se charge")
	if loi == null:
		return
	# Longueur a vide 60 mm, sensibilite 0,18 mm/g, crochet 8 g : le crochet
	# decale la droite, la relation est affine et non proportionnelle.
	verifier_proche(loi.evaluer({"masse": 0.0}), 61.44, "crochet seul", 1e-4)
	verifier_proche(loi.evaluer({"masse": 100.0}), 79.44, "sous 100 g", 1e-4)
	verifier_proche(loi.evaluer({"masse": 500.0}), 151.44, "sous 500 g", 1e-4)


func test_solution_attendue_du_peson() -> void:
	var loi: Loi = load(PESON) as Loi
	# La specification que le joueur doit trouver, masse = a * lecture + b,
	# n'est rien d'autre que l'inverse de la loi cachee mise sous forme affine.
	var a: float = 1.0 / 0.18
	var b: float = -(60.0 / 0.18) - 8.0
	verifier_proche(a, 5.5556, "coefficient a", 1e-3)
	verifier_proche(b, -341.3, "terme constant b", 0.1)
	for masse: float in [0.0, 250.0, 780.0]:
		var lecture: float = loi.evaluer({"masse": masse})
		verifier_proche(a * lecture + b, masse, "la spec redonne la masse", 1e-6)


func test_verification_structurelle() -> void:
	var loi: Loi = load(HOOKE) as Loi
	verifier_egal(loi.verifier(), [] as Array[String], "hooke est structurellement saine")

	var cassee: Loi = Loi.new()
	cassee.id = &"cassee"
	cassee.grandeurs_entree = [&"force"] as Array[StringName]
	cassee.grandeurs_sortie = [&"longueur"] as Array[StringName]
	cassee.outils_requis = [&"voir"] as Array[StringName]
	cassee.expression = "force * ("
	verifier(not cassee.verifier().is_empty(), "une formule illisible est signalee")
