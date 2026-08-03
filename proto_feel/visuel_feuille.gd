# Le visuel de la feuille : la COUCHE VISIBLE, remplacable. Le papier seulement —
# l'encre est une cible de rendu a part (encre.gd), posee par-dessus.
#
# `textures/feuille.png` passe le papier en NinePatchRect : la feuille peut
# changer de format sans que le bord, les punaises ou le grain se deforment. Le
# centre s'etire, les bords non. Sans fichier, on dessine le panneau quadrille.
extends Node2D

const Textures: GDScript = preload("res://textures.gd")

# Un papier doit se voir comme un panneau plus clair que le fond, pas comme un
# voile. Une premiere valeur a 5 % d'alpha etait litteralement invisible.
const PAPIER: Color = Color("15314f")
const BORD: Color = Color(0.90, 0.94, 0.97, 0.38)
const QUADRILLAGE: Color = Color(0.90, 0.94, 0.97, 0.10)
const PUNAISE: Color = Color(0.90, 0.94, 0.97, 0.55)

## Pas du quadrillage, en mm. Du vrai papier millimetre au demi-centimetre.
const PAS_QUADRILLAGE: float = 10.0
## Marge du 9-patch, en pixels de la texture fournie.
const MARGE_PATCH: int = 24

var taille: Vector2 = Vector2(330.0, 235.0)
var attrapee: bool = false

var _patch: NinePatchRect = null


func _ready() -> void:
	# Le papier passe DERRIERE l'encre : les deux sont enfants de la feuille, et
	# seul ce decalage de z les met dans le bon ordre.
	z_index = -1

	var texture: Texture2D = Textures.charger("feuille")
	if texture == null:
		return
	_patch = NinePatchRect.new()
	_patch.texture = texture
	_patch.size = taille
	_patch.patch_margin_left = MARGE_PATCH
	_patch.patch_margin_right = MARGE_PATCH
	_patch.patch_margin_top = MARGE_PATCH
	_patch.patch_margin_bottom = MARGE_PATCH
	_patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_patch)


func _draw() -> void:
	var cadre: Rect2 = Rect2(Vector2.ZERO, taille)
	if _patch != null:
		draw_rect(cadre, BORD, false, 0.75 if attrapee else 0.5)
		return

	draw_rect(cadre, PAPIER, true)
	draw_rect(cadre, BORD, false, 0.75 if attrapee else 0.5)

	# Un quadrillage tres pale : de quoi situer une trace sans rien mesurer.
	var x: float = PAS_QUADRILLAGE
	while x < taille.x:
		draw_line(Vector2(x, 0.0), Vector2(x, taille.y), QUADRILLAGE, 0.5)
		x += PAS_QUADRILLAGE
	var y: float = PAS_QUADRILLAGE
	while y < taille.y:
		draw_line(Vector2(0.0, y), Vector2(taille.x, y), QUADRILLAGE, 0.5)
		y += PAS_QUADRILLAGE

	for coin: Vector2 in [
		Vector2(7.0, 7.0),
		Vector2(taille.x - 7.0, 7.0),
		Vector2(7.0, taille.y - 7.0),
		Vector2(taille.x - 7.0, taille.y - 7.0),
	]:
		draw_arc(coin, 2.25, 0.0, TAU, 14, PUNAISE, 0.75)
