# Panneau de reglage a chaud. Tab pour l'ouvrir et le fermer.
#
# Des curseurs, oui : c'est un outil de reglage, pas une mecanique de jeu. Regler
# a chaud est la seule facon d'affiner un feel — sinon on relance trente fois et
# on n'ajuste jamais vraiment.
#
# La gravite n'est PAS ici et n'y sera pas. Elle vaut 9,81 m/s2. Si la sensation
# ne va pas, on ajuste les masses, les raideurs ou l'echelle de temps — qui, elle,
# est en haut de la liste.
#
# Toutes les bornes sont en mm, g, s.
extends CanvasLayer

const Reglages: GDScript = preload("res://src/atelier/reglages.gd")


func _ready() -> void:
	layer = 10
	var fond: PanelContainer = PanelContainer.new()
	fond.position = Vector2(14.0, 14.0)
	fond.custom_minimum_size.x = 350.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.09, 0.16, 0.92)
	style.border_color = Color(1.0, 1.0, 1.0, 0.16)
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	fond.add_theme_stylebox_override("panel", style)
	add_child(fond)

	var colonne: VBoxContainer = VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 2)
	fond.add_child(colonne)

	for ligne: Array in _lignes():
		colonne.add_child(_curseur(ligne[0], ligne[1], ligne[2], ligne[3]))

	var aide: Label = Label.new()
	aide.text = (
		"Tab masquer · R ranger · Espace ou clic droit : pointe\n"
		+ "F retourner la feuille · P effacer la face · N feuille vierge · E exporter en PNG"
	)
	aide.add_theme_font_size_override("font_size", 11)
	aide.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.4))
	colonne.add_child(aide)

	visible = false


func _input(evenement: InputEvent) -> void:
	if evenement is InputEventKey and evenement.pressed and evenement.keycode == KEY_TAB:
		visible = not visible
		get_viewport().set_input_as_handled()


## Nom de la propriete dans reglages.gd, libelle, minimum, maximum.
##
## Les statiques se lisent et s'ecrivent par set()/get() sur l'objet script :
## pas besoin d'une paire de Callables par ligne.
func _lignes() -> Array:
	return [
		["ECHELLE_TEMPS", "Echelle de temps", 0.1, 2.0],
		["RAIDEUR", "Raideur ressort (g/s2)", 2000.0, 24000.0],
		["AMORTISSEMENT", "Amortissement axial", 0.0, 200.0],
		["AMORTISSEMENT_LATERAL", "Amortissement lateral (1/s)", 0.0, 12.0],
		["LONGUEUR_REPOS", "Longueur au repos (mm)", 20.0, 120.0],
		["MASSE_CROCHET", "Masse du crochet (g)", 0.0, 40.0],
		["MASSE_RESSORT", "Masse du ressort (g)", 0.0, 60.0],
		["RAIDEUR_CURSEUR", "Rappel curseur (g/s2)", 1000.0, 25000.0],
		["AMORTISSEMENT_CURSEUR", "Amortissement curseur", 10.0, 320.0],
		["COMPENSATION_POIDS", "Compensation du poids", 0.0, 1.0],
		["RAYON_AIMANTATION", "Rayon d'aimantation (mm)", 8.0, 80.0],
		["FORCE_AIMANTATION", "Force d'aimantation (mm/s2)", 0.0, 6000.0],
		["AMPLITUDE_SURSAUT", "Sursaut d'accrochage (mm/s)", 0.0, 500.0],
		["SEUIL_DECROCHAGE", "Seuil de decrochage (mm)", 15.0, 160.0],
		["TRANSMISSION_CHOC", "Transmission du choc", 0.0, 2.0],
		["REBOND", "Rebond", 0.0, 0.9],
		["FRICTION", "Friction", 0.0, 2.0],
		["FREIN_ROULEMENT", "Frein de roulement", 0.0, 8.0],
		["AMORTISSEMENT_BUTEE", "Amortissement butee", 20.0, 800.0],
		["BALLANT", "Ballant du ressort (s)", 0.0, 0.3],
		["LARGEUR_SPIRE", "Largeur des spires (mm)", 2.0, 20.0],
		["SOUPLESSE_CHAINE", "Souplesse de la chaine", 0.02, 1.0],
		["SEUIL_REPOS", "Seuil de repos (mm)", 0.0, 5.0],
		["RAYON_CLIPSAGE", "Rayon de clipsage (mm)", 8.0, 65.0],
		["PAS_TRACE", "Finesse de la trace (mm)", 0.2, 5.0],
		["AIMANT_REGLE", "Aimant de la regle (mm)", 2.0, 35.0],
		["RAYON_LOUPE", "Rayon de la loupe (mm)", 15.0, 80.0],
		["GROSSISSEMENT_LOUPE", "Grossissement", 1.5, 7.0],
	]


func _curseur(propriete: String, libelle: String, mini: float, maxi: float) -> Control:
	var ligne: VBoxContainer = VBoxContainer.new()
	ligne.add_theme_constant_override("separation", 0)

	var texte: Label = Label.new()
	texte.add_theme_font_size_override("font_size", 11)
	texte.add_theme_color_override("font_color", Color(0.9, 0.94, 0.97, 0.75))
	ligne.add_child(texte)

	var curseur: HSlider = HSlider.new()
	curseur.min_value = mini
	curseur.max_value = maxi
	curseur.step = (maxi - mini) / 400.0
	curseur.value = float(Reglages.get(propriete))
	curseur.custom_minimum_size.y = 14.0
	ligne.add_child(curseur)

	var rafraichir: Callable = func(valeur: float) -> void:
		texte.text = "%s   %s" % [libelle, String.num(valeur, 2)]
	rafraichir.call(curseur.value)
	curseur.value_changed.connect(
		func(valeur: float) -> void:
			Reglages.set(propriete, valeur)
			rafraichir.call(valeur)
	)
	return ligne
