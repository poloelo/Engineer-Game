## L'ecran de jeu, valable pour toute machine.
##
## C'est le seul endroit qui connait a la fois l'interface et la simulation, et
## il ne connait aucune machine en particulier : tout vient de la [MachineDef]
## exportee. Une machine nouvelle se branche en changeant deux references dans
## une scene, sans toucher a ce fichier.
##
## Le sens de communication est strict : l'ecran appelle les methodes de la
## simulation, la simulation ne repond que par signaux. Elle ne connait aucun
## noeud.
class_name EcranMachine
extends Control

## La machine a jouer.
@export var definition: MachineDef = null

## Le dessin propre a la machine. Optionnel : une machine sans plan reste
## jouable, le graphe suffit. Doit exposer afficher_mesure(x, y).
@export var plan: PackedScene = null

var _simulation: SimulationMachine = null
var _graphe: Graphe = null
var _fiche: FicheTechnique = null
var _banc: BancEssai = null
var _barre: BarrePrimitives = null
var _plan: Node = null


func _ready() -> void:
	if definition == null:
		push_error("EcranMachine sans definition de machine")
		return

	_simulation = SimulationMachine.new(definition)
	_construire()
	_cadrer()
	_rafraichir_instruments()

	_simulation.mesure_effectuee.connect(_sur_mesure)
	_simulation.specification_evaluee.connect(_sur_resultat)
	_simulation.piece_validee.connect(_sur_piece)
	_simulation.matiere_modifiee.connect(_sur_matiere)

	_barre.mesure_demandee.connect(_sur_demande_mesure)
	_fiche.modele_modifie.connect(_sur_modele_modifie)
	_fiche.soumission_demandee.connect(_sur_soumission)


# --- Construction ------------------------------------------------------------


func _construire() -> void:
	var emplacement: EmplacementPiece = definition.emplacements[0]

	var fond: ColorRect = ColorRect.new()
	fond.color = ThemeBlueprint.FOND
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)

	var marges: MarginContainer = MarginContainer.new()
	marges.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for cote: String in ["left", "right", "top", "bottom"]:
		marges.add_theme_constant_override("margin_" + cote, int(ThemeBlueprint.MARGE))
	add_child(marges)

	var colonnes: HBoxContainer = HBoxContainer.new()
	colonnes.add_theme_constant_override("separation", int(ThemeBlueprint.MARGE))
	marges.add_child(colonnes)

	colonnes.add_child(_colonne_machine())
	colonnes.add_child(_colonne_modele(emplacement))


func _colonne_machine() -> VBoxContainer:
	var colonne: VBoxContainer = VBoxContainer.new()
	colonne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colonne.size_flags_stretch_ratio = 1.0
	colonne.add_theme_constant_override("separation", int(ThemeBlueprint.INTERLIGNE))

	colonne.add_child(
		_etiquette(definition.titre, ThemeBlueprint.POLICE_TITRE, ThemeBlueprint.TRAIT)
	)
	# Le symptome, pose sans commentaire. Une balance qui refuse de bouger est le
	# tutoriel : rien a expliquer par-dessus.
	var symptome: Label = _etiquette(
		definition.symptome, ThemeBlueprint.POLICE_NORMALE, ThemeBlueprint.TRAIT_EFFACE
	)
	symptome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	colonne.add_child(symptome)

	if plan != null:
		_plan = plan.instantiate()
		var controle: Control = _plan as Control
		if controle != null:
			controle.size_flags_vertical = Control.SIZE_EXPAND_FILL
		colonne.add_child(_plan)

	_barre = BarrePrimitives.new()
	colonne.add_child(_barre)
	return colonne


func _colonne_modele(emplacement: EmplacementPiece) -> VBoxContainer:
	var colonne: VBoxContainer = VBoxContainer.new()
	colonne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colonne.size_flags_stretch_ratio = 1.3
	colonne.add_theme_constant_override("separation", int(ThemeBlueprint.INTERLIGNE))

	_graphe = Graphe.new()
	_graphe.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graphe.configurer(
		Catalogue.libelle_axe(emplacement.grandeur_lue),
		Catalogue.libelle_axe(emplacement.grandeur_produite)
	)
	colonne.add_child(_graphe)

	_fiche = FicheTechnique.new()
	_fiche.configurer(emplacement)
	colonne.add_child(_fiche)

	_banc = BancEssai.new()
	colonne.add_child(_banc)
	return colonne


## Fige les axes sur ce que la machine peut produire, pour que le graphe ne saute
## pas a chaque nouveau releve.
func _cadrer() -> void:
	var lecture: Vector2 = _simulation.plage_lecture()
	if lecture == Vector2.ZERO or definition.etalons.is_empty():
		return
	var marge: float = maxf((lecture.y - lecture.x) * 0.12, 1.0)
	var cible_max: float = definition.etalons[0]
	for etalon: float in definition.etalons:
		cible_max = maxf(cible_max, etalon)
	_graphe.imposer_cadrage(lecture.x - marge, lecture.y + marge, 0.0, cible_max * 1.1)


# --- Reactions ---------------------------------------------------------------


func _sur_demande_mesure(valeur: float) -> void:
	_simulation.effectuer_mesure(_simulation.etat_pour_etalon(valeur))


func _sur_mesure(point: Vector2) -> void:
	_graphe.ajouter_releve(point)
	if _plan != null and _plan.has_method("afficher_mesure"):
		_plan.call("afficher_mesure", point.x, point.y)


func _sur_modele_modifie(valeurs: Dictionary) -> void:
	# Le modele se trace en direct, a chaque frappe : c'est ce qui fait du graphe
	# un instrument de reflexion et pas un compte rendu.
	var emplacement: EmplacementPiece = definition.emplacements[0]
	var specification: Specification = Specification.new(emplacement, valeurs)
	if not specification.est_complete():
		_graphe.definir_modele(PackedVector2Array())
		return
	var plage: Vector2 = _simulation.plage_lecture()
	_graphe.definir_modele(_simulation.courbe_predite(specification, plage.x, plage.y))


func _sur_soumission(valeurs: Dictionary) -> void:
	_simulation.soumettre_specification(
		Specification.new(definition.emplacements[0], valeurs)
	)


func _sur_resultat(resultat: ResultatBanc) -> void:
	_banc.afficher(resultat)
	if not resultat.est_valide():
		return
	# La machine reelle n'apparait qu'apres une soumission. Le joueur voit alors
	# ou son modele decroche, ce qui vaut mieux qu'un verdict.
	var plage: Vector2 = _simulation.plage_lecture()
	_graphe.definir_courbe_reelle(_simulation.courbe_reelle(plage.x, plage.y))


func _sur_piece(piece: Piece) -> void:
	_rafraichir_instruments(piece)


func _sur_matiere(restante: int) -> void:
	_fiche.definir_soumission_possible(restante > 0)
	_rafraichir_instruments()


func _rafraichir_instruments(piece: Piece = null) -> void:
	var lignes: PackedStringArray = PackedStringArray()
	lignes.append("Matiere restante : %d" % _simulation.matiere_restante())
	if definition.primitive_lue != null:
		lignes.append(
			(
				"%s : %s %s"
				% [
					definition.primitive_lue.nom,
					String.num(definition.primitive_lue.pas, 2),
					Catalogue.unite(definition.emplacements[0].grandeur_lue),
				]
			)
		)
	if piece != null:
		lignes.append(
			(
				"%s : %s %s"
				% [
					piece.nom,
					String.num(piece.pas_ameliore, 2),
					Catalogue.unite(definition.emplacements[0].grandeur_produite),
				]
			)
		)

	var emplacement: EmplacementPiece = definition.emplacements[0]
	_barre.configurer(
		definition.etalons,
		Catalogue.unite(emplacement.grandeur_produite),
		"Imposer une valeur de reference et relever :"
	)
	_barre.definir_instruments(lignes)


func _etiquette(texte: String, taille: int, couleur: Color) -> Label:
	var etiquette: Label = Label.new()
	etiquette.text = texte
	etiquette.add_theme_font_size_override("font_size", taille)
	etiquette.add_theme_color_override("font_color", couleur)
	return etiquette
