## La fiche technique : des champs numeriques vides, jamais un curseur.
##
## Un curseur invite a balayer au hasard, un champ vide invite a reflechir. Le
## joueur n'y saisit pas une reponse mais les coefficients d'un modele, que le
## banc eprouvera sur des cas qu'il n'a pas vus.
##
## Composant autonome : il se construit a partir d'un [EmplacementPiece] et ne
## sait rien de la machine qui l'utilise.
class_name FicheTechnique
extends PanelContainer

## Emis a chaque frappe, pour que le graphe trace le modele en direct.
signal modele_modifie(valeurs: Dictionary)

## Emis quand le joueur envoie sa piece au banc.
signal soumission_demandee(valeurs: Dictionary)

var _emplacement: EmplacementPiece = null
var _champs: Dictionary = {}
var _colonne: VBoxContainer = null
var _consigne: Label = null
var _bouton: Button = null


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

	_consigne = _etiquette("", ThemeBlueprint.POLICE_NORMALE, ThemeBlueprint.TRAIT)
	_consigne.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_colonne.add_child(_consigne)

	_bouton = Button.new()
	_bouton.text = "Envoyer au banc"
	_bouton.add_theme_font_size_override("font_size", ThemeBlueprint.POLICE_NORMALE)
	_bouton.pressed.connect(_sur_soumission)


## Construit les champs a partir de l'emplacement. Un champ par coefficient.
func configurer(emplacement: EmplacementPiece) -> void:
	_emplacement = emplacement
	for champ: Node in _champs.values():
		champ.queue_free()
	_champs.clear()
	if _bouton.get_parent() != null:
		_colonne.remove_child(_bouton)
	if emplacement == null:
		return

	_consigne.text = emplacement.libelle
	_colonne.add_child(_ligne_gabarit(emplacement.gabarit))

	for parametre: String in emplacement.parametres:
		var ligne: HBoxContainer = HBoxContainer.new()
		ligne.add_theme_constant_override("separation", int(ThemeBlueprint.INTERLIGNE))

		var nom: Label = _etiquette(parametre, ThemeBlueprint.POLICE_GRANDE, ThemeBlueprint.MODELE)
		nom.custom_minimum_size.x = 28.0
		ligne.add_child(nom)

		var champ: LineEdit = _champ()
		champ.text_changed.connect(func(_texte: String) -> void: _sur_frappe())
		champ.text_submitted.connect(func(_texte: String) -> void: _sur_soumission())
		ligne.add_child(champ)
		_champs[parametre] = champ

		var unite: String = String(emplacement.unites_parametres.get(parametre, ""))
		if not unite.is_empty():
			ligne.add_child(
				_etiquette(unite, ThemeBlueprint.POLICE_PETITE, ThemeBlueprint.TRAIT_EFFACE)
			)

		_colonne.add_child(ligne)

	_colonne.add_child(_bouton)


## Les coefficients saisis. Un champ vide est absent du dictionnaire : ce n'est
## pas un zero, c'est une case que le joueur n'a pas remplie.
func valeurs() -> Dictionary:
	var saisies: Dictionary = {}
	for parametre: String in _champs:
		var texte: String = String(_champs[parametre].text).strip_edges().replace(",", ".")
		if not texte.is_empty() and texte.is_valid_float():
			saisies[parametre] = texte.to_float()
	return saisies


func est_complete() -> bool:
	return _emplacement != null and valeurs().size() == _emplacement.parametres.size()


## Etat du banc : sans matiere, la fiche ne peut plus etre envoyee.
func definir_soumission_possible(possible: bool) -> void:
	_bouton.disabled = not possible


func _sur_frappe() -> void:
	modele_modifie.emit(valeurs())


func _sur_soumission() -> void:
	if est_complete():
		soumission_demandee.emit(valeurs())


func _ligne_gabarit(gabarit: String) -> Label:
	# Le modele est rappele tel quel, sans etre explique. La forme se lit, elle
	# ne se commente pas.
	return _etiquette(gabarit, ThemeBlueprint.POLICE_GRANDE, ThemeBlueprint.MODELE)


func _etiquette(texte: String, taille: int, couleur: Color) -> Label:
	var etiquette: Label = Label.new()
	etiquette.text = texte
	etiquette.add_theme_font_size_override("font_size", taille)
	etiquette.add_theme_color_override("font_color", couleur)
	return etiquette


func _champ() -> LineEdit:
	var champ: LineEdit = LineEdit.new()
	champ.custom_minimum_size.x = 130.0
	champ.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	champ.placeholder_text = "?"
	champ.add_theme_font_size_override("font_size", ThemeBlueprint.POLICE_NORMALE)
	champ.add_theme_color_override("font_color", ThemeBlueprint.TRAIT)
	var fond: StyleBoxFlat = StyleBoxFlat.new()
	fond.bg_color = ThemeBlueprint.FOND_CHAMP
	fond.border_color = ThemeBlueprint.TRAIT_TRES_EFFACE
	fond.set_border_width_all(int(ThemeBlueprint.TRAIT_FIN))
	fond.set_content_margin_all(ThemeBlueprint.INTERLIGNE * 0.5)
	champ.add_theme_stylebox_override("normal", fond)
	return champ
