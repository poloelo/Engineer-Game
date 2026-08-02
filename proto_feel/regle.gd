# La regle. Un objet pose sur la table, manipule directement : on attrape le
# corps pour la translater, une extremite pour la faire pivoter autour de
# l'autre. Aucun bouton, aucun mode, aucun raccourci.
#
# Son arete de mesure est la ligne y = 0 en repere local : un trait franc, avec
# les graduations qui en descendent et le corps translucide en dessous. On vise
# une arete, pas l'epaisseur d'un rectangle.
#
# Les seuls chiffres du prototype sont graves ici. C'est au joueur de les lire,
# a l'oeil, sous la loupe.
extends Node2D

const Reglages: GDScript = preload("res://reglages.gd")

const CORPS: Color = Color(0.72, 0.84, 0.95, 0.09)
const ARETE: Color = Color(0.94, 0.97, 1.0, 0.95)
const BORD: Color = Color(0.90, 0.94, 0.97, 0.30)
const GRADUATION: Color = Color(0.94, 0.97, 1.0, 0.88)
const CHIFFRE: Color = Color(0.94, 0.97, 1.0, 0.95)
const ZERO: Color = Color("6fd3ff")
const SURVOL: Color = Color("ffb454")

const LONGUEUR: float = 460.0
const LARGEUR: float = 44.0
const PAS: float = 5.0
## Zone de prehension a chaque bout. Large exprès : on ne doit pas avoir a viser.
const ZONE_BOUT: float = 62.0

## PIVOT_AUTOUR_FIN : on tient le debut, la regle tourne autour de son autre bout.
enum Prise { AUCUNE, TRANSLATION, PIVOT_AUTOUR_FIN, PIVOT_AUTOUR_DEBUT }

var prise: int = Prise.AUCUNE
var survol: int = Prise.AUCUNE
## Point d'encre sur lequel la regle vient de s'aimanter, pour le montrer.
var accroche: Vector2 = Vector2.INF


# --- Geometrie ---------------------------------------------------------------


func debut() -> Vector2:
	return global_position


func fin() -> Vector2:
	return to_global(Vector2(LONGUEUR, 0.0))


## Le zero de la graduation, celui qu'on cale sur un repere.
func zero() -> Vector2:
	return debut()


func _zone(ou: Vector2) -> int:
	var local: Vector2 = to_local(ou)
	if local.y < -14.0 or local.y > LARGEUR + 10.0:
		return Prise.AUCUNE
	if local.x < -14.0 or local.x > LONGUEUR + 14.0:
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
	queue_redraw()
	return prise != Prise.AUCUNE


func relacher() -> void:
	prise = Prise.AUCUNE
	accroche = Vector2.INF
	queue_redraw()


func definir_survol(ou: Vector2) -> void:
	var nouveau: int = _zone(ou) if prise == Prise.AUCUNE else prise
	if nouveau != survol:
		survol = nouveau
		queue_redraw()


## Translation. [param encre] est le point d'encre le plus proche du zero, ou
## Vector2.INF : la regle s'y cale d'elle-meme, ce qui evite la visee au pixel.
func deplacer(vers: Vector2, encre: Vector2) -> void:
	global_position = vers
	accroche = Vector2.INF
	if encre != Vector2.INF:
		global_position = encre
		accroche = encre
	queue_redraw()


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
	queue_redraw()


## Le bout que le curseur tient, en monde — c'est lui qu'on aimante.
func bout_tenu() -> Vector2:
	return fin() if prise == Prise.PIVOT_AUTOUR_DEBUT else debut()


# --- Dessin ------------------------------------------------------------------


func _draw() -> void:
	var etat: int = prise if prise != Prise.AUCUNE else survol

	# Le corps, translucide : les traces de stylo doivent rester lisibles dessous.
	draw_rect(Rect2(Vector2.ZERO, Vector2(LONGUEUR, LARGEUR)), CORPS, true)
	draw_line(Vector2(0.0, LARGEUR), Vector2(LONGUEUR, LARGEUR), BORD, 1.0)

	# L'arete de mesure : un trait franc, c'est elle qu'on vise.
	draw_line(
		Vector2.ZERO,
		Vector2(LONGUEUR, 0.0),
		SURVOL if etat == Prise.TRANSLATION else ARETE,
		2.0
	)

	_dessiner_graduations()
	_dessiner_zero(etat)
	_dessiner_prehension(etat)

	if accroche != Vector2.INF:
		draw_set_transform_matrix(get_global_transform().affine_inverse())
		draw_arc(accroche, 9.0, 0.0, TAU, 20, SURVOL, 2.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)


func _dessiner_graduations() -> void:
	var police: Font = ThemeDB.fallback_font
	var total: int = int(LONGUEUR / PAS)
	for i: int in total + 1:
		var x: float = float(i) * PAS
		var chiffree: bool = i % 10 == 0
		var longue: bool = i % 5 == 0
		var hauteur: float = 16.0 if chiffree else (10.0 if longue else 5.0)
		draw_line(Vector2(x, 0.0), Vector2(x, hauteur), GRADUATION, 1.0)
		if chiffree and i > 0:
			var texte: String = str(i)
			var largeur: float = police.get_string_size(
				texte, HORIZONTAL_ALIGNMENT_LEFT, -1, 11
			).x
			draw_string(
				police,
				Vector2(x - largeur * 0.5, hauteur + 12.0),
				texte,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				11,
				CHIFFRE
			)


## Le zero doit se reperer d'un coup d'oeil : c'est lui qu'on cale sur une marque.
func _dessiner_zero(_etat: int) -> void:
	draw_line(Vector2.ZERO, Vector2(0.0, LARGEUR), ZERO, 2.0)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(-6.0, -11.0), Vector2(6.0, -11.0)
		]),
		ZERO
	)


## Le retour de survol dit lequel des deux gestes va se produire.
func _dessiner_prehension(etat: int) -> void:
	if etat == Prise.AUCUNE:
		return
	if etat == Prise.TRANSLATION:
		draw_rect(Rect2(Vector2.ZERO, Vector2(LONGUEUR, LARGEUR)), SURVOL, false, 1.5)
		return

	# Pivot : on marque le bout tenu par un arc, et l'appui par un point.
	var tenu: Vector2 = (
		Vector2(LONGUEUR, 0.0) if etat == Prise.PIVOT_AUTOUR_DEBUT else Vector2.ZERO
	)
	var appui: Vector2 = (
		Vector2.ZERO if etat == Prise.PIVOT_AUTOUR_DEBUT else Vector2(LONGUEUR, 0.0)
	)
	draw_arc(tenu + Vector2(0.0, LARGEUR * 0.5), 26.0, -PI * 0.75, PI * 0.25, 28, SURVOL, 2.0)
	draw_circle(appui + Vector2(0.0, LARGEUR * 0.5), 4.0, SURVOL)
