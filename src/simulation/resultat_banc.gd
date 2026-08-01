## Ce que le banc d'essai rend apres avoir eprouve une piece.
##
## Jamais un booleen, jamais le mot "faux" : un ecart, et deux courbes a
## superposer. Le joueur doit voir ou son modele decroche, pas apprendre qu'il a
## eu tort.
class_name ResultatBanc
extends RefCounted

## Paliers d'ecart relatif. Une piece mediocre passe : on peut avancer avec, et
## revenir plus tard avec un meilleur modele.
const SEUIL_UNE_ETOILE: float = 0.20
const SEUIL_DEUX_ETOILES: float = 0.05
const SEUIL_TROIS_ETOILES: float = 0.01

## Ecart relatif sur chaque cas cache.
var ecarts: Array[float] = []

## Le pire des cas. C'est lui qui decide des etoiles : une piece n'est bonne que
## si elle l'est partout, sinon un modele juste par accident sur un point
## passerait.
var ecart_max: float = INF

var ecart_moyen: float = INF

## 0 a 3. Zero n'est pas un echec, c'est un ecart trop grand pour equiper.
var etoiles: int = 0

## Ce que la machine fait vraiment, en (lecture, valeur vraie).
var points_reels: Array[Vector2] = []

## Ce que le modele du joueur predit, aux memes lectures.
var points_predits: Array[Vector2] = []

## Un dictionnaire par cas : lecture, valeur vraie, valeur predite, ecart.
var details: Array[Dictionary] = []

## Renseigne quand l'evaluation n'a pas pu avoir lieu (fiche incomplete, plus de
## matiere, formule illisible). Distinct d'un mauvais resultat.
var erreur: String = ""


static func depuis_erreur(message: String) -> ResultatBanc:
	var resultat: ResultatBanc = ResultatBanc.new()
	resultat.erreur = message
	return resultat


static func etoiles_pour(ecart: float) -> int:
	if is_nan(ecart) or is_inf(ecart):
		return 0
	if ecart <= SEUIL_TROIS_ETOILES:
		return 3
	if ecart <= SEUIL_DEUX_ETOILES:
		return 2
	if ecart <= SEUIL_UNE_ETOILE:
		return 1
	return 0


func est_valide() -> bool:
	return erreur.is_empty()


## Vrai des une etoile : la piece entre a l'atelier et la machine repart.
func equipable() -> bool:
	return est_valide() and etoiles >= 1
