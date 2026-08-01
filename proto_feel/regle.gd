# La regle. Un objet physique qu'on pose sur la feuille, qu'on tourne, qu'on fixe.
#
# Deux dispositifs sans lesquels l'outil serait insupportable, et qui font donc
# partie de l'outil et non du confort : l'aimantation du curseur sur la
# graduation la plus proche, et la loupe qui grossit les graduations autour du
# pointeur. Viser au pixel pres a la souris n'est pas une competence de jeu.
#
# Les seuls chiffres de tout le prototype sont graves ici. C'est au joueur de
# les lire.
extends Node2D

const Reglages: GDScript = preload("res://reglages.gd")

const CORPS: Color = Color(0.86, 0.92, 0.97, 0.10)
const BORD: Color = Color(0.90, 0.94, 0.97, 0.55)
const GRADUATION: Color = Color(0.90, 0.94, 0.97, 0.65)
const CHIFFRE: Color = Color(0.90, 0.94, 0.97, 0.80)
const AIMANT: Color = Color("ffb454")
const FIXEE: Color = Color("8ef0b8")

const LONGUEUR: float = 460.0
const LARGEUR: float = 46.0
const PAS: float = 5.0
const RAYON_BOUTON: float = 13.0

var en_rotation: bool = false
var fixee: bool = false

var _curseur: Vector2 = Vector2.ZERO
var _curseur_valide: bool = false
## Indice de la graduation aimantee, -1 si le curseur est trop loin du bord.
var _graduation: int = -1


func _ready() -> void:
	rotation = -0.06


# --- Prise en main -----------------------------------------------------------


func attraper(ou: Vector2) -> bool:
	var local: Vector2 = to_local(ou)
	en_rotation = false

	# La punaise centrale fixe et libere la regle. C'est l'equivalent physique de
	# poser un modele sur ses points et de l'y laisser.
	if local.distance_to(_punaise()) < RAYON_BOUTON:
		fixee = not fixee
		queue_redraw()
		return false

	if fixee:
		return false

	if local.distance_to(_bouton()) < RAYON_BOUTON + 4.0:
		en_rotation = true
		return true

	return Rect2(Vector2(0.0, -6.0), Vector2(LONGUEUR, LARGEUR + 6.0)).has_point(local)


func relacher() -> void:
	en_rotation = false


func pivoter_vers(monde: Vector2) -> void:
	# On tourne autour de l'origine de la regle, c'est-a-dire du zero de sa
	# graduation : c'est le point qu'on aligne d'abord sur une marque.
	rotation = (monde - global_position).angle() - atan2(_bouton().y, _bouton().x)
	queue_redraw()


## Appele a chaque frame avec la position du pointeur, pour l'aimantation et la loupe.
func definir_curseur(monde: Vector2) -> void:
	_curseur = monde
	var local: Vector2 = to_local(monde)
	_curseur_valide = absf(local.y) < Reglages.DISTANCE_LOUPE and (
		local.x > -Reglages.DISTANCE_LOUPE and local.x < LONGUEUR + Reglages.DISTANCE_LOUPE
	)

	_graduation = -1
	if absf(local.y) < Reglages.AIMANT_REGLE and local.x >= -PAS and local.x <= LONGUEUR + PAS:
		_graduation = clampi(int(round(local.x / PAS)), 0, int(LONGUEUR / PAS))
	queue_redraw()


## Position monde de la graduation aimantee, pour qui voudrait s'en servir.
func point_aimante() -> Vector2:
	if _graduation < 0:
		return Vector2.ZERO
	return to_global(Vector2(float(_graduation) * PAS, 0.0))


# --- Dessin ------------------------------------------------------------------


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(LONGUEUR, LARGEUR)), CORPS, true)
	draw_rect(
		Rect2(Vector2.ZERO, Vector2(LONGUEUR, LARGEUR)),
		FIXEE if fixee else BORD,
		false,
		1.5
	)
	_dessiner_graduations(1.0, Vector2.ZERO, 1.0)

	# Le bouton de rotation, au bout.
	draw_arc(_bouton(), RAYON_BOUTON, 0.0, TAU, 24, BORD, 1.5)
	draw_line(
		_bouton() + Vector2(-5.0, 0.0), _bouton() + Vector2(5.0, 0.0), BORD, 1.5
	)
	draw_line(
		_bouton() + Vector2(0.0, -5.0), _bouton() + Vector2(0.0, 5.0), BORD, 1.5
	)

	# La punaise centrale : creuse quand la regle est libre, pleine quand fixee.
	if fixee:
		draw_circle(_punaise(), RAYON_BOUTON * 0.55, FIXEE)
	draw_arc(_punaise(), RAYON_BOUTON * 0.55, 0.0, TAU, 20, FIXEE if fixee else BORD, 1.5)

	if _graduation >= 0:
		_dessiner_aimantation()

	if _curseur_valide:
		_dessiner_loupe()


## Les graduations. Dessinees dans un repere parametrable pour que la loupe
## puisse reutiliser exactement le meme trace, simplement agrandi.
func _dessiner_graduations(echelle: float, origine: Vector2, alpha: float) -> void:
	var police: Font = ThemeDB.fallback_font
	var total: int = int(LONGUEUR / PAS)
	for i: int in total + 1:
		var x: float = float(i) * PAS
		var longue: bool = i % 5 == 0
		var chiffree: bool = i % 10 == 0
		var hauteur: float = 15.0 if chiffree else (10.0 if longue else 5.5)

		var haut: Vector2 = origine + Vector2(x, 0.0) * echelle
		var bas: Vector2 = origine + Vector2(x, hauteur) * echelle
		var couleur: Color = GRADUATION
		couleur.a *= alpha
		draw_line(haut, bas, couleur, 1.0 * maxf(echelle * 0.6, 1.0))

		if chiffree:
			var texte: String = str(i)
			var taille: int = int(11.0 * maxf(echelle, 1.0))
			var largeur: float = police.get_string_size(
				texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille
			).x
			var teinte: Color = CHIFFRE
			teinte.a *= alpha
			draw_string(
				police,
				origine + Vector2(x, hauteur + 4.0) * echelle - Vector2(largeur * 0.5, -12.0 * echelle),
				texte,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				taille,
				teinte
			)


func _dessiner_aimantation() -> void:
	var x: float = float(_graduation) * PAS
	draw_line(Vector2(x, -9.0), Vector2(x, LARGEUR), AIMANT, 1.5)
	draw_arc(Vector2(x, 0.0), 5.0, 0.0, TAU, 16, AIMANT, 2.0)


## La loupe, dessinee en repere monde pour rester ronde quelle que soit
## l'orientation de la regle.
func _dessiner_loupe() -> void:
	draw_set_transform_matrix(get_global_transform().affine_inverse())

	var rayon: float = Reglages.RAYON_LOUPE
	var grossissement: float = Reglages.GROSSISSEMENT_LOUPE

	# Fond opaque : sans lui on lirait les graduations normales par transparence.
	draw_circle(_curseur, rayon, Color("0d243d"))

	var total: int = int(LONGUEUR / PAS)
	var police: Font = ThemeDB.fallback_font
	for i: int in total + 1:
		var base: Vector2 = to_global(Vector2(float(i) * PAS, 0.0))
		var loupe_haut: Vector2 = _curseur + (base - _curseur) * grossissement
		if loupe_haut.distance_to(_curseur) > rayon + 30.0:
			continue

		var longue: bool = i % 5 == 0
		var chiffree: bool = i % 10 == 0
		var hauteur: float = 15.0 if chiffree else (10.0 if longue else 5.5)
		var pied: Vector2 = to_global(Vector2(float(i) * PAS, hauteur))
		var loupe_bas: Vector2 = _curseur + (pied - _curseur) * grossissement

		var segment: PackedVector2Array = _clip_cercle(loupe_haut, loupe_bas, _curseur, rayon)
		if segment.size() == 2:
			draw_line(segment[0], segment[1], GRADUATION, 1.6)

		if chiffree and loupe_haut.distance_to(_curseur) < rayon - 14.0:
			var texte: String = str(i)
			var taille: int = 13
			var largeur: float = police.get_string_size(
				texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille
			).x
			var ancre: Vector2 = _curseur + (
				to_global(Vector2(float(i) * PAS, hauteur + 13.0)) - _curseur
			) * grossissement
			draw_string(
				police,
				ancre - Vector2(largeur * 0.5, 0.0),
				texte,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				taille,
				CHIFFRE
			)

	# Le bord de la loupe et la croisee de visee.
	draw_arc(_curseur, rayon, 0.0, TAU, 48, BORD, 2.0)
	draw_line(_curseur + Vector2(-7.0, 0.0), _curseur + Vector2(7.0, 0.0), AIMANT, 1.0)
	draw_line(_curseur + Vector2(0.0, -7.0), _curseur + Vector2(0.0, 7.0), AIMANT, 1.0)

	draw_set_transform_matrix(Transform2D.IDENTITY)


## Decoupe un segment au disque de la loupe. Rend un tableau vide s'il est
## entierement dehors.
func _clip_cercle(a: Vector2, b: Vector2, centre: Vector2, rayon: float) -> PackedVector2Array:
	var direction: Vector2 = b - a
	var vers: Vector2 = a - centre
	var qa: float = direction.dot(direction)
	if qa < 1e-9:
		return PackedVector2Array()
	var qb: float = 2.0 * vers.dot(direction)
	var qc: float = vers.dot(vers) - rayon * rayon
	var discriminant: float = qb * qb - 4.0 * qa * qc
	if discriminant < 0.0:
		return PackedVector2Array()

	var racine: float = sqrt(discriminant)
	var debut: float = maxf((-qb - racine) / (2.0 * qa), 0.0)
	var fin: float = minf((-qb + racine) / (2.0 * qa), 1.0)
	if debut > fin:
		return PackedVector2Array()
	return PackedVector2Array([a + direction * debut, a + direction * fin])


func _bouton() -> Vector2:
	return Vector2(LONGUEUR + RAYON_BOUTON + 6.0, LARGEUR * 0.5)


func _punaise() -> Vector2:
	return Vector2(LONGUEUR * 0.5, LARGEUR * 0.5)
