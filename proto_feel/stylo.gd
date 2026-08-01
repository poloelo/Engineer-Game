# Le stylo. Trois etats : pose sur l'etabli, tenu a la main, clipse sur un
# element mobile.
#
# Clipse au crochet avec la pointe baissee, il trace la trajectoire de ce a quoi
# il est attache — un point par masse ajoutee, ou toute la courbe d'une
# oscillation. Aucun cas particulier : c'est la meme pointe qui touche la meme
# feuille.
extends Node2D

const CORPS: Color = Color("e6f0f8")
const ENCRE: Color = Color("ffd9a0")
const VISE: Color = Color("ffb454")
const LEVE: Color = Color(0.90, 0.94, 0.97, 0.35)

const LONGUEUR: float = 58.0
const LARGEUR: float = 9.0
## De combien la pointe descend quand on la baisse. C'est le geste explicite :
## on ne trace pas en permanence.
const COURSE_POINTE: float = 9.0

var tenu: bool = false
var pointe_baissee: bool = false
## L'element mobile sur lequel il est clipse, ou null.
var support: Node2D = null
var decalage: Vector2 = Vector2.ZERO
## Vrai quand lacher maintenant le clipserait quelque part.
var vise: bool = false


func attraper(ou: Vector2) -> bool:
	if to_local(ou).length() > LONGUEUR * 0.75:
		return false
	tenu = true
	declipser()
	queue_redraw()
	return true


func relacher() -> void:
	tenu = false
	vise = false
	queue_redraw()


func clipser(sur: Node2D) -> void:
	support = sur
	# On garde l'ecart courant : le stylo reste ou le joueur l'a pose, il ne
	# saute pas au centre de la masse.
	decalage = global_position - sur.global_position
	queue_redraw()


func declipser() -> void:
	support = null
	queue_redraw()


func basculer_pointe() -> void:
	pointe_baissee = not pointe_baissee
	queue_redraw()


## Ou l'encre touche le papier.
func pointe() -> Vector2:
	var course: float = COURSE_POINTE if pointe_baissee else 0.0
	return global_position + Vector2(0.0, LONGUEUR * 0.5 + course)


func _draw() -> void:
	var couleur: Color = VISE if vise else CORPS
	var demi: float = LONGUEUR * 0.5
	var course: float = COURSE_POINTE if pointe_baissee else 0.0

	# Le corps, un simple rectangle incline de rien du tout.
	draw_rect(
		Rect2(Vector2(-LARGEUR * 0.5, -demi), Vector2(LARGEUR, LONGUEUR * 0.78)),
		couleur,
		false,
		1.8
	)
	# La bague, qui marque la separation corps / pointe.
	draw_line(
		Vector2(-LARGEUR * 0.7, demi * 0.56),
		Vector2(LARGEUR * 0.7, demi * 0.56),
		couleur,
		2.0
	)
	# Le cone de la pointe, qui sort quand elle est baissee.
	var bout: Vector2 = Vector2(0.0, demi + course)
	draw_polyline(
		PackedVector2Array([
			Vector2(-LARGEUR * 0.5, demi * 0.56),
			bout,
			Vector2(LARGEUR * 0.5, demi * 0.56),
		]),
		ENCRE if pointe_baissee else LEVE,
		1.8
	)
	if pointe_baissee:
		draw_circle(bout, 2.4, ENCRE)

	# Le clip, qui montre a quoi il est attache.
	if support != null and is_instance_valid(support):
		draw_arc(Vector2(0.0, -demi + 6.0), 7.0, 0.0, TAU, 16, VISE, 1.6)
		draw_line(Vector2.ZERO, to_local(support.global_position), VISE.darkened(0.4), 1.0)
