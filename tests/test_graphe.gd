## Le graphe est de la presentation, mais sa geometrie est du calcul : le choix
## des graduations et le cadrage automatique se verifient sans rien afficher.
##
## Le dessin lui-meme ne s'execute pas en headless — ce test couvre ce qui peut
## l'etre, c'est-a-dire tout ce qui peut etre faux sans qu'on le voie.
extends "res://tests/support/test_base.gd"

const SCENE: String = "res://src/presentation/composants/graphe/graphe.tscn"


func _graphe() -> Graphe:
	return (load(SCENE) as PackedScene).instantiate() as Graphe


func test_scene_instanciable() -> void:
	var graphe: Graphe = _graphe()
	verifier(graphe != null, "graphe.tscn s'instancie")
	if graphe != null:
		graphe.free()


func test_releves_accumules() -> void:
	var graphe: Graphe = _graphe()
	graphe.ajouter_releve(Vector2(70.0, 50.0))
	graphe.ajouter_releve(Vector2(151.0, 500.0))
	var plage: Vector2 = graphe.plage_relevee()
	verifier_proche(plage.x, 70.0, "borne basse des releves")
	verifier_proche(plage.y, 151.0, "borne haute des releves")
	graphe.effacer()
	verifier_egal(graphe.plage_relevee(), Vector2.ZERO, "effacer vide le graphe")
	graphe.free()


func test_pas_de_graduation_lisible() -> void:
	var graphe: Graphe = _graphe()
	# Un pas de graduation doit toujours tomber sur 1, 2 ou 5 fois une puissance
	# de dix, sinon les etiquettes deviennent illisibles.
	for etendue: float in [1.0, 7.0, 45.0, 180.0, 950.0, 0.03]:
		var pas: float = graphe.call("_pas_lisible", etendue)
		var mantisse: float = pas / pow(10.0, floorf(log(pas) / log(10.0)))
		verifier(
			absf(mantisse - 1.0) < 1e-6 or absf(mantisse - 2.0) < 1e-6 or absf(mantisse - 5.0) < 1e-6,
			"pas lisible pour une etendue de %s (obtenu %s)" % [etendue, pas]
		)
		verifier(pas > 0.0 and pas <= etendue, "le pas tient dans l'etendue %s" % etendue)
	graphe.free()


func test_serie_plate_ne_divise_pas_par_zero() -> void:
	# Un seul releve, ou plusieurs alignes : l'etendue est nulle et la projection
	# diviserait par zero si le cadrage ne s'en occupait pas.
	var graphe: Graphe = _graphe()
	graphe.ajouter_releve(Vector2(70.0, 50.0))
	var bornes: Rect2 = graphe.call("_bornes")
	verifier(bornes.size.x > 0.0, "le cadrage a une largeur")
	verifier(bornes.size.y > 0.0, "le cadrage a une hauteur")
	graphe.free()


func test_cadrage_impose_prime() -> void:
	var graphe: Graphe = _graphe()
	graphe.ajouter_releve(Vector2(70.0, 50.0))
	graphe.imposer_cadrage(0.0, 300.0, 0.0, 1000.0)
	var bornes: Rect2 = graphe.call("_bornes")
	verifier_proche(bornes.position.x, 0.0, "borne gauche imposee")
	verifier_proche(bornes.end.x, 300.0, "borne droite imposee")
	verifier_proche(bornes.end.y, 1000.0, "borne haute imposee")
	graphe.free()


func test_projection_respecte_le_sens_de_l_ecran() -> void:
	var graphe: Graphe = _graphe()
	graphe.size = Vector2(400.0, 300.0)
	var cadre: Rect2 = graphe.call("_cadre")
	var bornes: Rect2 = Rect2(0.0, 0.0, 100.0, 100.0)

	var bas: Vector2 = graphe.call("_vers_pixel", Vector2(0.0, 0.0), cadre, bornes)
	var haut: Vector2 = graphe.call("_vers_pixel", Vector2(0.0, 100.0), cadre, bornes)
	# Une ordonnee qui monte doit descendre en pixels.
	verifier(haut.y < bas.y, "l'axe des ordonnees est retourne")
	verifier_proche(bas.y, cadre.end.y, "le minimum touche le bas du cadre", 1e-3)

	var droite: Vector2 = graphe.call("_vers_pixel", Vector2(100.0, 0.0), cadre, bornes)
	verifier(droite.x > bas.x, "l'axe des abscisses va vers la droite")
	graphe.free()


func test_etiquettes_sans_decimales_parasites() -> void:
	var graphe: Graphe = _graphe()
	verifier_egal(graphe.call("_formater", 250.0, 50.0), "250", "pas entier, etiquette entiere")
	verifier_egal(graphe.call("_formater", 0.5, 0.1), "0.5", "pas decimal, une decimale")
	verifier_egal(graphe.call("_formater", -0.0, 1.0), "0", "pas de zero negatif")
	graphe.free()
