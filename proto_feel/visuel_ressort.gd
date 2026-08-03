# Le visuel du ressort : la COUCHE VISIBLE, remplacable. La physique du ressort
# est ailleurs (atelier.gd) et ne sait rien de ce fichier.
#
# C'est un Line2D, pour la raison donnee au brief : deposer `textures/ressort.png`
# le passe en mode repetition, et les spires suivent l'allongement sans qu'on
# redessine quoi que ce soit. Sans texture, le meme Line2D porte le zigzag
# procedural d'avant.
#
# Compromis assume du mode repetition : la tuile garde sa taille, donc un ressort
# qui s'allonge gagne des tours au lieu d'ecarter les siens. C'est le
# comportement natif de Line2D ; l'autre option (etirer une tuile unique) rend
# une image floue et une spire deformee, ce qui est pire.
extends Line2D

const Reglages: GDScript = preload("res://reglages.gd")
const Textures: GDScript = preload("res://textures.gd")

const COULEUR: Color = Color("6fd3ff")

var _texture: Texture2D = null


func _ready() -> void:
	antialiased = true
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	default_color = COULEUR

	_texture = Textures.charger("ressort")
	if _texture != null:
		texture = _texture
		texture_mode = Line2D.LINE_TEXTURE_TILE
		default_color = Color.WHITE


## Le ressort se dessine le long de son axe courant : penche s'il est penche.
## Les spires s'ecartent quand il s'etire et se pincent lateralement. Le ballant
## est un arc perpendiculaire a l'axe, nourri par la composante laterale de la
## vitesse — un ressort qui balance n'est pas droit.
func mettre_a_jour(ancre: Vector2, extremite: Vector2, vitesse: Vector2) -> void:
	var axe: Vector2 = extremite - ancre
	var longueur: float = maxf(axe.length(), 0.001)
	var direction: Vector2 = axe / longueur
	var normale: Vector2 = direction.orthogonal()

	var v_laterale: float = vitesse.dot(normale)
	var ballant: float = clampf(v_laterale * Reglages.BALLANT, -13.0, 13.0)

	if _texture != null:
		_tracer_texture(ancre, extremite, direction, normale, longueur, ballant)
		return
	_tracer_spires(ancre, extremite, direction, normale, longueur, ballant)


## Avec texture : une ligne lisse dont la largeur est le diametre des spires,
## et dont la tuile se repete d'elle-meme sur toute la longueur.
func _tracer_texture(
	ancre: Vector2,
	extremite: Vector2,
	direction: Vector2,
	normale: Vector2,
	longueur: float,
	ballant: float
) -> void:
	width = Reglages.LARGEUR_SPIRE * 2.0
	var troncons: int = 12
	var trace: PackedVector2Array = PackedVector2Array()
	for i: int in troncons + 1:
		var t: float = float(i) / float(troncons)
		trace.append(ancre + direction * (longueur * t) + normale * (ballant * sin(PI * t)))
	trace[trace.size() - 1] = extremite
	points = trace


## Sans texture : le zigzag d'avant, porte par le meme noeud.
func _tracer_spires(
	ancre: Vector2,
	extremite: Vector2,
	direction: Vector2,
	normale: Vector2,
	longueur: float,
	ballant: float
) -> void:
	width = 1.0
	var etirement: float = longueur / maxf(Reglages.LONGUEUR_REPOS, 1.0)
	var largeur: float = Reglages.LARGEUR_SPIRE / sqrt(maxf(etirement, 0.35))

	var trace: PackedVector2Array = PackedVector2Array()
	trace.append(ancre)
	for i: int in Reglages.SPIRES + 1:
		var t: float = float(i) / float(Reglages.SPIRES)
		var cote: float = largeur * (1.0 if i % 2 == 0 else -1.0)
		# Arc de ballant : nul aux deux extremites, maximal au milieu.
		trace.append(ancre + direction * (longueur * t) + normale * (cote + ballant * sin(PI * t)))
	trace.append(extremite)
	points = trace
