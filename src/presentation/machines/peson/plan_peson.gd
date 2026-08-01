## Le plan du peson : un ressort, un crochet, une regle graduee au millimetre.
##
## Dessine entierement au trait, comme un plan technique. C'est la seule partie
## specifique a cette machine — et elle ne fait que du dessin : aucune physique
## n'est calculee ici, tout vient de la simulation.
##
## La regle est graduee au millimetre parce que c'est la resolution reelle de
## l'instrument. Le joueur voit qu'il ne peut pas lire plus fin ; c'est le
## tutoriel, et il n'y a rien a expliquer.
class_name PlanPeson
extends Control

const ECHELLE: float = 2.2
const HAUTEUR_POTENCE: float = 40.0
const SPIRES: int = 14
const LARGEUR_RESSORT: float = 13.0
const LARGEUR_MASSE: float = 46.0

var _longueur: float = 0.0
var _masse: float = 0.0
var _charge: bool = false


## Etat courant du montage, tel que la simulation vient de le rendre.
func afficher_mesure(longueur_mm: float, masse: float) -> void:
	_longueur = longueur_mm
	_masse = masse
	_charge = true
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThemeBlueprint.FOND, true)
	if not _charge:
		return

	var origine: Vector2 = Vector2(size.x * 0.62, HAUTEUR_POTENCE)
	var bas: Vector2 = origine + Vector2(0.0, _longueur * ECHELLE)

	_dessiner_potence(origine)
	_dessiner_regle(origine)
	_dessiner_ressort(origine, bas)
	_dessiner_crochet_et_masse(bas)
	_dessiner_cote(origine, bas)


func _dessiner_potence(origine: Vector2) -> void:
	draw_line(
		Vector2(origine.x - 70.0, origine.y),
		Vector2(origine.x + 40.0, origine.y),
		ThemeBlueprint.TRAIT,
		ThemeBlueprint.TRAIT_EPAIS
	)
	# Hachures de scellement, convention de plan.
	for i: int in 8:
		var x: float = origine.x - 66.0 + float(i) * 13.0
		draw_line(
			Vector2(x, origine.y),
			Vector2(x - 9.0, origine.y - 11.0),
			ThemeBlueprint.TRAIT_EFFACE,
			ThemeBlueprint.TRAIT_FIN
		)


func _dessiner_regle(origine: Vector2) -> void:
	var police: Font = ThemeBlueprint.police()
	var x: float = origine.x - 58.0
	var hauteur: float = size.y - origine.y - 20.0
	draw_line(
		Vector2(x, origine.y), Vector2(x, origine.y + hauteur), ThemeBlueprint.TRAIT, ThemeBlueprint.TRAIT_NORMAL
	)

	var millimetres: int = int(hauteur / ECHELLE)
	for mm: int in millimetres + 1:
		var y: float = origine.y + float(mm) * ECHELLE
		var decimetre: bool = mm % 10 == 0
		draw_line(
			Vector2(x, y),
			Vector2(x + (10.0 if decimetre else 4.0), y),
			ThemeBlueprint.TRAIT_EFFACE if decimetre else ThemeBlueprint.TRAIT_TRES_EFFACE,
			ThemeBlueprint.TRAIT_FIN
		)
		if decimetre and mm % 20 == 0:
			draw_string(
				police,
				Vector2(x - 34.0, y + 5.0),
				str(mm),
				HORIZONTAL_ALIGNMENT_RIGHT,
				28.0,
				ThemeBlueprint.POLICE_PETITE,
				ThemeBlueprint.TRAIT_EFFACE
			)


func _dessiner_ressort(origine: Vector2, bas: Vector2) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	points.append(origine)
	var utile: float = bas.y - origine.y
	for i: int in SPIRES + 1:
		var t: float = float(i) / float(SPIRES)
		var cote: float = LARGEUR_RESSORT * (1.0 if i % 2 == 0 else -1.0)
		points.append(Vector2(origine.x + cote, origine.y + utile * t))
	points.append(bas)
	draw_polyline(points, ThemeBlueprint.RELEVE, ThemeBlueprint.TRAIT_NORMAL)


func _dessiner_crochet_et_masse(bas: Vector2) -> void:
	draw_arc(
		bas + Vector2(0.0, 7.0), 7.0, PI, TAU + PI * 0.4, 20, ThemeBlueprint.TRAIT, ThemeBlueprint.TRAIT_NORMAL
	)
	var haut_masse: float = bas.y + 16.0
	var hauteur: float = 20.0 + minf(_masse, 500.0) * 0.045
	draw_rect(
		Rect2(bas.x - LARGEUR_MASSE * 0.5, haut_masse, LARGEUR_MASSE, hauteur),
		ThemeBlueprint.TRAIT_EFFACE,
		false,
		ThemeBlueprint.TRAIT_NORMAL
	)
	draw_string(
		ThemeBlueprint.police(),
		Vector2(bas.x - LARGEUR_MASSE * 0.5, haut_masse + hauteur * 0.5 + 5.0),
		"%s g" % String.num(_masse, 0),
		HORIZONTAL_ALIGNMENT_CENTER,
		LARGEUR_MASSE,
		ThemeBlueprint.POLICE_PETITE,
		ThemeBlueprint.TRAIT
	)


## La cote de la lecture, ecrite comme sur un plan : la valeur que le joueur relit.
func _dessiner_cote(origine: Vector2, bas: Vector2) -> void:
	var x: float = origine.x + 46.0
	draw_line(Vector2(x, origine.y), Vector2(x, bas.y), ThemeBlueprint.MODELE, ThemeBlueprint.TRAIT_FIN)
	for y: float in [origine.y, bas.y]:
		draw_line(Vector2(x - 5.0, y), Vector2(x + 5.0, y), ThemeBlueprint.MODELE, ThemeBlueprint.TRAIT_FIN)
	draw_string(
		ThemeBlueprint.police(),
		Vector2(x + 10.0, (origine.y + bas.y) * 0.5 + 5.0),
		"%s mm" % String.num(_longueur, 0),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ThemeBlueprint.POLICE_NORMALE,
		ThemeBlueprint.MODELE
	)
