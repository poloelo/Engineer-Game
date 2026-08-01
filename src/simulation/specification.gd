## Ce que le joueur soumet : un modele parametre, jamais un nombre-reponse.
##
## Le banc l'evalue sur des cas qu'il n'a pas vus, donc une specification juste
## sur trois cas caches est un modele, pas une coincidence.
class_name Specification
extends RefCounted

var emplacement: EmplacementPiece = null

## Un flottant par nom de [member EmplacementPiece.parametres].
var valeurs: Dictionary = {}

var _evaluateur: EvaluateurExpression = null


func _init(emplacement_piece: EmplacementPiece, valeurs_saisies: Dictionary = {}) -> void:
	emplacement = emplacement_piece
	valeurs = valeurs_saisies.duplicate()


## Vrai quand tous les champs de la fiche technique sont remplis. Un champ vide
## n'est pas un zero : la fiche se refuse tant qu'elle est incomplete.
func est_complete() -> bool:
	if emplacement == null:
		return false
	for parametre: String in emplacement.parametres:
		if not valeurs.has(parametre):
			return false
	return true


## Applique le modele du joueur a un jeu de lectures.
func evaluer(entrees: Dictionary) -> float:
	if emplacement == null:
		return EvaluateurExpression.ECHEC
	if _evaluateur == null:
		_evaluateur = EvaluateurExpression.new(emplacement.gabarit, emplacement.noms_gabarit())
	var arguments: Dictionary = valeurs.duplicate()
	arguments.merge(entrees, true)
	return _evaluateur.evaluer(arguments)


## Raccourci pour le cas courant a une seule lecture.
func evaluer_lecture(lecture: float) -> float:
	if emplacement == null or emplacement.entrees_gabarit.is_empty():
		return EvaluateurExpression.ECHEC
	return evaluer({String(emplacement.entrees_gabarit[0]): lecture})


func erreur() -> String:
	return "" if _evaluateur == null else _evaluateur.erreur()
