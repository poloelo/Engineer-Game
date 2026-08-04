# La regle : la COUCHE FORME. Geometrie, zones de prehension, marqueurs.
#
# DEUX ZONES, DEUX ACTIONS, ET LE SURVOL LE DIT :
#   - le corps   : on la deplace, et son zero se cale tout seul sur une marque
#   - la molette : on la fait pivoter autour de ce zero
# Il y avait avant deux zones de pivot larges de 31 mm a chaque bout, qui
# ressemblaient au corps : on ne savait pas ce qu'on allait attraper. La molette
# est ronde, moletee, posee hors du corps — elle ne ressemble a rien d'autre.
#
# On ne s'en sert que droite : elle se cale seule sur l'horizontale et la
# verticale, et il faut forcer pour l'incliner.
#
# Son arete de mesure est la ligne y = 0 en repere local : un trait franc, avec
# les graduations qui en descendent et le corps translucide en dessous. On vise
# une arete, pas l'epaisseur d'un rectangle.
#
# ELLE MESURE POUR DE VRAI. Le monde est en millimetres, la graduation est en
# millimetres, et une marque gravee a 10 mm couvre exactement 10 mm de monde.
# C'etait le but de tout le passage aux unites physiques : l'instrument ne ment
# plus.
extends Node2D

const Reglages: GDScript = preload("res://src/atelier/reglages.gd")
const Marqueurs: GDScript = preload("res://src/atelier/marqueurs.gd")
const VisuelRegle: GDScript = preload("res://src/atelier/visuel_regle.gd")

## Longueur graduee, en mm. Une regle de 20 cm.
const LONGUEUR: float = 200.0
const LARGEUR: float = 22.0
## Pas de graduation, en mm. Le millimetre, evidemment.
const PAS: float = 1.0
## Rayon de la molette de rotation, en mm. Elle deborde du corps, au bout oppose
## au zero : on pince le zero sur une marque et on fait tourner par l'autre bout.
const RAYON_MOLETTE: float = 9.5
## De combien la molette est decalee au-dela du bout de la regle, en mm.
const RECUL_MOLETTE: float = 11.0

enum Prise { AUCUNE, TRANSLATION, PIVOT }

var prise: int = Prise.AUCUNE
var survol: int = Prise.AUCUNE
## Point d'encre sur lequel la regle vient de s'aimanter, pour le montrer.
var accroche: Vector2 = Vector2.INF

var _visuel: Node2D = null


func _ready() -> void:
	Marqueurs.poser(self, "bord_zero", Vector2.ZERO, Marqueurs.REPERE)
	Marqueurs.poser(self, "bord_fin", Vector2(LONGUEUR, 0.0), Marqueurs.REPERE)

	_visuel = VisuelRegle.new()
	_visuel.longueur = LONGUEUR
	_visuel.largeur = LARGEUR
	_visuel.pas = PAS
	_visuel.rayon_molette = RAYON_MOLETTE
	_visuel.recul_molette = RECUL_MOLETTE
	add_child(_visuel)
	_rafraichir()


# --- Geometrie ---------------------------------------------------------------


func debut() -> Vector2:
	return global_position


func fin() -> Vector2:
	return to_global(Vector2(LONGUEUR, 0.0))


## Le zero de la graduation, celui qu'on cale sur un repere.
func zero() -> Vector2:
	return Marqueurs.position_de(self, "bord_zero")


## La molette, en repere local.
func molette() -> Vector2:
	return Vector2(LONGUEUR + RECUL_MOLETTE, LARGEUR * 0.5)


## La zone sous un point, sans rien saisir. Sert au curseur.
func zone_sous(ou: Vector2) -> int:
	return _zone(ou)


func _zone(ou: Vector2) -> int:
	var local: Vector2 = to_local(ou)
	# La molette d'abord : c'est la seule zone qui tourne, et elle gagne toujours.
	if local.distance_to(molette()) <= RAYON_MOLETTE + 2.0:
		return Prise.PIVOT
	if local.y < -7.0 or local.y > LARGEUR + 5.0:
		return Prise.AUCUNE
	if local.x < -7.0 or local.x > LONGUEUR + 7.0:
		return Prise.AUCUNE
	return Prise.TRANSLATION


# --- Manipulation ------------------------------------------------------------


func attraper(ou: Vector2) -> bool:
	prise = _zone(ou)
	_rafraichir()
	return prise != Prise.AUCUNE


func relacher() -> void:
	prise = Prise.AUCUNE
	accroche = Vector2.INF
	_rafraichir()


func definir_survol(ou: Vector2) -> void:
	var nouveau: int = _zone(ou) if prise == Prise.AUCUNE else prise
	if nouveau != survol:
		survol = nouveau
		_rafraichir()


## Translation. [param encre] est le point d'encre le plus proche du zero, ou
## Vector2.INF : la regle s'y cale d'elle-meme, ce qui evite la visee au pixel.
func deplacer(vers: Vector2, encre: Vector2) -> void:
	global_position = vers
	accroche = Vector2.INF
	if encre != Vector2.INF:
		global_position = encre
		accroche = encre
	_rafraichir()


## Pivot autour du zero, qui ne bouge pas : c'est lui qu'on a cale sur une marque,
## il n'est pas question qu'il parte.
##
## L'angle se cale sur l'horizontale et la verticale des qu'on en approche. On ne
## se sert de cette regle que droite ; incliner reste possible, mais il faut le
## vouloir.
func pivoter(vers: Vector2) -> void:
	var appui: Vector2 = debut()
	rotation = _caler_angle((vers - appui).angle())
	global_position = appui
	_rafraichir()


## Ramene un angle sur le quart de tour le plus proche s'il en est assez pres.
func _caler_angle(angle: float) -> float:
	var seuil: float = deg_to_rad(Reglages.AIMANT_ANGLE_REGLE)
	var quart: float = roundf(angle / (PI * 0.5)) * PI * 0.5
	return quart if absf(angle_difference(angle, quart)) < seuil else angle


## Vrai quand la regle est calee sur un quart de tour pile.
func est_droite() -> bool:
	return absf(angle_difference(rotation, roundf(rotation / (PI * 0.5)) * PI * 0.5)) < 0.001


func _rafraichir() -> void:
	if _visuel == null:
		return
	_visuel.etat = prise if prise != Prise.AUCUNE else survol
	_visuel.accroche = accroche
	_visuel.droite = est_droite()
	_visuel.queue_redraw()
