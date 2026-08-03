# Le visuel du stylo : la COUCHE VISIBLE, remplacable.
#
# `textures/stylo.png` le remplace par un sprite cadre sur la longueur du corps.
# La pointe reste ou le Marker2D la place : la texture habille, elle ne decide de
# rien.
extends Node2D

const Textures: GDScript = preload("res://src/atelier/textures.gd")

const CORPS: Color = Color("e6f0f8")
const ENCRE: Color = Color("ffd9a0")
const VISE: Color = Color("ffb454")
const LEVE: Color = Color(0.90, 0.94, 0.97, 0.35)

var longueur: float = 29.0
var largeur: float = 4.5
var course: float = 4.5
var pointe_baissee: bool = false
var vise: bool = false
var support: Node2D = null

var _sprite: Sprite2D = null


func _ready() -> void:
	var texture: Texture2D = Textures.charger("stylo")
	if texture == null:
		return
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.centered = true
	var taille: Vector2 = texture.get_size()
	if taille.y > 0.0:
		_sprite.scale = Vector2.ONE * (longueur / taille.y)
	add_child(_sprite)


func _draw() -> void:
	var couleur: Color = VISE if vise else CORPS
	var demi: float = longueur * 0.5
	var sortie: float = course if pointe_baissee else 0.0

	if _sprite != null:
		_sprite.modulate = couleur
	else:
		# Le corps, un simple rectangle incline de rien du tout.
		draw_rect(
			Rect2(Vector2(-largeur * 0.5, -demi), Vector2(largeur, longueur * 0.78)),
			couleur,
			false,
			0.9
		)
		# La bague, qui marque la separation corps / pointe.
		draw_line(
			Vector2(-largeur * 0.7, demi * 0.56),
			Vector2(largeur * 0.7, demi * 0.56),
			couleur,
			1.0
		)

	# Le cone de la pointe sort quand elle est baissee : il se dessine meme sous
	# texture, parce que c'est le seul retour de l'etat « ca trace ou non ».
	var bout: Vector2 = Vector2(0.0, demi + sortie)
	draw_polyline(
		PackedVector2Array([
			Vector2(-largeur * 0.5, demi * 0.56),
			bout,
			Vector2(largeur * 0.5, demi * 0.56),
		]),
		ENCRE if pointe_baissee else LEVE,
		0.9
	)
	if pointe_baissee:
		draw_circle(bout, 1.2, ENCRE)

	# Le clip, qui montre a quoi il est attache.
	if support != null and is_instance_valid(support):
		draw_arc(Vector2(0.0, -demi + 3.0), 3.5, 0.0, TAU, 16, VISE, 0.8)
		draw_line(Vector2.ZERO, to_local(support.global_position), VISE.darkened(0.4), 0.5)
