# Le visuel d'une masse : la COUCHE VISIBLE, remplacable.
#
# Deposer `textures/masse_50g.png` suffit a habiller la masse de 50 g ;
# `textures/masse.png` habille toutes celles qui n'ont pas leur fichier propre ;
# `textures/crochet.png` habille le crochet. Sans fichier, on dessine le disque
# fendu comme avant.
#
# La texture est cadree sur le diametre de collision : un PNG carre tombe pile
# sur la forme, sans reglage.
extends Node2D

const Textures: GDScript = preload("res://textures.gd")

const FOND: Color = Color("0d243d")
const TRAIT: Color = Color("e6f0f8")
const TRAIT_EFFACE: Color = Color(0.90, 0.94, 0.97, 0.45)
const SAISIE: Color = Color("6fd3ff")
const PRETE: Color = Color("ffb454")

var rayon: float = 11.0
var crochet: bool = false
var masse_g: float = 10.0
var accrochee: bool = false
var saisie: bool = false
var prete: bool = false

var _sprite: Sprite2D = null


func _ready() -> void:
	var texture: Texture2D = _texture()
	if texture == null:
		return
	# Avec texture, le dessin procedural se tait completement.
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.centered = true
	var taille: Vector2 = texture.get_size()
	if taille.x > 0.0 and taille.y > 0.0:
		_sprite.scale = Vector2.ONE * (rayon * 2.0 / maxf(taille.x, taille.y))
	add_child(_sprite)


func _texture() -> Texture2D:
	if crochet:
		return Textures.charger("crochet")
	# `masse_50g` d'abord, `masse` ensuite : le fichier dedie gagne.
	var noms: Array[String] = ["masse_%dg" % int(round(masse_g)), "masse"]
	return Textures.premiere(noms)


func _draw() -> void:
	if _sprite != null:
		_teinter()
		return

	var couleur: Color = TRAIT
	if prete:
		couleur = PRETE
	elif saisie:
		couleur = SAISIE

	if crochet:
		# Un S ouvert : la partie basse reste libre, c'est la qu'on accroche.
		draw_arc(Vector2(0.0, -rayon * 0.45), rayon * 0.55, PI, TAU, 20, couleur, 1.25)
		draw_arc(Vector2(0.0, rayon * 0.35), rayon * 0.62, -PI * 0.85, PI * 0.85, 24, couleur, 1.25)
		return

	draw_circle(Vector2.ZERO, rayon, FOND)
	draw_arc(Vector2.ZERO, rayon, 0.0, TAU, 40, couleur, 1.0)
	draw_arc(Vector2.ZERO, rayon * 0.42, 0.0, TAU, 24, TRAIT_EFFACE, 0.5)

	# La fente laterale des poids fendus : c'est elle qui rend la rotation lisible
	# quand la masse roule.
	draw_line(Vector2(0.0, -rayon * 0.42), Vector2(0.0, -rayon), TRAIT_EFFACE, 0.5)

	# L'anneau de suspension, en haut.
	draw_arc(Vector2(0.0, -rayon), 3.5, PI, TAU, 16, couleur, 1.0)


## Le retour d'etat marche aussi sur une texture : on la teinte au lieu de
## changer la couleur du trait.
func _teinter() -> void:
	if prete:
		_sprite.modulate = PRETE
	elif saisie:
		_sprite.modulate = SAISIE
	else:
		_sprite.modulate = Color.WHITE
