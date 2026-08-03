# Les points d'attache sont des Marker2D nommes, portes par les objets.
#
# Aucune position n'est codee en dur dans la logique de clipsage : elle demande
# « le marqueur du genre GENRE le plus proche de ce point, dans ce rayon » et
# l'objet repond avec ce qu'il expose. Un marqueur se deplace a la souris dans
# l'editeur le jour ou ces objets deviendront des scenes, et c'est ce qui prepare
# les modules qui se clipsent entre eux.
#
# Le genre est range dans une metadonnee plutot que dans le nom : deux objets
# peuvent nommer leur point d'accroche autrement (`crochet`, `pointe`,
# `bord_zero`) tout en etant compatibles.
extends RefCounted

const GENRE: StringName = &"genre"

## Ce qui pend : l'oeillet d'une masse, l'anneau du crochet.
const SUSPENSION: StringName = &"suspension"
## Ce a quoi on peut pendre : l'extremite du ressort, le bas d'une masse.
const SUPPORT: StringName = &"support"
## Ce sur quoi le stylo se clipse.
const PORTE_STYLO: StringName = &"porte_stylo"
## La pointe qui ecrit.
const POINTE: StringName = &"pointe"
## Le zero grave d'un instrument de mesure.
const REPERE: StringName = &"repere"


## Cree un Marker2D nomme sur [param parent], a la position locale voulue.
static func poser(parent: Node2D, nom: String, ou: Vector2, genre: StringName) -> Marker2D:
	var marqueur: Marker2D = Marker2D.new()
	marqueur.name = nom
	marqueur.position = ou
	marqueur.set_meta(GENRE, genre)
	parent.add_child(marqueur)
	return marqueur


## Le marqueur du genre voulu le plus proche de [param point] (en monde), dans
## [param rayon]. null si aucun. [param racines] est la liste des objets fouilles.
static func plus_proche(
	racines: Array, point: Vector2, genre: StringName, rayon: float
) -> Marker2D:
	var meilleur: Marker2D = null
	var distance: float = rayon
	for racine: Variant in racines:
		var noeud: Node = racine as Node
		if noeud == null or not is_instance_valid(noeud):
			continue
		for marqueur: Marker2D in _du_genre(noeud, genre):
			var ecart: float = marqueur.global_position.distance_to(point)
			if ecart < distance:
				distance = ecart
				meilleur = marqueur
	return meilleur


## Le marqueur nomme porte par [param objet], ou null.
static func nomme(objet: Node, nom: String) -> Marker2D:
	return objet.get_node_or_null(NodePath(nom)) as Marker2D


## Position monde du marqueur nomme, ou celle de l'objet a defaut.
static func position_de(objet: Node2D, nom: String) -> Vector2:
	var marqueur: Marker2D = nomme(objet, nom)
	return marqueur.global_position if marqueur != null else objet.global_position


static func _du_genre(racine: Node, genre: StringName) -> Array[Marker2D]:
	var trouves: Array[Marker2D] = []
	for enfant: Node in racine.get_children():
		var marqueur: Marker2D = enfant as Marker2D
		if marqueur != null and marqueur.get_meta(GENRE, &"") == genre:
			trouves.append(marqueur)
	return trouves
