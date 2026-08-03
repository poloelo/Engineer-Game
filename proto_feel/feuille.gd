# La feuille punaisee sur l'etabli, derriere le ressort : la COUCHE FORME.
#
# L'encre n'est plus une liste de segments redessines a chaque frame. La feuille
# porte une CIBLE DE RENDU (SubViewport) qui ne s'efface jamais : le stylo y
# depose son trait une fois, et le trait y reste. Le papier est une texture sur
# laquelle on dessine, comme du vrai papier.
#
# Ce que ca resout d'un coup :
#   - la persistance : aucun cout par frame, une trace d'une heure ne coute rien,
#   - ranger une feuille et la ressortir plus tard : la texture survit,
#   - l'export en PNG : la texture EST l'image, `exporter_png()` la pose sur le
#     disque telle quelle.
#
# Deux faces, deux cibles de rendu : retourner la feuille ne perd pas l'autre
# cote. Les coordonnees sont locales a la feuille — decaler le papier emporte les
# traces avec lui, exactement comme du vrai papier.
#
# On garde a cote une liste decimee des points d'encre. Ce n'est pas un doublon
# du dessin : c'est l'index dont la regle a besoin pour se caler sur une marque,
# et relire des pixels pour ca serait absurde.
extends Node2D

const Reglages: GDScript = preload("res://reglages.gd")
const Marqueurs: GDScript = preload("res://marqueurs.gd")
const Encre: GDScript = preload("res://encre.gd")
const VisuelFeuille: GDScript = preload("res://visuel_feuille.gd")

## Taille du papier, en mm. Un A3 a peu pres.
const TAILLE: Vector2 = Vector2(330.0, 235.0)

## Finesse de la cible de rendu, en pixels par mm. Il en faut plus que
## l'affichage (2 px/mm) pour que la loupe ait quelque chose a grossir.
const RESOLUTION: float = 6.0

var _faces: Array[Node] = []
var _face: int = 0
var _attrapee: bool = false
var _visuel: Node2D = null
## Index des points d'encre par face, en mm locaux, pour l'aimant de la regle.
var _index: Array[PackedVector2Array] = [PackedVector2Array(), PackedVector2Array()]


func _ready() -> void:
	for i: int in 2:
		var face: Node = Encre.new()
		face.taille_mm = TAILLE
		face.resolution = RESOLUTION
		add_child(face)
		_faces.append(face)

	_visuel = VisuelFeuille.new()
	_visuel.taille = TAILLE
	add_child(_visuel)
	_montrer_face()

	Marqueurs.poser(self, "coin_zero", Vector2.ZERO, Marqueurs.REPERE)


func rect() -> Rect2:
	return Rect2(Vector2.ZERO, TAILLE)


func attraper(ou: Vector2) -> bool:
	if not rect().has_point(to_local(ou)):
		return false
	_attrapee = true
	_visuel.attrapee = true
	_visuel.queue_redraw()
	return true


func relacher() -> void:
	_attrapee = false
	_visuel.attrapee = false
	_visuel.queue_redraw()


## Depose un point sous la pointe, si elle touche le papier.
func tracer(pointe_monde: Vector2) -> void:
	var local: Vector2 = to_local(pointe_monde)
	if not rect().has_point(local):
		lever()
		return
	if not _faces[_face].poser(local, Reglages.PAS_TRACE):
		return
	_index[_face].append(local)


## La pointe se leve : le trait en cours est clos, le suivant repartira ailleurs.
func lever() -> void:
	_faces[_face].lever()


## Point d'encre le plus proche, en monde, ou Vector2.INF si aucun dans le rayon.
## C'est ce qui permet a la regle de se caler sur une marque sans viser au pixel.
func encre_proche(monde: Vector2, rayon: float) -> Vector2:
	var local: Vector2 = to_local(monde)
	var meilleure: Vector2 = Vector2.INF
	var distance: float = rayon
	for point: Vector2 in _index[_face]:
		var ecart: float = local.distance_to(point)
		if ecart < distance:
			distance = ecart
			meilleure = point
	return Vector2.INF if meilleure == Vector2.INF else to_global(meilleure)


func retourner() -> void:
	lever()
	_face = 1 - _face
	_montrer_face()


## Effacer la face courante : la cible de rendu est nettoyee une fois, l'index
## avec.
func effacer_face() -> void:
	_faces[_face].effacer()
	_index[_face] = PackedVector2Array()


## Prendre une feuille vierge : les deux faces repartent a blanc.
func nouvelle_feuille() -> void:
	for i: int in _faces.size():
		_faces[i].effacer()
		_index[i] = PackedVector2Array()
	_face = 0
	_montrer_face()


## La texture de la face courante, telle qu'on la verrait posee sur la table.
func texture() -> Texture2D:
	return _faces[_face].texture()


## Pose la face courante sur le disque. Rend le chemin ecrit, ou "" en cas
## d'echec.
func exporter_png(chemin: String = "") -> String:
	var vers: String = chemin
	if vers.is_empty():
		vers = "user://feuille_%d_%s.png" % [_face, Time.get_datetime_string_from_system(false, true).replace(":", "-")]
	var image: Image = _faces[_face].image()
	if image == null:
		return ""
	if image.save_png(vers) != OK:
		return ""
	return ProjectSettings.globalize_path(vers)


func _montrer_face() -> void:
	for i: int in _faces.size():
		(_faces[i] as Node2D).visible = i == _face
	_visuel.queue_redraw()
