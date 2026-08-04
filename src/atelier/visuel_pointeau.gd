# Le visuel du pointeau : la COUCHE VISIBLE, remplacable.
#
# Les deux zones doivent se distinguer d'un coup d'oeil, sans avoir a cliquer
# pour savoir : la tete est un bouton rond, moletee, nettement detachee du corps.
# Le survol allume celle qui repondrait.
extends Node2D

const Textures: GDScript = preload("res://src/atelier/textures.gd")

const CORPS: Color = Color("e6f0f8")
const TETE: Color = Color(0.90, 0.94, 0.97, 0.62)
const POINTE: Color = Color("ffd9a0")
const SURVOL: Color = Color("ffb454")
const CLIP: Color = Color("ffb454")

var longueur: float = 34.0
var largeur: float = 6.0
var rayon_tete: float = 7.0
var enfoncement: float = 0.0
## Une valeur de Pointeau.Prise : ce que ferait un clic ici.
var survol: int = 0
var vise: bool = false
var clipse: bool = false

var _sprite: Sprite2D = null


func _ready() -> void:
	var texture: Texture2D = Textures.charger("pointeau")
	if texture == null:
		return
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.centered = true
	var taille: Vector2 = texture.get_size()
	if taille.x > 0.0:
		_sprite.scale = Vector2.ONE * (longueur / taille.x)
	add_child(_sprite)


func _draw() -> void:
	var demi: float = longueur * 0.5
	var centre_tete: Vector2 = Vector2(-demi - rayon_tete * 0.5 + enfoncement, 0.0)

	if _sprite != null:
		_sprite.modulate = SURVOL if vise else CORPS
	else:
		# Le fut, du corps vers la pointe : un coin qui s'affine.
		var couleur_corps: Color = SURVOL if survol == 1 else (CLIP if vise else CORPS)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-demi + enfoncement, -largeur * 0.5),
				Vector2(demi * 0.55, -largeur * 0.5),
				Vector2(demi, -0.7),
				Vector2(demi, 0.7),
				Vector2(demi * 0.55, largeur * 0.5),
				Vector2(-demi + enfoncement, largeur * 0.5),
			]),
			Color("0d243d")
		)
		draw_polyline(
			PackedVector2Array([
				Vector2(-demi + enfoncement, -largeur * 0.5),
				Vector2(demi * 0.55, -largeur * 0.5),
				Vector2(demi, -0.7),
				Vector2(demi, 0.7),
				Vector2(demi * 0.55, largeur * 0.5),
				Vector2(-demi + enfoncement, largeur * 0.5),
				Vector2(-demi + enfoncement, -largeur * 0.5),
			]),
			couleur_corps,
			0.9
		)
		# La bague qui separe le corps de la pointe : on vise ce bord.
		draw_line(
			Vector2(demi * 0.55, -largeur * 0.5),
			Vector2(demi * 0.55, largeur * 0.5),
			couleur_corps,
			0.8
		)

	# La tete de frappe : un bouton rond, molete, nettement detache du corps.
	# C'est elle qu'on tape, et elle ne ressemble a rien d'autre sur l'etabli.
	var couleur_tete: Color = SURVOL if survol == 2 else TETE
	draw_circle(centre_tete, rayon_tete, Color("0d243d"))
	draw_arc(centre_tete, rayon_tete, 0.0, TAU, 24, couleur_tete, 1.2)
	for i: int in 8:
		var angle: float = TAU * float(i) / 8.0
		var direction: Vector2 = Vector2.from_angle(angle)
		draw_line(
			centre_tete + direction * (rayon_tete * 0.62),
			centre_tete + direction * (rayon_tete * 0.96),
			couleur_tete,
			0.6
		)
	# La tige entre la tete et le corps, qui montre la course.
	draw_line(centre_tete, Vector2(-demi + enfoncement, 0.0), couleur_tete, 1.0)

	# La pointe, en couleur d'encre : c'est elle qui marque.
	draw_circle(Vector2(demi, 0.0), 1.1, POINTE)

	if clipse:
		draw_arc(Vector2(0.0, 0.0), largeur * 1.1, 0.0, TAU, 18, CLIP, 0.7)
