## Acces par identifiant au contenu pose sur le disque.
##
## Se contente de lire les dossiers de donnees : ajouter une grandeur, une loi ou
## une machine consiste a y deposer un .tres, jamais a inscrire quoi que ce soit
## dans une liste.
class_name Catalogue
extends RefCounted

const DOSSIER_GRANDEURS: String = "res://src/contenu/data/grandeurs"
const DOSSIER_PRIMITIVES: String = "res://src/contenu/data/primitives"
const DOSSIER_LOIS: String = "res://src/contenu/data/lois"
const DOSSIER_MACHINES: String = "res://src/contenu/data/machines"

static var _caches: Dictionary = {}


static func grandeurs() -> Array[Grandeur]:
	var trouvees: Array[Grandeur] = []
	for ressource: Resource in _charger(DOSSIER_GRANDEURS):
		trouvees.append(ressource as Grandeur)
	return trouvees


static func lois() -> Array[Loi]:
	var trouvees: Array[Loi] = []
	for ressource: Resource in _charger(DOSSIER_LOIS):
		trouvees.append(ressource as Loi)
	return trouvees


static func primitives() -> Array[Primitive]:
	var trouvees: Array[Primitive] = []
	for ressource: Resource in _charger(DOSSIER_PRIMITIVES):
		trouvees.append(ressource as Primitive)
	return trouvees


static func machines() -> Array[MachineDef]:
	var trouvees: Array[MachineDef] = []
	for ressource: Resource in _charger(DOSSIER_MACHINES):
		trouvees.append(ressource as MachineDef)
	return trouvees


static func grandeur(id: StringName) -> Grandeur:
	for trouvee: Grandeur in grandeurs():
		if trouvee.id == id:
			return trouvee
	return null


static func primitive(id: StringName) -> Primitive:
	for trouvee: Primitive in primitives():
		if trouvee.id == id:
			return trouvee
	return null


## "Longueur (mm)" — ce qui va sur un axe de graphe.
static func libelle_axe(id: StringName) -> String:
	var trouvee: Grandeur = grandeur(id)
	if trouvee == null:
		return String(id)
	return "%s (%s)" % [trouvee.nom, trouvee.unite]


static func unite(id: StringName) -> String:
	var trouvee: Grandeur = grandeur(id)
	return "" if trouvee == null else trouvee.unite


static func _charger(dossier: String) -> Array[Resource]:
	if _caches.has(dossier):
		return _caches[dossier]

	var ressources: Array[Resource] = []
	var acces: DirAccess = DirAccess.open(dossier)
	if acces != null:
		var fichiers: PackedStringArray = acces.get_files()
		fichiers.sort()
		for fichier: String in fichiers:
			# Les ressources sont exportees en .remap dans un projet empaquete.
			var nom: String = fichier.trim_suffix(".remap")
			if nom.ends_with(".tres"):
				var ressource: Resource = load("%s/%s" % [dossier, nom])
				if ressource != null:
					ressources.append(ressource)
	_caches[dossier] = ressources
	return ressources
