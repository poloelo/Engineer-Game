## Un cas cache sur lequel le banc d'essai eprouve la piece du joueur.
##
## Le joueur ne les voit jamais et ne peut pas les mesurer : c'est ce qui rend le
## brute-force mecaniquement impossible sans avoir a l'interdire. Une piece qui
## marche sur trois cas inconnus est un modele juste, pas une valeur devinee.
class_name CasTest
extends Resource

## Etat cache de la machine : une valeur par grandeur d'entree de la loi.
## Le banc en derive a la fois ce que l'instrument lirait et la bonne reponse.
@export var etat: Dictionary = {}

## Libelle interne, jamais montre au joueur avant l'evaluation.
@export var libelle: String = ""
