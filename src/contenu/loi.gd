## Un couplage oriente entre grandeurs, entierement declare en donnee.
##
## Une loi porte a la fois sa physique (nom, grandeurs couplees, outils qu'elle
## exige) et sa forme mathematique, qui est transverse : Hooke, Ohm et le debit
## constant sont trois lois sans rapport qui partagent la forme LINEAIRE.
##
## Les formules sont du texte evalue par [EvaluateurExpression]. Les variables
## disponibles sont les [member id] des grandeurs couplees plus les
## [member parametres] : "l0 + force / k" se lit avec force, l0 et k.
##
## L'inverse est une seconde formule declaree, pas une inversion symbolique
## calculee : il n'y a que trente-six lois, ecrites une fois par un humain qui
## connait l'algebre, donc un moteur de calcul formel serait un projet a lui seul
## pour zero gain.
class_name Loi
extends Resource

enum Invertibilite {
	## L'inverse existe et est declare dans [member expression_inverse].
	INVERSIBLE,
	## Plusieurs inconnues pour une seule equation (les formes SYSTEME) : on ne
	## peut retourner la formule, seulement contraindre.
	PARTIELLE,
	## Aucune inverse (le volume de la boite : il faut chercher un maximum, ce
	## qui est un algorithme, pas une formule retournee).
	NON_INVERSIBLE,
}

## Identifiant stable (&"hooke").
@export var id: StringName = &""

## Nom physique affichable, tel qu'il apparait au carnet ("Hooke", "Torricelli").
## Deux lois peuvent le partager : la loi generique de reference et la variante
## concrete d'une machine sont attribuees a la meme entree de carnet.
@export var nom_physique: String = ""

## La forme mathematique. Declaree et non deduite de la formule : pour les lois
## de base c'est la classification pedagogique voulue qui fait foi, pas ce qu'un
## analyseur croit lire. Seules les lois composees, que personne n'ecrit a la
## main, verront leur forme calculee.
@export var forme: Forme.Type = Forme.Type.LINEAIRE

## Grandeurs consommees. Toujours un tableau, meme a un seul element : les lois
## de forme SYSTEME en prennent plusieurs et ne doivent pas etre un cas special.
@export var grandeurs_entree: Array[StringName] = []

## Grandeurs produites.
@export var grandeurs_sortie: Array[StringName] = []

## Noms des constantes physiques de la loi (raideur, longueur a vide...).
## Ce ne sont pas des grandeurs mesurees : ce sont les coefficients que la
## machine fixe et que le joueur doit deduire.
@export var parametres: Array[String] = []

## Valeurs des parametres, surchargeables par la machine qui utilise la loi.
@export var parametres_defaut: Dictionary = {}

## Formule directe, en fonction des grandeurs d'entree et des parametres.
@export_multiline var expression: String = ""

## Formule inverse, en fonction des grandeurs de sortie et des parametres.
## Vide si la loi n'est pas inversible.
@export_multiline var expression_inverse: String = ""

@export var invertibilite: Invertibilite = Invertibilite.INVERSIBLE

## Ce que le joueur doit posseder pour exploiter la loi : soit une des huit
## primitives, soit une piece qu'il a fabriquee. Le diagnostic du graphe des lois
## remonte cette chaine jusqu'aux primitives brutes.
@export var outils_requis: Array[StringName] = []

var _avant: EvaluateurExpression = null
var _arriere: EvaluateurExpression = null


## Noms de variables acceptes par [method evaluer].
func noms_avant() -> PackedStringArray:
	return _noms(grandeurs_entree)


## Noms de variables acceptes par [method inverser].
func noms_arriere() -> PackedStringArray:
	return _noms(grandeurs_sortie)


func est_inversible() -> bool:
	return invertibilite == Invertibilite.INVERSIBLE and not expression_inverse.strip_edges().is_empty()


## Applique la loi dans le sens direct. [param valeurs] complete ou surcharge
## [member parametres_defaut].
func evaluer(valeurs: Dictionary) -> float:
	if _avant == null:
		_avant = EvaluateurExpression.new(expression, noms_avant())
	return _avant.evaluer(_fusionner(valeurs))


## Applique la loi dans le sens retour. Rend NAN si la loi n'est pas inversible :
## c'est au code appelant de verifier [method est_inversible] d'abord.
func inverser(valeurs: Dictionary) -> float:
	if not est_inversible():
		return EvaluateurExpression.ECHEC
	if _arriere == null:
		_arriere = EvaluateurExpression.new(expression_inverse, noms_arriere())
	return _arriere.evaluer(_fusionner(valeurs))


## Derniere erreur rencontree, pour les tests et la commande de diagnostic.
func derniere_erreur() -> String:
	if _avant != null and not _avant.erreur().is_empty():
		return _avant.erreur()
	if _arriere != null and not _arriere.erreur().is_empty():
		return _arriere.erreur()
	return ""


## Problemes structurels de la loi, en langage clair. Utilise par la commande de
## diagnostic pour refuser du contenu incoherent des son ajout.
func verifier() -> Array[String]:
	var problemes: Array[String] = []
	if id == &"":
		problemes.append("loi sans id")
	if grandeurs_entree.is_empty():
		problemes.append("%s : aucune grandeur d'entree" % id)
	if grandeurs_sortie.is_empty():
		problemes.append("%s : aucune grandeur de sortie" % id)
	if outils_requis.is_empty():
		problemes.append("%s : aucun outil requis, la loi serait exploitable a mains nues" % id)

	var avant: EvaluateurExpression = EvaluateurExpression.new(expression, noms_avant())
	if not avant.est_valide():
		problemes.append("%s : formule directe illisible — %s" % [id, avant.erreur()])

	if invertibilite == Invertibilite.INVERSIBLE:
		if expression_inverse.strip_edges().is_empty():
			problemes.append("%s : declaree inversible mais sans formule inverse" % id)
		else:
			var arriere: EvaluateurExpression = EvaluateurExpression.new(
				expression_inverse, noms_arriere()
			)
			if not arriere.est_valide():
				problemes.append("%s : formule inverse illisible — %s" % [id, arriere.erreur()])
	elif not expression_inverse.strip_edges().is_empty():
		problemes.append("%s : formule inverse presente alors que la loi ne l'est pas" % id)

	return problemes


func _noms(grandeurs: Array[StringName]) -> PackedStringArray:
	var noms: PackedStringArray = PackedStringArray()
	for grandeur: StringName in grandeurs:
		noms.append(String(grandeur))
	for parametre: String in parametres:
		noms.append(parametre)
	return noms


func _fusionner(valeurs: Dictionary) -> Dictionary:
	var fusion: Dictionary = parametres_defaut.duplicate()
	fusion.merge(valeurs, true)
	return fusion
