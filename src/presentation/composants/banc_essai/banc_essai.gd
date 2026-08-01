## Le banc d'essai : ce que la machine fait vraiment avec la piece du joueur.
##
## Il n'affiche jamais "faux". Il affiche un ecart, cas par cas, et laisse le
## graphe montrer ou le modele decroche. Un mauvais resultat est une information,
## pas une sanction.
class_name BancEssai
extends PanelContainer

var _colonne: VBoxContainer = null
var _verdict: Label = null
var _etoiles: Etoiles = null
var _details: VBoxContainer = null


func _init() -> void:
	var fond: StyleBoxFlat = StyleBoxFlat.new()
	fond.bg_color = ThemeBlueprint.FOND_PANNEAU
	fond.border_color = ThemeBlueprint.GRILLE_FORTE
	fond.set_border_width_all(int(ThemeBlueprint.TRAIT_FIN))
	fond.set_content_margin_all(ThemeBlueprint.MARGE)
	add_theme_stylebox_override("panel", fond)

	_colonne = VBoxContainer.new()
	_colonne.add_theme_constant_override("separation", int(ThemeBlueprint.INTERLIGNE))
	add_child(_colonne)

	_etoiles = Etoiles.new()
	_etoiles.custom_minimum_size = Vector2(120.0, 28.0)
	_colonne.add_child(_etoiles)

	_verdict = _etiquette("", ThemeBlueprint.POLICE_GRANDE, ThemeBlueprint.TRAIT)
	_colonne.add_child(_verdict)

	_details = VBoxContainer.new()
	_details.add_theme_constant_override("separation", 2)
	_colonne.add_child(_details)


func reinitialiser() -> void:
	_verdict.text = ""
	_etoiles.definir(0)
	_vider_details()


func afficher(resultat: ResultatBanc) -> void:
	_vider_details()

	if not resultat.est_valide():
		_etoiles.definir(0)
		_verdict.text = resultat.erreur
		_verdict.add_theme_color_override("font_color", ThemeBlueprint.TRAIT_EFFACE)
		return

	_etoiles.definir(resultat.etoiles)
	_verdict.text = "Ecart maximal %s %%" % _pourcent(resultat.ecart_max)
	_verdict.add_theme_color_override(
		"font_color",
		ThemeBlueprint.REEL if resultat.equipable() else ThemeBlueprint.ECART
	)

	for detail: Dictionary in resultat.details:
		var ecart: float = float(detail["ecart"])
		var ligne: Label = _etiquette(
			(
				"%s   lu %s   attendu %s   obtenu %s   ecart %s %%"
				% [
					detail["libelle"],
					_nombre(float(detail["lecture"])),
					_nombre(float(detail["vraie"])),
					_nombre(float(detail["predite"])),
					_pourcent(ecart),
				]
			),
			ThemeBlueprint.POLICE_PETITE,
			ThemeBlueprint.TRAIT_EFFACE if ecart <= ResultatBanc.SEUIL_UNE_ETOILE else ThemeBlueprint.ECART
		)
		_details.add_child(ligne)


func _vider_details() -> void:
	for enfant: Node in _details.get_children():
		_details.remove_child(enfant)
		enfant.queue_free()


func _etiquette(texte: String, taille: int, couleur: Color) -> Label:
	var etiquette: Label = Label.new()
	etiquette.text = texte
	etiquette.add_theme_font_size_override("font_size", taille)
	etiquette.add_theme_color_override("font_color", couleur)
	return etiquette


static func _nombre(valeur: float) -> String:
	return String.num(valeur, 1)


static func _pourcent(ecart: float) -> String:
	if is_inf(ecart) or is_nan(ecart):
		return "-"
	return String.num(ecart * 100.0, 2)


## Les etoiles, dessinees comme le reste : des traits, pas une image.
class Etoiles:
	extends Control

	const BRANCHES: int = 5
	const ECART_ETOILES: float = 34.0

	var _obtenues: int = 0

	func definir(nombre: int) -> void:
		_obtenues = nombre
		queue_redraw()

	func _draw() -> void:
		var rayon: float = minf(size.y, ECART_ETOILES) * 0.42
		for i: int in 3:
			var centre: Vector2 = Vector2(rayon + float(i) * ECART_ETOILES, size.y * 0.5)
			var contour: PackedVector2Array = _contour(centre, rayon)
			if i < _obtenues:
				draw_colored_polygon(contour, ThemeBlueprint.MODELE)
			else:
				contour.append(contour[0])
				draw_polyline(contour, ThemeBlueprint.TRAIT_TRES_EFFACE, ThemeBlueprint.TRAIT_FIN)

	func _contour(centre: Vector2, rayon: float) -> PackedVector2Array:
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in BRANCHES * 2:
			var angle: float = -PI * 0.5 + float(i) * PI / float(BRANCHES)
			var distance: float = rayon if i % 2 == 0 else rayon * 0.42
			points.append(centre + Vector2(cos(angle), sin(angle)) * distance)
		return points
