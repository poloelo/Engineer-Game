## Une grandeur physique du jeu (temperature, masse, longueur...).
##
## Purement descriptif : une grandeur ne sait ni calculer ni s'afficher, elle
## nomme. Les lois s'y referent par [member id].
class_name Grandeur
extends Resource

## Identifiant stable, utilise comme nom de variable dans les expressions des lois.
## Doit donc etre un identifiant GDScript valide (pas d'espace, pas d'accent).
@export var id: StringName = &""

## Libelle affichable.
@export var nom: String = ""

## Symbole conventionnel (m, L, F, T...).
@export var symbole: String = ""

## Unite de reference dans laquelle toutes les valeurs de cette grandeur
## circulent dans la simulation. Une seule unite par grandeur : les conversions
## sont un probleme de presentation, pas de simulation.
@export var unite: String = ""
