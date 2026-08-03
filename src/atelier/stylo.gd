# Le stylo : la COUCHE FORME. Trois etats — pose sur l'etabli, tenu a la main,
# clipse sur un marqueur.
#
# Clipse au crochet avec la pointe baissee, il trace la trajectoire de ce a quoi
# il est attache — un point par masse ajoutee, ou toute la courbe d'une
# oscillation. Aucun cas particulier : c'est la meme pointe qui touche la meme
# feuille.
#
# La pointe est un Marker2D : c'est lui que la feuille recoit, et il se deplace
# dans l'editeur sans qu'une position soit ecrite en dur nulle part.
extends Node2D

const Marqueurs: GDScript = preload("res://src/atelier/marqueurs.gd")
const VisuelStylo: GDScript = preload("res://src/atelier/visuel_stylo.gd")

## Longueur du corps, en mm.
const LONGUEUR: float = 29.0
const LARGEUR: float = 4.5
## De combien la pointe descend quand on la baisse, en mm. C'est le geste
## explicite : on ne trace pas en permanence.
const COURSE_POINTE: float = 4.5

var tenu: bool = false
var pointe_baissee: bool = false
## L'element mobile sur lequel il est clipse, ou null.
var support: Node2D = null
var decalage: Vector2 = Vector2.ZERO
## Vrai quand lacher maintenant le clipserait quelque part.
var vise: bool = false

var _visuel: Node2D = null
var _pointe: Marker2D = null


func _ready() -> void:
	_pointe = Marqueurs.poser(self, "pointe", Vector2(0.0, LONGUEUR * 0.5), Marqueurs.POINTE)

	_visuel = VisuelStylo.new()
	_visuel.longueur = LONGUEUR
	_visuel.largeur = LARGEUR
	_visuel.course = COURSE_POINTE
	add_child(_visuel)
	_rafraichir()


func attraper(ou: Vector2) -> bool:
	if to_local(ou).length() > LONGUEUR * 0.75:
		return false
	tenu = true
	declipser()
	_rafraichir()
	return true


func relacher() -> void:
	tenu = false
	vise = false
	_rafraichir()


## Ou le stylo se clipserait si on lachait maintenant.
func definir_vise(valeur: bool) -> void:
	if valeur == vise:
		return
	vise = valeur
	_rafraichir()


func clipser(sur: Node2D) -> void:
	support = sur
	# On garde l'ecart courant : le stylo reste ou le joueur l'a pose, il ne
	# saute pas au centre de la masse.
	decalage = global_position - sur.global_position
	_rafraichir()


func declipser() -> void:
	support = null
	_rafraichir()


func basculer_pointe() -> void:
	pointe_baissee = not pointe_baissee
	_pointe.position = Vector2(0.0, LONGUEUR * 0.5 + (COURSE_POINTE if pointe_baissee else 0.0))
	_rafraichir()


## Ou l'encre touche le papier.
func pointe() -> Vector2:
	return _pointe.global_position


func _rafraichir() -> void:
	if _visuel == null:
		return
	_visuel.pointe_baissee = pointe_baissee
	_visuel.vise = vise
	_visuel.support = support
	_visuel.queue_redraw()
