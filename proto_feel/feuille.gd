# La feuille punaisee sur l'etabli, derriere le ressort.
#
# Les traces sont stockees en coordonnees LOCALES a la feuille. C'est tout le
# truc : decaler le papier emporte les traces avec lui, exactement comme du vrai
# papier. Un nuage de points ne se construit pas autrement.
extends Node2D

const Reglages: GDScript = preload("res://reglages.gd")

# Un papier doit se voir comme un panneau plus clair que le fond, pas comme un
# voile. Une premiere valeur a 5 % d'alpha etait litteralement invisible.
const PAPIER: Color = Color("15314f")
const BORD: Color = Color(0.90, 0.94, 0.97, 0.38)
const QUADRILLAGE: Color = Color(0.90, 0.94, 0.97, 0.10)
const ENCRE: Color = Color("ffd9a0")
const PUNAISE: Color = Color(0.90, 0.94, 0.97, 0.55)

const TAILLE: Vector2 = Vector2(660.0, 470.0)
const PAS_QUADRILLAGE: float = 22.0

## Deux faces : on retourne la feuille pour repartir a neuf sans perdre l'autre.
var _faces: Array[Array] = [[], []]
var _face: int = 0
var _trace_en_cours: PackedVector2Array = PackedVector2Array()
var _attrapee: bool = false


func rect() -> Rect2:
	return Rect2(Vector2.ZERO, TAILLE)


func attraper(ou: Vector2) -> bool:
	if not rect().has_point(to_local(ou)):
		return false
	_attrapee = true
	return true


func relacher() -> void:
	_attrapee = false


## Depose un point sous la pointe, si elle touche le papier.
func tracer(pointe_monde: Vector2) -> void:
	var local: Vector2 = to_local(pointe_monde)
	if not rect().has_point(local):
		lever()
		return
	if _trace_en_cours.is_empty():
		_trace_en_cours.append(local)
		queue_redraw()
		return
	# Un point tous les PAS_TRACE pixels : assez fin pour une courbe, assez
	# grossier pour ne pas gonfler indefiniment pendant une oscillation.
	if _trace_en_cours[-1].distance_to(local) >= Reglages.PAS_TRACE:
		_trace_en_cours.append(local)
		queue_redraw()


## La pointe se leve : le trait en cours est clos, le suivant repartira ailleurs.
func lever() -> void:
	if _trace_en_cours.is_empty():
		return
	if _trace_en_cours.size() > 1:
		_faces[_face].append(_trace_en_cours)
	else:
		# Un point unique : une marque, pas un trait. On la garde quand meme.
		_faces[_face].append(_trace_en_cours)
	_trace_en_cours = PackedVector2Array()
	queue_redraw()


## Point d'encre le plus proche, en monde, ou Vector2.INF si aucun dans le rayon.
## C'est ce qui permet a la regle de se caler sur une marque sans viser au pixel.
##
## Balayage lineaire de toute la face : suffisant pour un prototype, a revoir si
## les traces deviennent tres longues.
func encre_proche(monde: Vector2, rayon: float) -> Vector2:
	var local: Vector2 = to_local(monde)
	var meilleure: Vector2 = Vector2.INF
	var distance: float = rayon
	for trace: PackedVector2Array in _faces[_face] + [_trace_en_cours]:
		for point: Vector2 in trace:
			var ecart: float = local.distance_to(point)
			if ecart < distance:
				distance = ecart
				meilleure = point
	return Vector2.INF if meilleure == Vector2.INF else to_global(meilleure)


func retourner() -> void:
	lever()
	_face = 1 - _face
	queue_redraw()


func effacer_face() -> void:
	_trace_en_cours = PackedVector2Array()
	_faces[_face] = []
	queue_redraw()


func _draw() -> void:
	draw_rect(rect(), PAPIER, true)
	draw_rect(rect(), BORD, false, 1.5 if _attrapee else 1.0)

	# Un quadrillage tres pale : de quoi situer une trace sans rien mesurer.
	var x: float = PAS_QUADRILLAGE
	while x < TAILLE.x:
		draw_line(Vector2(x, 0.0), Vector2(x, TAILLE.y), QUADRILLAGE, 1.0)
		x += PAS_QUADRILLAGE
	var y: float = PAS_QUADRILLAGE
	while y < TAILLE.y:
		draw_line(Vector2(0.0, y), Vector2(TAILLE.x, y), QUADRILLAGE, 1.0)
		y += PAS_QUADRILLAGE

	for coin: Vector2 in [
		Vector2(14.0, 14.0),
		Vector2(TAILLE.x - 14.0, 14.0),
		Vector2(14.0, TAILLE.y - 14.0),
		Vector2(TAILLE.x - 14.0, TAILLE.y - 14.0),
	]:
		draw_arc(coin, 4.5, 0.0, TAU, 14, PUNAISE, 1.5)

	for trace: PackedVector2Array in _faces[_face]:
		_dessiner_trace(trace)
	_dessiner_trace(_trace_en_cours)


func _dessiner_trace(trace: PackedVector2Array) -> void:
	if trace.size() == 1:
		draw_circle(trace[0], 2.0, ENCRE)
	elif trace.size() > 1:
		draw_polyline(trace, ENCRE, 1.6)
