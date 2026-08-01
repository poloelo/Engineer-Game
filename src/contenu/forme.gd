## Les formes mathematiques transverses du jeu.
##
## Une forme est ce que plusieurs lois physiquement sans rapport partagent :
## Hooke, Ohm, la dilatation thermique et le debit constant sont quatre lois
## differentes qui ont toutes la forme LINEAIRE. C'est le contenu pedagogique
## du jeu, donc un champ de premier ordre du modele de donnees.
class_name Forme
extends RefCounted

enum Type {
	LINEAIRE,
	RACINE,
	QUADRATIQUE,
	RATIONNELLE,
	EXPONENTIELLE,
	TRIGONOMETRIQUE,
	SYSTEME,
}

const NOMS: Dictionary = {
	Type.LINEAIRE: "lineaire",
	Type.RACINE: "racine",
	Type.QUADRATIQUE: "quadratique",
	Type.RATIONNELLE: "rationnelle",
	Type.EXPONENTIELLE: "exponentielle",
	Type.TRIGONOMETRIQUE: "trigonometrique",
	Type.SYSTEME: "systeme",
}

## Libelle affichable d'une forme, pour le carnet.
static func nom(type: Type) -> String:
	return NOMS.get(type, "inconnue")
