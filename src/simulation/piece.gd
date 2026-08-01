## Une specification validee, devenue instrument.
##
## L'inventaire du joueur, ce sont ses instruments et ses modeles, pas des
## objets : une piece ne sert a rien en elle-meme, elle ameliore la precision
## d'une primitive pour toutes les machines suivantes.
class_name Piece
extends Resource

@export var id: StringName = &""
@export var nom: String = ""
@export var machine_id: StringName = &""
@export var emplacement_id: StringName = &""

## Les coefficients tels que le joueur les a soumis.
@export var valeurs: Dictionary = {}

@export var etoiles: int = 0

## La primitive amelioree et sa nouvelle resolution.
@export var primitive_amelioree: StringName = &""
@export var pas_ameliore: float = 0.0


static func depuis(
	machine: MachineDef,
	emplacement: EmplacementPiece,
	specification: Specification,
	resultat: ResultatBanc
) -> Piece:
	var piece: Piece = Piece.new()
	piece.id = StringName("%s_%s" % [machine.id, emplacement.id])
	piece.nom = emplacement.nom
	piece.machine_id = machine.id
	piece.emplacement_id = emplacement.id
	piece.valeurs = specification.valeurs.duplicate()
	piece.etoiles = resultat.etoiles
	piece.primitive_amelioree = emplacement.primitive_amelioree
	piece.pas_ameliore = emplacement.pas_ameliore
	return piece
