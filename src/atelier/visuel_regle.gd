# Le visuel de la regle : la COUCHE VISIBLE, remplacable.
#
# `textures/regle.png` la passe en NinePatchRect. Les bords — le zero grave, le
# bout — ne se deforment pas ; le centre se repete au lieu de s'etirer, sinon la
# graduation mentirait des qu'on changerait la longueur de la regle. C'est
# exactement pour ca que le mode de repetition est TILE et pas STRETCH.
#
# Sans texture, on grave les traits a la main. Les chiffres sont les seuls du
# prototype : ils sont sur l'instrument, pas dans l'interface, et c'est au joueur
# de les lire a l'oeil, sous la loupe.
extends Node2D

const Textures: GDScript = preload("res://src/atelier/textures.gd")

const CORPS: Color = Color(0.72, 0.84, 0.95, 0.09)
const ARETE: Color = Color(0.94, 0.97, 1.0, 0.95)
const BORD: Color = Color(0.90, 0.94, 0.97, 0.30)
const GRADUATION: Color = Color(0.94, 0.97, 1.0, 0.88)
const CHIFFRE: Color = Color(0.94, 0.97, 1.0, 0.95)
const ZERO: Color = Color("6fd3ff")
const SURVOL: Color = Color("ffb454")

## Hauteur des chiffres graves, en mm.
const HAUTEUR_CHIFFRE: float = 4.0
## Taille de rasterisation de la police. On grave grand puis on reduit : le
## chiffre reste net sous la loupe, ou un millimetre fait six pixels.
const RASTER: int = 48
## Marge du 9-patch, en pixels de la texture fournie.
const MARGE_PATCH: int = 16

var longueur: float = 200.0
var largeur: float = 22.0
var pas: float = 1.0
var rayon_molette: float = 9.5
var recul_molette: float = 11.0
## Une valeur de Regle.Prise : ce que le curseur ferait s'il cliquait.
## 1 = deplacer, 2 = faire pivoter.
var etat: int = 0
var accroche: Vector2 = Vector2.INF
## Vrai quand la regle est calee pile sur un quart de tour.
var droite: bool = false

var _patch: NinePatchRect = null


func _ready() -> void:
	var texture: Texture2D = Textures.charger("regle")
	if texture == null:
		return
	_patch = NinePatchRect.new()
	_patch.texture = texture
	_patch.size = Vector2(longueur, largeur)
	_patch.patch_margin_left = MARGE_PATCH
	_patch.patch_margin_right = MARGE_PATCH
	_patch.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	_patch.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	_patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_patch)


func _draw() -> void:
	if _patch == null:
		# Le corps, translucide : les traces de stylo doivent rester lisibles
		# dessous.
		draw_rect(Rect2(Vector2.ZERO, Vector2(longueur, largeur)), CORPS, true)
		draw_line(Vector2(0.0, largeur), Vector2(longueur, largeur), BORD, 0.5)

		# L'arete de mesure : un trait franc, c'est elle qu'on vise.
		draw_line(
			Vector2.ZERO,
			Vector2(longueur, 0.0),
			SURVOL if etat == 1 else ARETE,
			1.0
		)
		_dessiner_graduations()
		_dessiner_zero()

	_dessiner_molette()
	_dessiner_prehension()

	if accroche != Vector2.INF:
		draw_set_transform_matrix(get_global_transform().affine_inverse())
		draw_arc(accroche, 4.5, 0.0, TAU, 20, SURVOL, 1.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)


## Un trait par millimetre, plus long tous les cinq, chiffre tous les dix.
##
## Le chiffre grave est le centimetre, comme sur toutes les regles du monde : a
## 2 px/mm, vingt nombres a trois chiffres se chevaucheraient et deviendraient
## illisibles. Ce n'est pas une entorse a l'honnetete de l'instrument — le PAS
## est le millimetre, et c'est lui qui mesure.
func _dessiner_graduations() -> void:
	var police: Font = ThemeDB.fallback_font
	var total: int = int(longueur / pas)
	for i: int in total + 1:
		var x: float = float(i) * pas
		var chiffree: bool = i % 10 == 0
		var longue: bool = i % 5 == 0
		var hauteur: float = 8.0 if chiffree else (5.0 if longue else 2.5)
		draw_line(Vector2(x, 0.0), Vector2(x, hauteur), GRADUATION, 0.4)
		if chiffree and i > 0:
			_graver(police, str(i / 10), x, hauteur + HAUTEUR_CHIFFRE + 1.5)


## Grave un nombre centre sur [param centre_x], en unites monde.
func _graver(police: Font, texte: String, centre_x: float, base_y: float) -> void:
	var echelle: float = HAUTEUR_CHIFFRE / float(RASTER)
	var largeur_texte: float = police.get_string_size(
		texte, HORIZONTAL_ALIGNMENT_LEFT, -1, RASTER
	).x
	draw_set_transform(
		Vector2(centre_x - largeur_texte * echelle * 0.5, base_y), 0.0, Vector2.ONE * echelle
	)
	draw_string(police, Vector2.ZERO, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, RASTER, CHIFFRE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Le zero doit se reperer d'un coup d'oeil : c'est lui qu'on cale sur une marque.
func _dessiner_zero() -> void:
	draw_line(Vector2.ZERO, Vector2(0.0, largeur), ZERO, 1.0)
	draw_colored_polygon(
		PackedVector2Array([Vector2(0.0, 0.0), Vector2(-3.0, -5.5), Vector2(3.0, -5.5)]), ZERO
	)


## La molette de rotation. Ronde, moletee, posee hors du corps : elle ne
## ressemble a aucune autre partie de la regle, donc on ne se trompe pas de zone.
func _dessiner_molette() -> void:
	var centre: Vector2 = Vector2(longueur + recul_molette, largeur * 0.5)
	var couleur: Color = SURVOL if etat == 2 else BORD
	draw_line(Vector2(longueur, largeur * 0.5), centre, couleur, 1.0)
	draw_circle(centre, rayon_molette, CORPS)
	draw_arc(centre, rayon_molette, 0.0, TAU, 26, couleur, 1.1)
	for i: int in 10:
		var angle: float = TAU * float(i) / 10.0
		var direction: Vector2 = Vector2.from_angle(angle)
		draw_line(
			centre + direction * (rayon_molette * 0.55),
			centre + direction * (rayon_molette * 0.95),
			couleur,
			0.55
		)
	# Un point plein au centre quand la regle est calee droite : on voit d'un
	# coup d'oeil qu'on est pile sur l'horizontale ou la verticale.
	if droite:
		draw_circle(centre, rayon_molette * 0.3, SURVOL if etat == 2 else ZERO)


## Le retour de survol dit lequel des deux gestes va se produire.
func _dessiner_prehension() -> void:
	if etat != 1:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(longueur, largeur)), SURVOL, false, 0.75)
