# La loupe : la COUCHE FORME. Un objet pose sur l'etabli, qu'on attrape et qu'on
# repose ou on veut.
#
# Posee plutot que collee au curseur : on peut alors travailler a deux mains
# dessous — caler la regle d'une main pendant que la loupe reste sur la marque.
# C'est ce qui la rend utile plutot que decorative.
#
# Elle grossit TOUT ce qui passe dessous, sans exception ni traitement special :
# le papier, les traits de stylo, les graduations, la pointe du stylo, une masse
# qui passe derriere. Techniquement, un SubViewport partage le meme World2D que
# la scene et le refilme a travers une camera zoomee. Il n'y a aucun cas
# particulier a ecrire pour qu'un objet soit grossi : il suffit qu'il existe.
#
# La taille de la cible de rendu suit l'echelle reelle a l'ecran, pas une
# constante en pixels : en 4K la loupe rend quatre fois plus de pixels et reste
# aussi nette qu'en 1152 x 648.
extends Node2D

const Reglages: GDScript = preload("res://reglages.gd")
const VisuelLoupe: GDScript = preload("res://visuel_loupe.gd")

## Longueur du manche, en mm, qui sert aussi de zone de prehension.
const MANCHE_LONGUEUR: float = 46.0

var tenue: bool = false
var survolee: bool = false

var _vue: SubViewport = null
var _camera: Camera2D = null
var _visuel: Node2D = null


func _ready() -> void:
	# La loupe ne doit pas se voir elle-meme, sinon le rendu se reboucle sur son
	# image de la frame precedente. On la range sur un calque de visibilite que
	# le SubViewport ignore.
	visibility_layer = 2

	_vue = SubViewport.new()
	_vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vue.transparent_bg = false
	_vue.disable_3d = true
	_vue.canvas_cull_mask = 0xFFFFFFFF & ~2
	add_child(_vue)
	# Partager le World2D : le SubViewport rend la scene elle-meme, pas une copie.
	_vue.world_2d = get_viewport().world_2d

	_camera = Camera2D.new()
	_camera.enabled = true
	_vue.add_child(_camera)

	_visuel = VisuelLoupe.new()
	_visuel.visibility_layer = 2
	_visuel.vue = _vue
	_visuel.manche = MANCHE_LONGUEUR
	add_child(_visuel)


func _process(_delta: float) -> void:
	# Echelle reelle monde -> ecran : elle contient le zoom de la camera ET
	# l'etirement du projet. C'est le seul endroit du fichier ou un pixel existe,
	# et c'est bien une question de rendu.
	var echelle: float = get_viewport_transform().get_scale().x
	var cote: int = maxi(int(Reglages.RAYON_LOUPE * 2.0 * echelle), 8)
	if _vue.size.x != cote:
		_vue.size = Vector2i(cote, cote)
	_camera.zoom = Vector2.ONE * echelle * Reglages.GROSSISSEMENT_LOUPE
	_camera.global_position = global_position
	_visuel.rayon = Reglages.RAYON_LOUPE
	_visuel.queue_redraw()


func attraper(ou: Vector2) -> bool:
	var local: Vector2 = to_local(ou)
	# Le disque entier et le manche sont saisissables : pas de zone a viser.
	if local.length() > Reglages.RAYON_LOUPE and local.distance_to(_bout_manche()) > 13.0:
		return false
	tenue = true
	_visuel.tenue = true
	return true


func relacher() -> void:
	tenue = false
	_visuel.tenue = false


func definir_survol(ou: Vector2) -> void:
	var dessus: bool = to_local(ou).length() <= Reglages.RAYON_LOUPE
	if dessus != survolee:
		survolee = dessus
		_visuel.survolee = dessus


func _bout_manche() -> Vector2:
	return Vector2.from_angle(PI * 0.28) * (Reglages.RAYON_LOUPE + MANCHE_LONGUEUR)
