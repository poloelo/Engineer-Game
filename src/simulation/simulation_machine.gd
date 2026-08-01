## Le moteur d'une machine. Pur, deterministe, sans aucune dependance a
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

## Le banc a rendu son verdict.
signal specification_evaluee(resultat: ResultatBanc)

## La piece est suffisamment bonne pour entrer a l'atelier.
signal piece_validee(piece: Piece)

## Le budget de matiere a change.
signal matiere_modifiee(restante: int)

var machine: MachineDef = null

var _generateur: GenerateurMesure = null
## Resolutions effectives des primitives, injectees par l'atelier. La simulation
## ne lit aucun etat global : ce qu'elle sait de la progression, on le lui donne.
var _precisions: Dictionary = {}
var _matiere: int = 0
var _releves: Array[Vector2] = []


func _init(definition: MachineDef, graine: int = 0, precisions: Dictionary = {}) -> void:
	machine = definition
	_generateur = GenerateurMesure.new(graine)
	_precisions = precisions.duplicate()
	_matiere = definition.matiere_initiale if definition != null else 0


func matiere_restante() -> int:
	return _matiere


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
	var emplacement: EmplacementPiece = _emplacement_principal()
	if emplacement == null:
		return Vector2.ZERO

	var complet: Dictionary = _etat_complet(etat)
	var lue: float = _valeur(complet, emplacement.grandeur_lue)
	var produite: float = _valeur(complet, emplacement.grandeur_produite)

	var point: Vector2 = Vector2(
		_generateur.mesurer(lue, machine.primitive_lue, _pas(machine.primitive_lue)),
		_generateur.mesurer(produite, machine.primitive_produite, _pas(machine.primitive_produite))
	)
	_releves.append(point)
	mesure_effectuee.emit(point)
	return point


## Eprouve le modele du joueur sur les cas caches.
##
## Le banc n'applique aucune imprecision d'instrument : il simule la machine
## equipee de la piece. Ce que le joueur combat, c'est la grossierete de ses
## propres mesures pendant la calibration, pas un banc capricieux.
func soumettre_specification(specification: Specification) -> ResultatBanc:
	var refus: ResultatBanc = _refus_eventuel(specification)
	if refus != null:
		specification_evaluee.emit(refus)
		return refus

	_matiere -= 1
	matiere_modifiee.emit(_matiere)

	var emplacement: EmplacementPiece = specification.emplacement
	var resultat: ResultatBanc = ResultatBanc.new()
	var somme: float = 0.0
	var pire: float = 0.0

	for cas: CasTest in machine.cas_test_caches:
		var complet: Dictionary = _etat_complet(cas.etat)
		var lecture: float = _valeur(complet, emplacement.grandeur_lue)
		var vraie: float = _valeur(complet, emplacement.grandeur_produite)
		var predite: float = specification.evaluer(_entrees_gabarit(emplacement, complet))

		if is_nan(lecture) or is_nan(vraie) or is_nan(predite):
			var message: String = specification.erreur()
			return _echouer(
				"le banc n'a pas pu evaluer le modele%s" % ("" if message.is_empty() else " — " + message)
			)

		var ecart: float = _ecart_relatif(predite, vraie)
		somme += ecart
		pire = maxf(pire, ecart)

		resultat.ecarts.append(ecart)
		resultat.points_reels.append(Vector2(lecture, vraie))
		resultat.points_predits.append(Vector2(lecture, predite))
		resultat.details.append({
			"libelle": cas.libelle,
			"lecture": lecture,
			"vraie": vraie,
			"predite": predite,
			"ecart": ecart,
		})

	resultat.ecart_max = pire
	resultat.ecart_moyen = somme / float(maxi(resultat.ecarts.size(), 1))
	resultat.etoiles = ResultatBanc.etoiles_pour(pire)

	specification_evaluee.emit(resultat)
	if resultat.equipable():
		piece_validee.emit(Piece.depuis(machine, emplacement, specification, resultat))
	return resultat


## Plage de lectures que la machine peut produire avec ses valeurs de reference.
## Sert a figer les axes du graphe : le cadrage n'est pas un secret, et un graphe
## qui saute a chaque releve est illisible.
func plage_lecture() -> Vector2:
	var emplacement: EmplacementPiece = _emplacement_principal()
	if emplacement == null or machine.etalons.is_empty():
		return Vector2.ZERO
	var mini: float = INF
	var maxi: float = -INF
	for etalon: float in machine.etalons:
		var lecture: float = _valeur(
			_etat_complet(etat_pour_etalon(etalon)), emplacement.grandeur_lue
		)
		if is_nan(lecture):
			continue
		mini = minf(mini, lecture)
		maxi = maxf(maxi, lecture)
	return Vector2.ZERO if is_inf(mini) else Vector2(mini, maxi)


## Trace continu du modele du joueur, pour le superposer aux releves du graphe.
func courbe_predite(specification: Specification, x_min: float, x_max: float, points: int = 64) -> PackedVector2Array:
	var courbe: PackedVector2Array = PackedVector2Array()
	if not specification.est_complete() or points < 2 or x_max <= x_min:
		return courbe
	var emplacement: EmplacementPiece = specification.emplacement
	if emplacement.entrees_gabarit.is_empty():
		return courbe
	for i: int in points:
		var x: float = lerpf(x_min, x_max, float(i) / float(points - 1))
		var y: float = specification.evaluer({String(emplacement.entrees_gabarit[0]): x})
		if is_nan(y):
			continue
		courbe.append(Vector2(x, y))
	return courbe


## Trace de la machine reelle sur la meme plage. Le banc la revele apres coup :
## c'est elle qui montre ou le modele decroche, plutot qu'un verdict.
func courbe_reelle(x_min: float, x_max: float, points: int = 64) -> PackedVector2Array:
	var courbe: PackedVector2Array = PackedVector2Array()
	var emplacement: EmplacementPiece = _emplacement_principal()
	if emplacement == null or machine.loi_cachee == null or points < 2 or x_max <= x_min:
		return courbe

	var loi: Loi = machine.loi_cachee
	# La lecture est en abscisse ; selon la machine elle est soit l'entree de la
	# loi cachee, soit sa sortie. Dans le second cas il faut remonter la loi.
	var lue_est_sortie: bool = loi.grandeurs_sortie.has(emplacement.grandeur_lue)
	if lue_est_sortie and not loi.est_inversible():
		return courbe

	for i: int in points:
		var x: float = lerpf(x_min, x_max, float(i) / float(points - 1))
		var complet: Dictionary
		if lue_est_sortie:
			var entree: float = loi.inverser(_avec_parametres({String(emplacement.grandeur_lue): x}))
			complet = _etat_complet({String(loi.grandeurs_entree[0]): entree})
		else:
			complet = _etat_complet({String(emplacement.grandeur_lue): x})
		var y: float = _valeur(complet, emplacement.grandeur_produite)
		if not is_nan(y):
			courbe.append(Vector2(x, y))
	return courbe


func _emplacement_principal() -> EmplacementPiece:
	if machine == null or machine.emplacements.is_empty():
		return null
	return machine.emplacements[0]


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


func _entrees_gabarit(emplacement: EmplacementPiece, complet: Dictionary) -> Dictionary:
	# Le gabarit nomme sa lecture "lecture" ; le banc lui passe la grandeur lue.
	var entrees: Dictionary = {}
	for nom: StringName in emplacement.entrees_gabarit:
		entrees[String(nom)] = _valeur(complet, emplacement.grandeur_lue)
	return entrees


func _valeur(etat: Dictionary, grandeur: StringName) -> float:
	var cle: String = String(grandeur)
	return float(etat[cle]) if etat.has(cle) else EvaluateurExpression.ECHEC


func _pas(instrument: Primitive) -> float:
	if instrument == null:
		return -1.0
	return float(_precisions.get(instrument.id, -1.0))


func _ecart_relatif(predite: float, vraie: float) -> float:
	# Une verite quasi nulle rendrait tout ecart relatif infini ; on retombe alors
	# sur l'ecart absolu, qui reste comparable aux memes paliers.
	if absf(vraie) < 1e-9:
		return absf(predite - vraie)
	return absf(predite - vraie) / absf(vraie)


func _refus_eventuel(specification: Specification) -> ResultatBanc:
	if machine == null:
		return ResultatBanc.depuis_erreur("aucune machine chargee")
	if specification == null or specification.emplacement == null:
		return ResultatBanc.depuis_erreur("aucune specification")
	if not specification.est_complete():
		return ResultatBanc.depuis_erreur("la fiche technique est incomplete")
	if machine.cas_test_caches.is_empty():
		return ResultatBanc.depuis_erreur("la machine n'a aucun cas de test")
	if _matiere <= 0:
		return ResultatBanc.depuis_erreur("plus de matiere")
	return null


func _echouer(message: String) -> ResultatBanc:
	var resultat: ResultatBanc = ResultatBanc.depuis_erreur(message)
	specification_evaluee.emit(resultat)
	return resultat
