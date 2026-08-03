# Le visuel de la loupe : la COUCHE VISIBLE, remplacable.
#
# Le disque est un polygone dont les UV echantillonnent le rendu grossi : c'est
# lui qui rend la scene, et il n'est pas remplacable — c'est la loupe. La monture
# et le manche, eux, le sont : `textures/loupe.png` se pose par-dessus le verre.
extends Node2D

const Textures: GDScript = preload("res://src/atelier/textures.gd")

const MONTURE: Color = Color(0.94, 0.97, 1.0, 0.85)
const MANCHE: Color = Color(0.90, 0.94, 0.97, 0.55)
const SURVOL: Color = Color("ffb454")
const VISEE: Color = Color(0.94, 0.97, 1.0, 0.35)

const COTES: int = 56

var vue: SubViewport = null
var rayon: float = 39.0
var manche: float = 46.0
var tenue: bool = false
var survolee: bool = false

var _sprite: Sprite2D = null


func _ready() -> void:
	var texture: Texture2D = Textures.charger("loupe")
	if texture == null:
		return
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.centered = true
	var taille: Vector2 = texture.get_size()
	if taille.x > 0.0:
		_sprite.scale = Vector2.ONE * (rayon * 2.0 / taille.x)
	# Par-dessus le verre : la monture cadre l'image, elle ne la cache pas.
	_sprite.z_index = 1
	_sprite.visibility_layer = visibility_layer
	add_child(_sprite)


func _draw() -> void:
	if vue == null:
		return
	var couleur: Color = SURVOL if (tenue or survolee) else MONTURE

	# Le manche, dans le prolongement bas-droite. Sous le verre : c'est le disque
	# qui passe devant, pas l'inverse.
	if _sprite == null:
		var bout: Vector2 = Vector2.from_angle(PI * 0.28) * (rayon + manche)
		draw_line(Vector2.ZERO, bout, MANCHE, 2.5)
		draw_circle(bout, 3.5, MANCHE)

	# Le disque : un polygone dont les UV echantillonnent le rendu grossi.
	var contour: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	for i: int in COTES:
		var angle: float = TAU * float(i) / float(COTES)
		var point: Vector2 = Vector2.from_angle(angle) * rayon
		contour.append(point)
		# Le SubViewport couvre exactement le disque : un point local p tombe au
		# pixel (rayon + p), donc en UV (0.5 + p / (2 * rayon)).
		uvs.append(Vector2(0.5, 0.5) + point / (rayon * 2.0))
	draw_colored_polygon(contour, Color.WHITE, uvs, vue.get_texture())

	if _sprite != null:
		_sprite.modulate = couleur
		return

	draw_arc(Vector2.ZERO, rayon, 0.0, TAU, COTES, couleur, 1.5)
	# Une croisee discrete, pour savoir ou vise exactement le centre.
	draw_line(Vector2(-4.0, 0.0), Vector2(4.0, 0.0), VISEE, 0.5)
	draw_line(Vector2(0.0, -4.0), Vector2(0.0, 4.0), VISEE, 0.5)
