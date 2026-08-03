# Le pot de poudre. On l'attrape par le corps pour le poser, par la poignee pour
# l'incliner. Passe un certain angle, la poudre coule en continu ; on relache et
# le pot se redresse, le filet s'arrete.
#
# Deux zones de prehension et pas de bouton : c'est exactement l'idiome de la
# regle, qu'on translate par le corps et qu'on fait pivoter par un bout.
#
# Rudimentaire par choix : pas de particules, pas de tas qui se forme. Une masse
# qui monte dans le sachet et un trait de stylo qui descend suffisent a lire ce
# qui se passe.
extends Node2D

const Marqueurs: GDScript = preload("res://src/atelier/marqueurs.gd")

const CORPS: Color = Color("e6f0f8")
const POUDRE: Color = Color("ffb454")
const SURVOL: Color = Color("ffb454")
const EFFACE: Color = Color(0.90, 0.94, 0.97, 0.35)

## Dimensions du pot, en mm.
const HAUTEUR: float = 46.0
const LARGEUR: float = 34.0
## Inclinaison maximale, en radians.
const ANGLE_MAX: float = 2.1
## Au-dela de cet angle, ca coule.
const ANGLE_VERSAGE: float = 0.62
## Debit, en g/s. Assez lent pour viser une graduation, assez vif pour ne pas
## attendre.
const DEBIT: float = 55.0
## Ecart horizontal tolere entre le goulot et la bouche visee, en mm. La poudre
## tombe droit : il faut mettre le bec au-dessus du sac, pas a cote.
const LARGEUR_FILET: float = 24.0

## Hauteur de chute maximale, en mm. Au-dela le filet se disperse et rien
## n'arrive dans le sac.
const CHUTE_MAX: float = 260.0

enum Prise { AUCUNE, CORPS, POIGNEE }

## Ce qui reste dans le pot, en grammes. Large : le joueur a droit a l'erreur.
var reste_g: float = 900.0
var prise: int = Prise.AUCUNE
var survol: int = Prise.AUCUNE

var _angle: float = 0.0
var _goulot: Marker2D = null


func _ready() -> void:
	# Le goulot est un Marker2D : c'est lui que le versage interroge, et il suit
	# l'inclinaison du pot sans qu'aucune position ne soit recalculee ailleurs.
	_goulot = Marqueurs.poser(
		self, "goulot", Vector2(LARGEUR * 0.5, -HAUTEUR * 0.5), Marqueurs.POINTE
	)


func _process(delta: float) -> void:
	if prise != Prise.POIGNEE:
		# On relache : le pot se redresse, donc le filet s'arrete tout seul.
		_angle = lerpf(_angle, 0.0, 1.0 - pow(0.0005, delta))
	rotation = _angle
	queue_redraw()


# --- Manipulation ------------------------------------------------------------


func _zone(ou: Vector2) -> int:
	var local: Vector2 = to_local(ou)
	if absf(local.x) > LARGEUR * 0.7 or absf(local.y) > HAUTEUR * 0.62:
		return Prise.AUCUNE
	# Le tiers haut est la poignee : c'est par la qu'on bascule.
	return Prise.POIGNEE if local.y < -HAUTEUR * 0.12 else Prise.CORPS


func attraper(ou: Vector2) -> bool:
	prise = _zone(ou)
	queue_redraw()
	return prise != Prise.AUCUNE


func relacher() -> void:
	prise = Prise.AUCUNE
	queue_redraw()


func definir_survol(ou: Vector2) -> void:
	var nouveau: int = _zone(ou) if prise == Prise.AUCUNE else prise
	if nouveau != survol:
		survol = nouveau
		queue_redraw()


## Incline le pot vers le curseur. L'angle est celui du bras pivot -> curseur,
## ramene a la plage utile : on ne renverse pas le pot par megarde.
func incliner(vers: Vector2) -> void:
	var bras: Vector2 = vers - global_position
	_angle = clampf(bras.angle() + PI * 0.5, 0.0, ANGLE_MAX)


func goulot() -> Vector2:
	return _goulot.global_position


## Vrai quand le pot est assez penche et qu'il reste quelque chose dedans.
func coule() -> bool:
	return _angle > ANGLE_VERSAGE and reste_g > 0.0


## Prend dans le pot ce qui doit s'ecouler pendant [param delta].
func prelever(delta: float) -> float:
	var sorti: float = minf(DEBIT * delta, reste_g)
	reste_g -= sorti
	return sorti


# --- Dessin ------------------------------------------------------------------


func _draw() -> void:
	var etat: int = prise if prise != Prise.AUCUNE else survol
	var demi_l: float = LARGEUR * 0.5
	var demi_h: float = HAUTEUR * 0.5

	# Le corps du pot, evase vers le haut, avec un bec a droite.
	var contour: PackedVector2Array = PackedVector2Array([
		Vector2(-demi_l * 0.78, demi_h),
		Vector2(demi_l * 0.78, demi_h),
		Vector2(demi_l * 0.92, -demi_h * 0.55),
		Vector2(demi_l, -demi_h),
		Vector2(demi_l * 0.45, -demi_h * 0.82),
		Vector2(-demi_l * 0.92, -demi_h * 0.82),
	])
	draw_colored_polygon(contour, Color("0d243d"))
	draw_polyline(contour + PackedVector2Array([contour[0]]), CORPS, 1.0)

	# Le niveau de poudre restante, a plat dans le repere du pot.
	if reste_g > 0.0:
		var part: float = clampf(reste_g / 900.0, 0.0, 1.0)
		var niveau: float = lerpf(demi_h, -demi_h * 0.7, part)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-demi_l * 0.86, niveau),
				Vector2(demi_l * 0.86, niveau),
				Vector2(demi_l * 0.78, demi_h),
				Vector2(-demi_l * 0.78, demi_h),
			]),
			POUDRE.darkened(0.35)
		)

	# La poignee : la zone par ou on bascule, marquee quand le curseur y est.
	draw_line(
		Vector2(-demi_l * 0.92, -demi_h * 0.55),
		Vector2(demi_l * 0.92, -demi_h * 0.55),
		SURVOL if etat == Prise.POIGNEE else EFFACE,
		1.0
	)
	if etat == Prise.CORPS:
		draw_polyline(contour + PackedVector2Array([contour[0]]), SURVOL, 1.0)
