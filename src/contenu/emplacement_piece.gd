## Une piece a specifier : la fiche technique que le joueur doit remplir.
##
## C'est le point d'extension central du jeu. L'emplacement declare la forme du
## modele attendu ("a * lecture + b"), les champs numeriques a saisir, les deux
## grandeurs qui font les axes du graphe, et l'amelioration accordee en
## recompense. Une machine entierement nouvelle se decrit ici, en donnee.
class_name EmplacementPiece
extends Resource

@export var id: StringName = &""

## Nom de la piece une fois fabriquee, tel qu'il apparait a l'atelier.
@export var nom: String = ""

## Ce que la fiche demande, en une phrase. Jamais une explication, jamais un
## rappel de cours : l'enonce d'une commande, comme sur un plan.
@export_multiline var libelle: String = ""

## Le modele que le joueur parametre, en fonction de [member entrees_gabarit] et
## de [member parametres]. Il ne soumet jamais un nombre-reponse : il soumet
## cette formule avec ses coefficients, evaluee ensuite sur des cas caches.
@export var gabarit: String = ""

## Coefficients a saisir. Un champ numerique vide par nom, jamais un curseur.
@export var parametres: Array[String] = []

## Unite affichee a cote de chaque champ, pour information.
@export var unites_parametres: Dictionary = {}

## Noms de variables que le banc fournit au gabarit, en plus des parametres.
## Un tableau : une machine a plusieurs releves simultanes reste exprimable.
@export var entrees_gabarit: Array[StringName] = [&"lecture"]

## Grandeur que le joueur lit sur son instrument. Axe des abscisses du graphe, et
## premiere entree du gabarit.
@export var grandeur_lue: StringName = &""

## Grandeur que la piece doit rendre. Axe des ordonnees, et valeur comparee a la
## verite cachee par le banc d'essai.
@export var grandeur_produite: StringName = &""

## Primitive dont la precision est amelioree par cette piece. C'est toute la
## recompense du jeu : pas un objet, un instrument plus fin.
@export var primitive_amelioree: StringName = &""

## Nouveau pas de cette primitive. Le peson fait passer peser de 100 g a 5 g.
@export var pas_ameliore: float = 0.0


## Noms de variables acceptes par la specification construite sur cet emplacement.
func noms_gabarit() -> PackedStringArray:
	var noms: PackedStringArray = PackedStringArray()
	for entree: StringName in entrees_gabarit:
		noms.append(String(entree))
	for parametre: String in parametres:
		noms.append(parametre)
	return noms


func verifier() -> Array[String]:
	var problemes: Array[String] = []
	if id == &"":
		problemes.append("emplacement sans id")
	if gabarit.strip_edges().is_empty():
		problemes.append("%s : aucun gabarit, le joueur n'aurait rien a parametrer" % id)
	if parametres.is_empty():
		problemes.append("%s : aucun parametre, la fiche technique serait vide" % id)
	if grandeur_lue == &"" or grandeur_produite == &"":
		problemes.append("%s : les deux axes du graphe ne sont pas definis" % id)
	var eval: EvaluateurExpression = EvaluateurExpression.new(gabarit, noms_gabarit())
	if not eval.est_valide():
		problemes.append("%s : gabarit illisible — %s" % [id, eval.erreur()])
	return problemes
