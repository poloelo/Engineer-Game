## Rend executable une formule ecrite dans un fichier de donnees.
##
## Enrobe la classe [Expression] du moteur : c'est elle qui fait qu'une loi peut
## etre entierement declaree dans un .tres, sans une ligne de GDScript par loi.
## Ecrit une fois, jamais retouche quand on ajoute du contenu.
##
## Vit dans la couche CONTENU et non SIMULATION parce qu'il n'est pas une regle
## de jeu : il est la semantique executable de la donnee elle-meme. La couche
## contenu ne depend ainsi toujours de rien.
class_name EvaluateurExpression
extends RefCounted

## Valeur rendue par [method evaluer] quand l'evaluation echoue. NAN se propage
## dans tous les calculs en aval, ce qui rend une erreur impossible a confondre
## avec un resultat.
const ECHEC: float = NAN

var _expression: Expression = Expression.new()
var _noms: PackedStringArray = PackedStringArray()
var _formule: String = ""
var _valide: bool = false
var _erreur: String = ""


func _init(formule: String, noms_variables: PackedStringArray) -> void:
	_formule = formule
	_noms = noms_variables
	if formule.strip_edges().is_empty():
		_erreur = "formule vide"
		return
	if _expression.parse(formule, noms_variables) != OK:
		_erreur = "%s (dans \"%s\")" % [_expression.get_error_text(), formule]
		return
	_valide = true


func est_valide() -> bool:
	return _valide


func erreur() -> String:
	return _erreur


func formule() -> String:
	return _formule


## Evalue la formule. [param valeurs] associe chaque nom de variable a sa valeur ;
## toute variable manquante est une erreur, jamais un zero implicite.
func evaluer(valeurs: Dictionary) -> float:
	if not _valide:
		return ECHEC

	var ordonnees: Array = []
	ordonnees.resize(_noms.size())
	for i: int in _noms.size():
		var nom: String = _noms[i]
		if not valeurs.has(nom):
			_erreur = "variable \"%s\" absente (dans \"%s\")" % [nom, _formule]
			return ECHEC
		ordonnees[i] = float(valeurs[nom])

	var resultat: Variant = _expression.execute(ordonnees, null, false)
	if _expression.has_execute_failed():
		_erreur = "%s (dans \"%s\")" % [_expression.get_error_text(), _formule]
		return ECHEC
	if not (resultat is float or resultat is int):
		_erreur = "resultat non numerique (dans \"%s\")" % _formule
		return ECHEC
	return float(resultat)
