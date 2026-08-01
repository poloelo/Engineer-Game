## Une des huit primitives : ce que le joueur peut faire sans rien construire.
##
## Chaque primitive a une precision, et cette precision est amelioree par les
## pieces que le joueur fabrique. Le desequilibre est volontaire : le chronometre
## est tres precis, tout le reste est grossier. C'est ce qui pousse le joueur a
## convertir systematiquement les grandeurs en durees.
class_name Primitive
extends Resource

## Identifiant stable (&"peser", &"chronometrer"...).
@export var id: StringName = &""

@export var nom: String = ""

## Grandeurs que cette primitive sait lire directement.
@export var grandeurs_mesurables: Array[StringName] = []

## Resolution de l'instrument, dans l'unite de la grandeur mesuree : toute
## lecture est arrondie a un multiple de ce pas. C'est le modele central de
## l'imprecision, et il est deterministe — une balance a pas de 100 g rend
## toujours la meme valeur pour la meme masse, elle ne tremble pas.
@export var pas: float = 1.0

## Bruit aleatoire additionnel, en ecart-type, applique avant l'arrondi.
## Nul par defaut : la plupart des instruments du jeu sont grossiers mais stables.
@export var bruit: float = 0.0

## Precision purement qualitative (frapper, souffler) : la primitive excite un
## phenomene mais ne rend pas de nombre exploitable seul.
@export var qualitative: bool = false
