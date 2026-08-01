# Une masse : un disque fendu, comme un poids d'etalonnage.
extends RigidBody2D

const Reglages: GDScript = preload("res://reglages.gd")

const FOND: Color = Color("0d243d")
const TRAIT: Color = Color("e6f0f8")
const TRAIT_EFFACE: Color = Color(0.90, 0.94, 0.97, 0.45)
const SAISIE: Color = Color("6fd3ff")
const PRETE: Color = Color("ffb454")

var rayon: float = 22.0
## Le crochet se dessine ouvert, et il a sa propre masse : le ressort n'est donc
## jamais tout a fait au repos. On peut le devisser comme n'importe quelle masse.
var crochet: bool = false
var accrochee: bool = false
var saisie: bool = false
## Vraie quand on la traine dans la zone d'aimantation : c'est le retour visuel
## qui annonce que ca va accrocher.
var prete: bool = false


func _ready() -> void:
	var forme: CircleShape2D = CircleShape2D.new()
	forme.radius = rayon
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = forme
	add_child(collision)

	var matiere: PhysicsMaterial = PhysicsMaterial.new()
	matiere.bounce = Reglages.REBOND
	matiere.friction = Reglages.FRICTION
	physics_material_override = matiere

	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE


func _physics_process(_delta: float) -> void:
	# Relus a chaque frame pour que le panneau de reglage agisse a chaud.
	gravity_scale = Reglages.GRAVITE / 980.0
	angular_damp = Reglages.FREIN_ROULEMENT
	physics_material_override.bounce = Reglages.REBOND
	physics_material_override.friction = Reglages.FRICTION


func _draw() -> void:
	var couleur: Color = TRAIT
	if prete:
		couleur = PRETE
	elif saisie:
		couleur = SAISIE

	if crochet:
		# Un S ouvert : la partie basse reste libre, c'est la qu'on accroche.
		draw_arc(Vector2(0.0, -rayon * 0.45), rayon * 0.55, PI, TAU, 20, couleur, 2.5)
		draw_arc(Vector2(0.0, rayon * 0.35), rayon * 0.62, -PI * 0.85, PI * 0.85, 24, couleur, 2.5)
		return

	draw_circle(Vector2.ZERO, rayon, FOND)
	draw_arc(Vector2.ZERO, rayon, 0.0, TAU, 40, couleur, 2.0)
	draw_arc(Vector2.ZERO, rayon * 0.42, 0.0, TAU, 24, TRAIT_EFFACE, 1.0)

	# La fente laterale des poids fendus : c'est elle qui rend la rotation lisible
	# quand la masse roule.
	draw_line(
		Vector2(0.0, -rayon * 0.42), Vector2(0.0, -rayon), TRAIT_EFFACE, 1.0
	)

	# L'anneau de suspension, en haut.
	draw_arc(Vector2(0.0, -rayon), 7.0, PI, TAU, 16, couleur, 2.0)


func point_accroche() -> Vector2:
	return global_position + Vector2(0.0, -rayon - 7.0)


func point_bas() -> Vector2:
	return global_position + Vector2(0.0, rayon)
