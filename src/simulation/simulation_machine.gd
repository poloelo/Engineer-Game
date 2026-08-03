## La physique d'une machine. Pure, deterministe, sans aucune dependance a
## l'affichage.
##
## Cette classe est un [RefCounted] et n'herite d'aucun [Node] : elle se charge,
## se manipule et se verifie sans ouvrir la moindre scene. C'est le critere qui
## valide toute l'architecture, et c'est aussi ce qui rend la suite de tests
## headless possible.
##
## Elle ne connait aucune machine en particulier : tout vient de la [MachineDef]
## qu'on lui passe. Une machine nouvelle n'ajoute pas une ligne ici.
class_name SimulationMachine
extends RefCounted

## Un releve du joueur vient d'etre pris, en (lecture, valeur cible).
signal mesure_effectuee(point: Vector2)

var machine: MachineDef = null

var _generateur: GenerateurMesure = null
## Resolutions effectives des primitives, injectees par l'atelier. La simulation
## ne lit aucun etat global : ce qu'elle sait de la progression, on le lui donne.
var _precisions: Dictionary = {}
var _releves: Array[Vector2] = []


func _init(definition: MachineDef, graine: int = 0, precisions: Dictionary = {}) -> void:
	machine = definition
	_generateur = GenerateurMesure.new(graine)
	_precisions = precisions.duplicate()


## Les releves deja pris, dans l'ordre. Le graphe s'en sert pour se reconstruire.
func releves() -> Array[Vector2]:
	return _releves.duplicate()


## Construit l'etat cache correspondant a un etalon impose par le joueur.
func etat_pour_etalon(valeur: float) -> Dictionary:
	if machine == null or machine.loi_cachee == null:
		return {}
	if machine.loi_cachee.grandeurs_entree.is_empty():
		return {}
	return {String(machine.loi_cachee.grandeurs_entree[0]): valeur}


## Le joueur impose un etat a la machine et releve ses instruments.
## Rend le point (lecture, valeur cible) tel qu'il le voit, imprecisions comprises.
func effectuer_mesure(etat: Dictionary) -> Vector2:
	if machine == null:
		return Vector2.ZERO

	var complet: Dictionary = _etat_complet(etat)
	var lue: float = _valeur(complet, machine.grandeur_lue)
	var produite: float = _valeur(complet, machine.grandeur_produite)

	var point: Vector2 = Vector2(
		_generateur.mesurer(lue, machine.primitive_lue, _pas(machine.primitive_lue)),
		_generateur.mesurer(produite, machine.primitive_produite, _pas(machine.primitive_produite))
	)
	_releves.append(point)
	mesure_effectuee.emit(point)
	return point


## Trace continu de la machine reelle, sur une plage de lectures.
func courbe_reelle(x_min: float, x_max: float, points: int = 64) -> PackedVector2Array:
	var courbe: PackedVector2Array = PackedVector2Array()
	if machine == null or machine.loi_cachee == null or points < 2 or x_max <= x_min:
		return courbe

	var loi: Loi = machine.loi_cachee
	# La lecture est en abscisse ; selon la machine elle est soit l'entree de la
	# loi cachee, soit sa sortie. Dans le second cas il faut remonter la loi.
	var lue_est_sortie: bool = loi.grandeurs_sortie.has(machine.grandeur_lue)
	if lue_est_sortie and not loi.est_inversible():
		return courbe

	for i: int in points:
		var x: float = lerpf(x_min, x_max, float(i) / float(points - 1))
		var complet: Dictionary
		if lue_est_sortie:
			var entree: float = loi.inverser(_avec_parametres({String(machine.grandeur_lue): x}))
			complet = _etat_complet({String(loi.grandeurs_entree[0]): entree})
		else:
			complet = _etat_complet({String(machine.grandeur_lue): x})
		var y: float = _valeur(complet, machine.grandeur_produite)
		if not is_nan(y):
			courbe.append(Vector2(x, y))
	return courbe


## Complete un etat cache par tout ce que la loi de la machine permet d'en
## deduire. Le sens n'a pas a etre code : que la grandeur lue soit l'entree ou la
## sortie de la loi, l'etat complet contient les deux.
func _etat_complet(etat: Dictionary) -> Dictionary:
	var complet: Dictionary = _avec_parametres(etat)
	var loi: Loi = machine.loi_cachee
	if loi == null or loi.grandeurs_sortie.is_empty():
		return complet

	var sortie: String = String(loi.grandeurs_sortie[0])
	var entree: String = String(loi.grandeurs_entree[0]) if not loi.grandeurs_entree.is_empty() else ""

	if not complet.has(sortie) and complet.has(entree):
		complet[sortie] = loi.evaluer(complet)
	elif not complet.has(entree) and complet.has(sortie) and loi.est_inversible():
		complet[entree] = loi.inverser(complet)
	return complet


func _avec_parametres(etat: Dictionary) -> Dictionary:
	var complet: Dictionary = machine.parametres_caches.duplicate()
	complet.merge(etat, true)
	return complet


func _valeur(etat: Dictionary, grandeur: StringName) -> float:
	var cle: String = String(grandeur)
	return float(etat[cle]) if etat.has(cle) else EvaluateurExpression.ECHEC


func _pas(instrument: Primitive) -> float:
	if instrument == null:
		return -1.0
	return float(_precisions.get(instrument.id, -1.0))
