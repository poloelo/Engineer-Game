## Le graphe : chaque releve du joueur y depose un point, son modele s'y trace en
## surimpression, et le banc y revele la machine reelle.
##
## Composant autonome et ignorant : il ne connait aucune machine, aucune loi,
## aucune simulation. Il recoit des [Vector2] et des libelles d'axes, rien
## d'autre. Toute machine du jeu le reutilise tel quel.
##
## Tout est dessine dans [method _draw] : le fond, la grille, les graduations et
## les courbes. Aucun asset.
class_name Graphe
extends Control

## Nombre de graduations visees par axe. Le pas reel est arrondi a une valeur
## lisible (1, 2 ou 5 fois une puissance de dix).
const GRADUATIONS_VISEES: int = 6

## Marge relative ajoutee autour des donnees pour qu'aucun point ne colle au bord.
const RESPIRATION: float = 0.08

var _releves: PackedVector2Array = PackedVector2Array()
var _modele: PackedVector2Array = PackedVector2Array()
var _reelle: PackedVector2Array = PackedVector2Array()

var _libelle_x: String = ""
var _libelle_y: String = ""

## Bornes figees par la machine. Vides tant qu'elles ne le sont pas : le graphe
## se cadre alors tout seul sur ce qu'il contient.
var _bornes_imposees: Rect2 = Rect2()
var _cadrage_impose: bool = false


func _ready() -> void:
	resized.connect(queue_redraw)


# --- API publique ------------------------------------------------------------

## Nomme les axes. Appele une fois par la machine, avec ses grandeurs et unites.
func configurer(libelle_x: String, libelle_y: String) -> void:
	_libelle_x = libelle_x
	_libelle_y = libelle_y
	queue_redraw()


## Fige la plage visible. Sans cela le cadrage suit les donnees, ce qui fait
## sauter le graphe a chaque nouveau releve.
func imposer_cadrage(x_min: float, x_max: float, y_min: float, y_max: float) -> void:
	_bornes_imposees = Rect2(x_min, y_min, x_max - x_min, y_max - y_min)
	_cadrage_impose = true
	queue_redraw()


## Depose un releve. C'est le geste central du jeu : mesurer ajoute un point.
func ajouter_releve(point: Vector2) -> void:
	_releves.append(point)
	queue_redraw()


func definir_releves(points: PackedVector2Array) -> void:
	_releves = points
	queue_redraw()


## Le modele du joueur, trace par-dessus ses releves.
func definir_modele(courbe: PackedVector2Array) -> void:
	_modele = courbe
	queue_redraw()


## La machine reelle. Le banc ne la revele qu'apres une soumission : c'est elle
## qui montre ou le modele decroche.
func definir_courbe_reelle(courbe: PackedVector2Array) -> void:
	_reelle = courbe
	queue_redraw()


func effacer() -> void:
	_releves = PackedVector2Array()
	_modele = PackedVector2Array()
	_reelle = PackedVector2Array()
	queue_redraw()


## Plage horizontale actuellement couverte par les releves, pour que la machine
## sache sur quel intervalle echantillonner les courbes.
func plage_relevee() -> Vector2:
	if _releves.is_empty():
		return Vector2.ZERO
	var mini: float = _releves[0].x
	var maxi: float = _releves[0].x
	for point: Vector2 in _releves:
		mini = minf(mini, point.x)
		maxi = maxf(maxi, point.x)
	return Vector2(mini, maxi)


# --- Dessin ------------------------------------------------------------------


func _draw() -> void:
	var cadre: Rect2 = _cadre()
	draw_rect(Rect2(Vector2.ZERO, size), ThemeBlueprint.FOND, true)
	if cadre.size.x <= 0.0 or cadre.size.y <= 0.0:
		return

	var bornes: Rect2 = _bornes()
	var pas_x: float = _pas_lisible(bornes.size.x)
	var pas_y: float = _pas_lisible(bornes.size.y)

	_dessiner_grille(cadre, bornes, pas_x, pas_y)
	_dessiner_axes(cadre, bornes, pas_x, pas_y)
	_dessiner_courbe(_reelle, cadre, bornes, ThemeBlueprint.REEL, ThemeBlueprint.TRAIT_NORMAL, false)
	_dessiner_courbe(_modele, cadre, bornes, ThemeBlueprint.MODELE, ThemeBlueprint.TRAIT_EPAIS, true)
	_dessiner_releves(cadre, bornes)
	_dessiner_libelles(cadre)


func _dessiner_grille(cadre: Rect2, bornes: Rect2, pas_x: float, pas_y: float) -> void:
	for valeur: float in _graduations(bornes.position.x, bornes.end.x, pas_x):
		var x: float = _vers_pixel(Vector2(valeur, 0.0), cadre, bornes).x
		draw_line(
			Vector2(x, cadre.position.y),
			Vector2(x, cadre.end.y),
			ThemeBlueprint.GRILLE_FINE,
			ThemeBlueprint.TRAIT_FIN
		)
	for valeur: float in _graduations(bornes.position.y, bornes.end.y, pas_y):
		var y: float = _vers_pixel(Vector2(0.0, valeur), cadre, bornes).y
		draw_line(
			Vector2(cadre.position.x, y),
			Vector2(cadre.end.x, y),
			ThemeBlueprint.GRILLE_FINE,
			ThemeBlueprint.TRAIT_FIN
		)


func _dessiner_axes(cadre: Rect2, bornes: Rect2, pas_x: float, pas_y: float) -> void:
	var police: Font = ThemeBlueprint.police()
	draw_rect(cadre, ThemeBlueprint.GRILLE_FORTE, false, ThemeBlueprint.TRAIT_FIN)

	for valeur: float in _graduations(bornes.position.x, bornes.end.x, pas_x):
		var x: float = _vers_pixel(Vector2(valeur, 0.0), cadre, bornes).x
		draw_line(
			Vector2(x, cadre.end.y),
			Vector2(x, cadre.end.y + 5.0),
			ThemeBlueprint.TRAIT_EFFACE,
			ThemeBlueprint.TRAIT_FIN
		)
		var texte: String = _formater(valeur, pas_x)
		var largeur: float = police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeBlueprint.POLICE_PETITE).x
		draw_string(
			police,
			Vector2(x - largeur * 0.5, cadre.end.y + 19.0),
			texte,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			ThemeBlueprint.POLICE_PETITE,
			ThemeBlueprint.TRAIT_EFFACE
		)

	for valeur: float in _graduations(bornes.position.y, bornes.end.y, pas_y):
		var y: float = _vers_pixel(Vector2(0.0, valeur), cadre, bornes).y
		draw_line(
			Vector2(cadre.position.x - 5.0, y),
			Vector2(cadre.position.x, y),
			ThemeBlueprint.TRAIT_EFFACE,
			ThemeBlueprint.TRAIT_FIN
		)
		var texte: String = _formater(valeur, pas_y)
		var largeur: float = police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeBlueprint.POLICE_PETITE).x
		draw_string(
			police,
			Vector2(cadre.position.x - largeur - 9.0, y + 4.0),
			texte,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			ThemeBlueprint.POLICE_PETITE,
			ThemeBlueprint.TRAIT_EFFACE
		)


func _dessiner_courbe(
	courbe: PackedVector2Array,
	cadre: Rect2,
	bornes: Rect2,
	couleur: Color,
	epaisseur: float,
	pointille: bool
) -> void:
	if courbe.size() < 2:
		return
	var precedent: Vector2 = _vers_pixel(courbe[0], cadre, bornes)
	for i: int in range(1, courbe.size()):
		var courant: Vector2 = _vers_pixel(courbe[i], cadre, bornes)
		if pointille:
			draw_dashed_line(precedent, courant, couleur, epaisseur, ThemeBlueprint.LONGUEUR_TIRET)
		else:
			draw_line(precedent, courant, couleur, epaisseur)
		precedent = courant


func _dessiner_releves(cadre: Rect2, bornes: Rect2) -> void:
	for point: Vector2 in _releves:
		var pixel: Vector2 = _vers_pixel(point, cadre, bornes)
		draw_circle(pixel, ThemeBlueprint.RAYON_POINT, ThemeBlueprint.FOND)
		draw_arc(
			pixel,
			ThemeBlueprint.RAYON_POINT,
			0.0,
			TAU,
			24,
			ThemeBlueprint.RELEVE,
			ThemeBlueprint.TRAIT_NORMAL
		)


func _dessiner_libelles(cadre: Rect2) -> void:
	var police: Font = ThemeBlueprint.police()
	if not _libelle_x.is_empty():
		var largeur: float = police.get_string_size(_libelle_x, HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeBlueprint.POLICE_NORMALE).x
		draw_string(
			police,
			Vector2(cadre.position.x + (cadre.size.x - largeur) * 0.5, size.y - 6.0),
			_libelle_x,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			ThemeBlueprint.POLICE_NORMALE,
			ThemeBlueprint.TRAIT
		)
	if not _libelle_y.is_empty():
		# Ecrit verticalement le long de l'axe, comme une cote sur un plan.
		draw_set_transform(Vector2(14.0, cadre.end.y), -PI * 0.5, Vector2.ONE)
		draw_string(
			police,
			Vector2.ZERO,
			_libelle_y,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			ThemeBlueprint.POLICE_NORMALE,
			ThemeBlueprint.TRAIT
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- Geometrie ---------------------------------------------------------------


func _cadre() -> Rect2:
	var gauche: float = ThemeBlueprint.MARGE_GRAPHE
	var bas: float = ThemeBlueprint.MARGE_GRAPHE
	var haut: float = ThemeBlueprint.MARGE
	var droite: float = ThemeBlueprint.MARGE
	return Rect2(
		Vector2(gauche, haut), Vector2(size.x - gauche - droite, size.y - haut - bas)
	)


## Plage de donnees couverte, imposee ou deduite de tout ce que le graphe contient.
func _bornes() -> Rect2:
	if _cadrage_impose:
		return _bornes_imposees

	var mini: Vector2 = Vector2(INF, INF)
	var maxi: Vector2 = Vector2(-INF, -INF)
	for serie: PackedVector2Array in [_releves, _modele, _reelle]:
		for point: Vector2 in serie:
			mini = mini.min(point)
			maxi = maxi.max(point)

	if is_inf(mini.x):
		return Rect2(0.0, 0.0, 1.0, 1.0)

	var etendue: Vector2 = maxi - mini
	# Une serie plate (ou un seul point) n'a pas d'etendue : lui en donner une,
	# sinon la projection divise par zero.
	if etendue.x <= 0.0:
		etendue.x = maxf(absf(mini.x), 1.0)
	if etendue.y <= 0.0:
		etendue.y = maxf(absf(mini.y), 1.0)

	var marge: Vector2 = etendue * RESPIRATION
	return Rect2(mini - marge, etendue + marge * 2.0)


func _vers_pixel(point: Vector2, cadre: Rect2, bornes: Rect2) -> Vector2:
	var u: float = (point.x - bornes.position.x) / bornes.size.x
	var v: float = (point.y - bornes.position.y) / bornes.size.y
	# L'axe des ordonnees pointe vers le haut a l'ecran, l'inverse du pixel.
	return Vector2(cadre.position.x + u * cadre.size.x, cadre.end.y - v * cadre.size.y)


## Pas de graduation lisible : 1, 2 ou 5 fois une puissance de dix.
func _pas_lisible(etendue: float) -> float:
	if etendue <= 0.0:
		return 1.0
	var brut: float = etendue / float(GRADUATIONS_VISEES)
	var puissance: float = pow(10.0, floorf(log(brut) / log(10.0)))
	var normalise: float = brut / puissance
	var facteur: float = 1.0
	if normalise > 5.0:
		facteur = 10.0
	elif normalise > 2.0:
		facteur = 5.0
	elif normalise > 1.0:
		facteur = 2.0
	return facteur * puissance


func _graduations(debut: float, fin: float, pas: float) -> PackedFloat32Array:
	var valeurs: PackedFloat32Array = PackedFloat32Array()
	if pas <= 0.0:
		return valeurs
	var valeur: float = ceilf(debut / pas) * pas
	# Garde-fou : une plage aberrante ne doit pas boucler indefiniment.
	while valeur <= fin and valeurs.size() < 64:
		valeurs.append(valeur)
		valeur += pas
	return valeurs


## Autant de decimales que le pas en demande, jamais plus.
func _formater(valeur: float, pas: float) -> String:
	var decimales: int = maxi(0, int(ceilf(-log(pas) / log(10.0))))
	var texte: String = String.num(valeur, mini(decimales, 4))
	return "0" if texte == "-0" else texte
