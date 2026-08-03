# La regle : la COUCHE FORME. Geometrie, zones de prehension, marqueurs. Un objet
# pose sur la table, manipule directement : on attrape le corps pour la
# translater, une extremite pour la faire pivoter autour de l'autre. Aucun bouton,
# aucun mode, aucun raccourci.
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

const Marqueurs: GDScript = preload("res://src/atelier/marqueurs.gd")
const VisuelRegle: GDScript = preload("res://src/atelier/visuel_regle.gd")

## Longueur graduee, en mm. Une regle de 20 cm.
const LONGUEUR: float = 200.0
const LARGEUR: float = 22.0
## Pas de graduation, en mm. Le millimetre, evidemment.
const PAS: float = 1.0
## Zone de prehension a chaque bout, en mm. Large expres : on ne doit pas avoir a
## viser.
const ZONE_BOUT: float = 31.0

## PIVOT_AUTOUR_FIN : on tient le debut, la regle tourne autour de son autre bout.
enum Prise { AUCUNE, TRANSLATION, PIVOT_AUTOUR_FIN, PIVOT_AUTOUR_DEBUT }

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


func _zone(ou: Vector2) -> int:
	var local: Vector2 = to_local(ou)
	if local.y < -7.0 or local.y > LARGEUR + 5.0:
		return Prise.AUCUNE
	if local.x < -7.0 or local.x > LONGUEUR + 7.0:
		return Prise.AUCUNE
	# Un bout fait pivoter autour de l'autre bout.
	if local.x < ZONE_BOUT:
		return Prise.PIVOT_AUTOUR_FIN
	if local.x > LONGUEUR - ZONE_BOUT:
		return Prise.PIVOT_AUTOUR_DEBUT
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


## Pivot autour du bout oppose a celui qu'on tient. Le point d'appui ne bouge pas.
func pivoter(vers: Vector2, encre: Vector2) -> void:
	var cible: Vector2 = vers
	accroche = Vector2.INF
	if encre != Vector2.INF:
		cible = encre
		accroche = encre

	var appui: Vector2 = fin() if prise == Prise.PIVOT_AUTOUR_FIN else debut()
	var angle: float = (cible - appui).angle()

	if prise == Prise.PIVOT_AUTOUR_FIN:
		# On tient le debut. En local, le vecteur appui -> debut vaut (-L, 0),
		# donc d'angle PI : la rotation est celle du curseur moins PI, et
		# l'origine se pose au bout du bras, appui compris.
		rotation = angle - PI
		global_position = appui + Vector2.from_angle(angle) * LONGUEUR
	else:
		# On tient la fin, l'appui est l'origine locale : elle ne bouge pas.
		rotation = angle
		global_position = appui
	_rafraichir()


## Le bout que le curseur tient, en monde — c'est lui qu'on aimante.
func bout_tenu() -> Vector2:
	return fin() if prise == Prise.PIVOT_AUTOUR_DEBUT else debut()


func _rafraichir() -> void:
	if _visuel == null:
		return
	_visuel.etat = prise if prise != Prise.AUCUNE else survol
	_visuel.accroche = accroche
	_visuel.queue_redraw()
