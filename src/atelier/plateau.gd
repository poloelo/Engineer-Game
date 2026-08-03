# Le plateau de livraison. Trois emplacements creuses dans l'etabli, un par ligne
# du bon de travail.
#
# C'est la FIN de la boucle, et c'est un objet, pas un ecran de resultat. Le
# compte des sachets produits se lit en regardant le plateau : trois creux vides,
# puis deux, puis un, puis plus aucun. Aucun chiffre, aucun pourcentage.
#
# Le verdict n'est pas rendu emplacement par emplacement — dire « celui-la est
# faux » serait le verdict binaire que le document interdit. Tant que le compte
# n'y est pas, il ne se passe simplement rien ; quand les trois sachets tombent
# dans la tolerance, le plateau le montre d'un coup. Un sachet mal dose se
# reprend et se corrige.
extends Node2D

const Marqueurs: GDScript = preload("res://src/atelier/marqueurs.gd")

const CADRE: Color = Color(0.90, 0.94, 0.97, 0.55)
const CREUX: Color = Color(0.90, 0.94, 0.97, 0.22)
const FOND: Color = Color("0d243d")
const HONORE: Color = Color("ffb454")

const TAILLE: Vector2 = Vector2(132.0, 62.0)
## Rayon d'un creux, en mm. Un peu plus large qu'un sachet, pour qu'il tombe
## dedans sans qu'on ait a viser.
const RAYON_CREUX: float = 19.0
## Distance a laquelle un sachet lache se laisse tomber dans un creux, en mm.
## Large : deposer ne doit pas demander de viser.
const RAYON_DEPOT: float = 34.0

## Ce qui est pose dans chaque creux, ou null.
var occupants: Array[RigidBody2D] = [null, null, null]
## Vrai quand les trois sachets posent la commande entiere, aux tolerances pres.
var honore: bool = false

var _creux: Array[Marker2D] = []
## Le creux ou tomberait le sachet tenu, ou -1. Pur retour visuel.
var _vise: int = -1


func _ready() -> void:
	for i: int in 3:
		var ou: Vector2 = Vector2(28.0 + float(i) * 38.0, TAILLE.y * 0.5)
		_creux.append(Marqueurs.poser(self, "creux_%d" % i, ou, Marqueurs.SUPPORT))


## Le creux que le sachet tenu rejoindrait si on lachait. Retour visuel seulement.
func definir_vise(creux: int) -> void:
	if creux == _vise:
		return
	_vise = creux
	queue_redraw()


## L'indice du creux libre le plus proche de [param monde], ou -1.
func creux_libre(monde: Vector2) -> int:
	var meilleur: int = -1
	var distance: float = RAYON_DEPOT
	for i: int in _creux.size():
		if occupants[i] != null:
			continue
		var ecart: float = _creux[i].global_position.distance_to(monde)
		if ecart < distance:
			distance = ecart
			meilleur = i
	return meilleur


## Pose un sachet dans un creux. Il s'y cale et n'en bouge plus.
func deposer(sachet: RigidBody2D, creux: int) -> void:
	if creux < 0 or creux >= occupants.size():
		return
	occupants[creux] = sachet
	sachet.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	sachet.freeze = true
	sachet.linear_velocity = Vector2.ZERO
	sachet.angular_velocity = 0.0
	queue_redraw()


## Recale les sachets poses, a chaque frame physique.
##
## Ecrire la position une fois ne suffit pas : le serveur physique reecrit la
## transformation d'un corps a la fin du pas, et le sachet retombe a cote de son
## creux. La chaine du ressort est placee de la meme facon, pour la meme raison.
func maintenir() -> void:
	for i: int in occupants.size():
		if occupants[i] == null:
			continue
		occupants[i].global_position = _creux[i].global_position
		occupants[i].linear_velocity = Vector2.ZERO


## Reprend un sachet mal dose. Rend vrai s'il etait bien sur le plateau.
func retirer(sachet: RigidBody2D) -> bool:
	for i: int in occupants.size():
		if occupants[i] != sachet:
			continue
		occupants[i] = null
		sachet.freeze = false
		queue_redraw()
		return true
	return false


func porte(sachet: RigidBody2D) -> bool:
	return occupants.has(sachet)


## La commande est-elle honoree ? Chaque ligne doit trouver SON sachet, et un
## sachet ne peut servir qu'une ligne : deux sachets a 56 g ne valident pas une
## commande qui en demande un de 56 et un de 89.
func evaluer(commande: Array[float], tolerance: float) -> bool:
	var restants: Array[RigidBody2D] = []
	for occupant: RigidBody2D in occupants:
		if occupant == null:
			honore = false
			queue_redraw()
			return false
		restants.append(occupant)

	for voulu: float in commande:
		var trouve: int = -1
		for i: int in restants.size():
			if absf(float(restants[i].get("contenu_g")) - voulu) <= tolerance:
				trouve = i
				break
		if trouve < 0:
			honore = false
			queue_redraw()
			return false
		restants.remove_at(trouve)

	honore = true
	queue_redraw()
	return true


func _draw() -> void:
	var couleur: Color = HONORE if honore else CADRE
	draw_rect(Rect2(Vector2.ZERO, TAILLE), FOND, true)
	draw_rect(Rect2(Vector2.ZERO, TAILLE), couleur, false, 0.8)

	for i: int in _creux.size():
		var ou: Vector2 = _creux[i].position
		if occupants[i] == null:
			# Un creux vide : un cercle en pointille, qui appelle un sachet. Il
			# s'allume quand le sachet tenu tomberait dedans.
			var vide: Color = HONORE if i == _vise else CREUX
			draw_arc(ou, RAYON_CREUX, 0.0, TAU, 28, vide, 1.0 if i == _vise else 0.6)
		else:
			draw_arc(ou, RAYON_CREUX, 0.0, TAU, 28, couleur, 1.0)
