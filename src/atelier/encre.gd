# Une face de papier : une cible de rendu qui ne s'efface jamais.
#
# Le principe tient en deux reglages de SubViewport :
#   - CLEAR_MODE_NEVER : la cible garde ce qui y a deja ete dessine,
#   - UPDATE_ONCE a la demande : on ne rend une frame que quand il y a un
#     nouveau bout de trait a deposer.
#
# Le noeud interieur ne dessine donc que le segment qui vient d'arriver, une
# seule fois, et il reste. Une trace d'une heure ne coute pas une frame de plus
# qu'une trace vide. C'est aussi ce qui rend l'export trivial : la texture EST
# l'image.
extends Node2D

## Epaisseur du trait, en mm. Une pointe fine.
const EPAISSEUR_MM: float = 0.8


## Le noeud qui depose l'encre. Il vit dans la cible de rendu et ne dessine que
## ce qui est en attente : une fois pose, ce n'est plus son affaire.
class Trait:
	extends Node2D

	const COULEUR: Color = Color("ffd9a0")

	var epaisseur: float = 5.0
	var en_attente: Array[PackedVector2Array] = []

	func _draw() -> void:
		for segment: PackedVector2Array in en_attente:
			if segment.size() == 1:
				# Un point unique : une marque, pas un trait.
				draw_circle(segment[0], epaisseur * 0.6, COULEUR, true, -1.0, true)
			else:
				draw_polyline(segment, COULEUR, epaisseur, true)
		en_attente.clear()


var taille_mm: Vector2 = Vector2(330.0, 235.0)
## Finesse de la cible, en pixels de texture par mm de papier.
var resolution: float = 6.0

var _vue: SubViewport = null
var _trait: Trait = null
var _sprite: Sprite2D = null
## Dernier point pose, en mm locaux. INF quand la pointe est levee.
var _dernier: Vector2 = Vector2.INF
## Frames restantes avant de repasser la cible en « ne jamais effacer ».
var _nettoyage: int = 0


func _ready() -> void:
	_vue = SubViewport.new()
	_vue.size = Vector2i(int(taille_mm.x * resolution), int(taille_mm.y * resolution))
	_vue.transparent_bg = true
	_vue.disable_3d = true
	_vue.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	_vue.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vue)

	_trait = Trait.new()
	_trait.epaisseur = EPAISSEUR_MM * resolution
	_vue.add_child(_trait)

	_sprite = Sprite2D.new()
	_sprite.texture = _vue.get_texture()
	_sprite.centered = false
	_sprite.scale = Vector2.ONE / resolution
	add_child(_sprite)

	# Le papier vierge : un nettoyage unique, sinon la cible demarre sur du bruit.
	effacer()


func _process(_delta: float) -> void:
	if _nettoyage <= 0:
		return
	_nettoyage -= 1
	if _nettoyage == 0:
		_vue.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER


## Depose un point sous la pointe. Rend vrai si l'encre a effectivement coule —
## faux quand la pointe n'a pas assez bouge depuis le dernier point.
func poser(local_mm: Vector2, pas: float) -> bool:
	if _dernier != Vector2.INF and _dernier.distance_to(local_mm) < pas:
		return false

	var segment: PackedVector2Array = PackedVector2Array()
	if _dernier != Vector2.INF:
		segment.append(_dernier * resolution)
	segment.append(local_mm * resolution)
	_trait.en_attente.append(segment)
	_dernier = local_mm

	_trait.queue_redraw()
	_vue.render_target_update_mode = SubViewport.UPDATE_ONCE
	return true


## La pointe se leve : le trait suivant repartira ailleurs, sans relier les deux.
func lever() -> void:
	_dernier = Vector2.INF


func effacer() -> void:
	_dernier = Vector2.INF
	_trait.en_attente.clear()
	_trait.queue_redraw()
	_vue.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	_vue.render_target_update_mode = SubViewport.UPDATE_ONCE
	# Le mode de nettoyage doit revenir a NEVER une fois la frame passee : sans ce
	# retour, la face s'effacerait a chaque depot suivant.
	_nettoyage = 2


func texture() -> Texture2D:
	return _vue.get_texture()


func image() -> Image:
	return _vue.get_texture().get_image()
