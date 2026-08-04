# Le pointeau : la COUCHE FORME. Un coup sec, un trait horizontal court a la
# hauteur courante. C'est le seul geste de tracage utile au niveau 1.
#
# Il remplace le stylo, qui tracait en continu. Une trace continue donne un point
# quand rien ne bouge lateralement, et il fallait pousser le crochet de cote pour
# obtenir un repere lisible — un bug deguise en geste. Le stylo existe toujours
# (stylo.gd) et servira au niveau 3, quand le papier defilera sous la pointe.
#
# DEUX ZONES, DEUX ACTIONS, ET LE SURVOL LE DIT :
#   - le corps      : on le prend et on le deplace, il se clipse au ressort
#   - la tete       : on frappe, ca marque
# Rien d'autre. Si le joueur doit deviner ce qu'un clic va faire, c'est rate.
extends Node2D

const Marqueurs: GDScript = preload("res://src/atelier/marqueurs.gd")
const VisuelPointeau: GDScript = preload("res://src/atelier/visuel_pointeau.gd")

## Longueur du corps, en mm.
const LONGUEUR: float = 34.0
const LARGEUR: float = 6.0
## Rayon de la tete de frappe, en mm. Large : c'est un bouton qu'on tape.
const RAYON_TETE: float = 7.0
## Longueur du trait laisse par un coup, en mm.
const LONGUEUR_TRAIT: float = 16.0
## De combien la tete s'enfonce quand on frappe, en mm.
const COURSE_FRAPPE: float = 3.0

## Ou la pointe se monte par rapport a son support, en mm.
##
## Le montage est FIXE et non pas la ou la main a lache. Deux raisons, et les
## deux sont dures :
##   - toutes les marques doivent etre sur la meme verticale pour former un
##     cadran ; un montage libre les eparpillerait et le cadran ne voudrait
##     plus rien dire ;
##   - a l'aplomb du ressort, les marques tombent sur le point d'accroche, et
##     annoter une marque rependait la masse au ressort. Ce decalage lateral
##     les separe une fois pour toutes.
const MONTAGE: Vector2 = Vector2(46.0, 0.0)

enum Prise { AUCUNE, CORPS, TETE }

var tenu: bool = false
## L'element sur lequel il est clipse, ou null.
var support: Node2D = null
var decalage: Vector2 = Vector2.ZERO
## Vrai quand lacher maintenant le clipserait quelque part.
var vise: bool = false
var survol: int = Prise.AUCUNE

var _pointe: Marker2D = null
var _visuel: Node2D = null
var _enfoncement: float = 0.0


func _ready() -> void:
	_pointe = Marqueurs.poser(self, "pointe", Vector2(LONGUEUR * 0.5, 0.0), Marqueurs.POINTE)
	_visuel = VisuelPointeau.new()
	_visuel.longueur = LONGUEUR
	_visuel.largeur = LARGEUR
	_visuel.rayon_tete = RAYON_TETE
	add_child(_visuel)
	_rafraichir()


func _process(delta: float) -> void:
	if _enfoncement <= 0.0:
		return
	# La tete remonte apres le coup. Rien ne s'arrete net.
	_enfoncement = maxf(_enfoncement - delta * 24.0, 0.0)
	_rafraichir()


# --- Zones -------------------------------------------------------------------


func zone(ou: Vector2) -> int:
	var local: Vector2 = to_local(ou)
	if local.distance_to(_tete()) <= RAYON_TETE + 2.0:
		return Prise.TETE
	if absf(local.x) <= LONGUEUR * 0.55 and absf(local.y) <= LARGEUR * 1.6:
		return Prise.CORPS
	return Prise.AUCUNE


func definir_survol(ou: Vector2) -> void:
	var nouveau: int = zone(ou) if not tenu else Prise.CORPS
	if nouveau == survol:
		return
	survol = nouveau
	_rafraichir()


func _tete() -> Vector2:
	return Vector2(-LONGUEUR * 0.5 - RAYON_TETE * 0.5 + _enfoncement, 0.0)


# --- Manipulation ------------------------------------------------------------


## Rend vrai si le corps est saisi. La tete, elle, ne se traine pas : elle frappe.
func attraper(ou: Vector2) -> bool:
	if zone(ou) != Prise.CORPS:
		return false
	tenu = true
	declipser()
	_rafraichir()
	return true


func relacher() -> void:
	tenu = false
	vise = false
	_rafraichir()


func definir_vise(valeur: bool) -> void:
	if valeur == vise:
		return
	vise = valeur
	_rafraichir()


func clipser(sur: Node2D) -> void:
	support = sur
	# La pointe se pose a MONTAGE du support, pas la ou on a lache : c'est un
	# instrument qu'on visse a sa place, pas un autocollant.
	decalage = MONTAGE - Vector2(LONGUEUR * 0.5, 0.0)
	_rafraichir()


func declipser() -> void:
	support = null
	_rafraichir()


## Le coup sec. Rend les deux bouts du trait a graver, en monde.
func frapper() -> Array[Vector2]:
	_enfoncement = COURSE_FRAPPE
	_rafraichir()
	var bout: Vector2 = pointe()
	# Le trait part de la pointe vers la gauche : la pointe elle-meme reste le
	# bord de reference, celui qu'on cale sous le zero de la regle.
	return [bout, bout - Vector2(LONGUEUR_TRAIT, 0.0)] as Array[Vector2]


func pointe() -> Vector2:
	return _pointe.global_position


func _rafraichir() -> void:
	if _visuel == null:
		return
	_visuel.enfoncement = _enfoncement
	_visuel.survol = survol
	_visuel.vise = vise
	_visuel.clipse = support != null and is_instance_valid(support)
	_visuel.queue_redraw()
