## Une machine du jeu, entierement decrite en donnee.
##
## Elle decrit la PHYSIQUE d'une machine et rien d'autre : sa loi cachee, ses
## constantes, les etalons que le joueur peut lui imposer et les instruments avec
## lesquels il la lit. Ce qui relevait de la fiche technique a specifier a ete
## retire — le jeu ne se joue plus en remplissant un formulaire.
class_name MachineDef
extends Resource

@export var id: StringName = &""

@export var titre: String = ""

## Le symptome, decrit factuellement. Ce que le joueur constate, pas ce qu'il
## doit en conclure : une balance qui refuse de bouger est le tutoriel.
@export_multiline var symptome: String = ""

## La physique reelle de la machine, cachee au joueur. Le banc s'en sert pour
## deriver les lectures et les bonnes reponses des cas de test.
@export var loi_cachee: Loi = null

## Constantes de la machine, qui surchargent celles de la loi. C'est ce qui
## permet a deux machines de reutiliser la meme loi avec des valeurs differentes.
@export var parametres_caches: Dictionary = {}

## Grandeur que le joueur lit sur son instrument.
@export var grandeur_lue: StringName = &""

## Grandeur que la machine produit, en face de la lecture.
@export var grandeur_produite: StringName = &""

## Valeurs de reference que le joueur peut imposer a la machine pendant sa
## calibration (les masses etalons du peson). Elles s'appliquent a la premiere
## grandeur d'entree de la loi cachee.
@export var etalons: Array[float] = []

## Instrument avec lequel le joueur lit [member grandeur_lue].
## Sa resolution est ce qui limite la qualite de sa calibration.
@export var primitive_lue: Primitive = null

## Instrument avec lequel il connait [member grandeur_produite].
## Nul quand la valeur est connue exactement — les masses etalons ne se pesent
## pas, elles sont gravees.
@export var primitive_produite: Primitive = null


func verifier() -> Array[String]:
	var problemes: Array[String] = []
	if id == &"":
		problemes.append("machine sans id")
	if loi_cachee == null:
		problemes.append("%s : aucune loi cachee" % id)
	if grandeur_lue == &"":
		problemes.append("%s : aucune grandeur lue" % id)
	if grandeur_produite == &"":
		problemes.append("%s : aucune grandeur produite" % id)
	if primitive_lue == null:
		problemes.append("%s : aucun instrument de lecture" % id)
	return problemes
