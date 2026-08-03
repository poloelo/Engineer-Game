# Le bon de travail, punaise sur l'etabli. La commande, rien d'autre.
#
# C'est le seul texte du jeu et les seuls chiffres qu'il affiche. Ils sont sur un
# bout de papier dans la scene, pas dans une interface : le joueur les lit comme
# il lirait une etiquette. Rien ici ne dit comment faire, rien ne verifie ce qui
# sort — la balance de l'atelier a un pas de 100 g, elle ne tranchera pas.
extends Node2D

const PAPIER: Color = Color("15314f")
const BORD: Color = Color(0.90, 0.94, 0.97, 0.38)
const ENCRE: Color = Color(0.94, 0.97, 1.0, 0.92)
const EFFACE: Color = Color(0.90, 0.94, 0.97, 0.45)
const PUNAISE: Color = Color(0.90, 0.94, 0.97, 0.55)

const TAILLE: Vector2 = Vector2(120.0, 86.0)
## On grave grand puis on reduit : le texte reste net sous la loupe.
const RASTER: int = 48

## Les trois sachets a produire, en grammes.
const COMMANDE: Array[float] = [56.0, 89.0, 143.0]


func _draw() -> void:
	var police: Font = ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, TAILLE), PAPIER, true)
	draw_rect(Rect2(Vector2.ZERO, TAILLE), BORD, false, 0.6)
	draw_arc(Vector2(TAILLE.x * 0.5, 6.0), 2.5, 0.0, TAU, 14, PUNAISE, 0.8)

	_ecrire(police, "BON DE TRAVAIL", Vector2(9.0, 22.0), 5.0, EFFACE)
	draw_line(Vector2(9.0, 26.0), Vector2(TAILLE.x - 9.0, 26.0), EFFACE, 0.4)

	var y: float = 42.0
	for grammes: float in COMMANDE:
		_ecrire(police, "poudre", Vector2(9.0, y), 6.0, EFFACE)
		_ecrire(police, "%d g" % int(grammes), Vector2(TAILLE.x - 40.0, y), 8.0, ENCRE)
		y += 17.0


## Ecrit un texte dont la hauteur est donnee en mm de monde.
func _ecrire(police: Font, texte: String, ou: Vector2, hauteur: float, teinte: Color) -> void:
	var echelle: float = hauteur / float(RASTER)
	draw_set_transform(ou, 0.0, Vector2.ONE * echelle)
	draw_string(police, Vector2.ZERO, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, RASTER, teinte)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
