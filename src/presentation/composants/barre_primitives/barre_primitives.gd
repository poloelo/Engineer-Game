## La barre des primitives : tout ce que le joueur peut faire sans rien
## construire, et la precision actuelle de chacune.
##
## Composant autonome : il recoit des libelles et des valeurs, et emet un signal
## quand le joueur agit. Il ne sait rien de la machine ni de la simulation.
class_name BarrePrimitives
extends PanelContainer

## Le joueur impose une valeur de reference a la machine (accrocher un etalon,
## verser un volume connu).
signal mesure_demandee(valeur: float)

var _colonne: VBoxContainer = null
var _actions: HBoxContainer = null
var _instruments: VBoxContainer = null
var _consigne: Label = null


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
	_colonne.add_child(_consigne)

	_actions = HBoxContainer.new()
	_actions.add_theme_constant_override("separation", int(ThemeBlueprint.INTERLIGNE))
	_colonne.add_child(_actions)

	_instruments = VBoxContainer.new()
	_instruments.add_theme_constant_override("separation", 2)
	_colonne.add_child(_instruments)


## Un bouton par valeur de reference disponible.
func configurer(valeurs: Array[float], unite: String, consigne: String) -> void:
	_consigne.text = consigne
	for enfant: Node in _actions.get_children():
		_actions.remove_child(enfant)
		enfant.queue_free()

	for valeur: float in valeurs:
		var bouton: Button = Button.new()
		bouton.text = "%s %s" % [String.num(valeur, 0), unite]
		bouton.add_theme_font_size_override("font_size", ThemeBlueprint.POLICE_NORMALE)
		bouton.pressed.connect(func() -> void: mesure_demandee.emit(valeur))
		_actions.add_child(bouton)


## Etat des instruments, une ligne par primitive : son nom et sa resolution.
## C'est le seul inventaire du jeu — des instruments et des modeles, pas des objets.
func definir_instruments(lignes: PackedStringArray) -> void:
	for enfant: Node in _instruments.get_children():
		_instruments.remove_child(enfant)
		enfant.queue_free()
	for ligne: String in lignes:
		_instruments.add_child(
			_etiquette(ligne, ThemeBlueprint.POLICE_PETITE, ThemeBlueprint.TRAIT_EFFACE)
		)


func _etiquette(texte: String, taille: int, couleur: Color) -> Label:
	var etiquette: Label = Label.new()
	etiquette.text = texte
	etiquette.add_theme_font_size_override("font_size", taille)
	etiquette.add_theme_color_override("font_color", couleur)
	return etiquette
