# La loupe. Un objet pose sur l'etabli, qu'on attrape et qu'on repose ou on veut.
#
# Posee plutot que collee au curseur : on peut alors travailler a deux mains
# dessous — caler la regle d'une main pendant que la loupe reste sur la marque.
# C'est ce qui la rend utile plutot que decorative.
#
# Elle grossit TOUT ce qui passe dessous, et pas seulement la regle : le papier,
# les traits de stylo, les graduations, la pointe, une masse. Techniquement, un
# SubViewport partage le meme World2D que la scene et le rend a travers une
# camera zoomee ; le disque est un polygone texture par ce rendu. Aucun shader.
extends Node2D

const Reglages: GDScript = preload("res://reglages.gd")

const MONTURE: Color = Color(0.94, 0.97, 1.0, 0.85)
const MANCHE: Color = Color(0.90, 0.94, 0.97, 0.55)
const SURVOL: Color = Color("ffb454")
const VISEE: Color = Color(0.94, 0.97, 1.0, 0.35)

const COTES: int = 56
## Longueur du manche, qui sert aussi de zone de prehension.
const MANCHE_LONGUEUR: float = 92.0

var tenue: bool = false
var survolee: bool = false

var _vue: SubViewport = null
var _camera: Camera2D = null


func _ready() -> void:
	# La loupe ne doit pas se voir elle-meme, sinon le rendu se reboucle sur son
	# image de la frame precedente. On la range sur un calque de visibilite que
	# le SubViewport ignore.
	visibility_layer = 2

	_vue = SubViewport.new()
	_vue.size = Vector2i(int(Reglages.RAYON_LOUPE * 2.0), int(Reglages.RAYON_LOUPE * 2.0))
	_vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vue.transparent_bg = false
	_vue.canvas_cull_mask = 0xFFFFFFFF & ~2
	add_child(_vue)
	# Partager le World2D : le SubViewport rend la scene elle-meme, pas une copie.
	_vue.world_2d = get_viewport().world_2d

	_camera = Camera2D.new()
	_camera.enabled = true
	_vue.add_child(_camera)


func _process(_delta: float) -> void:
	var rayon: float = Reglages.RAYON_LOUPE
	var taille: int = int(rayon * 2.0)
	if _vue.size.x != taille:
		_vue.size = Vector2i(taille, taille)
	_camera.zoom = Vector2.ONE * Reglages.GROSSISSEMENT_LOUPE
	_camera.global_position = global_position
	queue_redraw()


func attraper(ou: Vector2) -> bool:
	var local: Vector2 = to_local(ou)
	# Le disque entier et le manche sont saisissables : pas de zone a viser.
	if local.length() > Reglages.RAYON_LOUPE and local.distance_to(_bout_manche()) > 26.0:
		return false
	tenue = true
	queue_redraw()
	return true


func relacher() -> void:
	tenue = false
	queue_redraw()


func definir_survol(ou: Vector2) -> void:
	var dessus: bool = to_local(ou).length() <= Reglages.RAYON_LOUPE
	if dessus != survolee:
		survolee = dessus
		queue_redraw()


func _draw() -> void:
	var rayon: float = Reglages.RAYON_LOUPE
	var couleur: Color = SURVOL if (tenue or survolee) else MONTURE

	# Le manche, dans le prolongement bas-droite.
	draw_line(Vector2.ZERO, _bout_manche(), MANCHE, 5.0)
	draw_circle(_bout_manche(), 7.0, MANCHE)

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
	draw_colored_polygon(contour, Color.WHITE, uvs, _vue.get_texture())

	draw_arc(Vector2.ZERO, rayon, 0.0, TAU, COTES, couleur, 3.0)
	# Une croisee discrete, pour savoir ou vise exactement le centre.
	draw_line(Vector2(-8.0, 0.0), Vector2(8.0, 0.0), VISEE, 1.0)
	draw_line(Vector2(0.0, -8.0), Vector2(0.0, 8.0), VISEE, 1.0)


func _bout_manche() -> Vector2:
	return Vector2.from_angle(PI * 0.28) * (Reglages.RAYON_LOUPE + MANCHE_LONGUEUR)
