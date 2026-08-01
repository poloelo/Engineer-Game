## Une machine du jeu, entierement decrite en donnee.
##
## Ajouter une machine consiste a ecrire un .tres de ce type — plus une loi si
## elle en introduit une — sans toucher a la simulation. C'est le critere qui
## valide toute l'architecture.
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

## Les pieces a specifier. Une seule pour le peson, le tableau est la pour les
## machines a plusieurs sous-ensembles.
@export var emplacements: Array[EmplacementPiece] = []

## Les cas caches de l'epreuve finale.
@export var cas_test_caches: Array[CasTest] = []

## Valeurs de reference que le joueur peut imposer a la machine pendant sa
## calibration (les masses etalons du peson). Elles s'appliquent a la premiere
## grandeur d'entree de la loi cachee.
@export var etalons: Array[float] = []

## Instrument avec lequel le joueur lit [member EmplacementPiece.grandeur_lue].
## Sa resolution est ce qui limite la qualite de la calibration.
@export var primitive_lue: Primitive = null

## Instrument avec lequel il connait [member EmplacementPiece.grandeur_produite].
## Nul quand la valeur est connue exactement — les masses etalons ne se pesent
## pas, elles sont gravees.
@export var primitive_produite: Primitive = null

## Budget de matiere : nombre de soumissions au banc. Assez pour que le
## tatonnement reste legitime, pas assez pour balayer au hasard.
@export var matiere_initiale: int = 12


func verifier() -> Array[String]:
	var problemes: Array[String] = []
	if id == &"":
		problemes.append("machine sans id")
	if loi_cachee == null:
		problemes.append("%s : aucune loi cachee" % id)
	if emplacements.is_empty():
		problemes.append("%s : aucun emplacement de piece" % id)
	if cas_test_caches.size() < 2:
		problemes.append(
			"%s : moins de deux cas caches, une valeur devinee suffirait a passer" % id
		)
	if primitive_lue == null:
		problemes.append("%s : aucun instrument de lecture" % id)
	for emplacement: EmplacementPiece in emplacements:
		problemes.append_array(emplacement.verifier())
	return problemes
