# Une masse d'etalonnage : la COUCHE FORME. Collision, masse reelle en grammes,
# points d'attache. Elle ne dessine rien et ne change jamais.
#
# Le visuel est un enfant remplacable (visuel_masse.gd) : il prend une texture si
# on en a depose une, sinon il dessine le disque fendu.
#
# Le crochet est une masse comme les autres, avec `crochet = true` : il pend au
# bout du ressort en permanence, il l'etire de 30 mm a lui tout seul, il balance
# quand on le pousse et il oscille quand on retire un poids. On peut le devisser
# comme n'importe quelle masse — et c'est le geste qui resout le niveau 1.
extends RigidBody2D

const Reglages: GDScript = preload("res://reglages.gd")
const Marqueurs: GDScript = preload("res://marqueurs.gd")
const VisuelMasse: GDScript = preload("res://visuel_masse.gd")

## Rayon en mm. Il sert a la collision et a la prehension, pas au dessin.
var rayon: float = 11.0
var crochet: bool = false
var accrochee: bool = false
var saisie: bool = false
## Vraie quand on la traine dans la zone d'aimantation : c'est le retour visuel
## qui annonce que ca va accrocher.
var prete: bool = false

var _visuel: Node2D = null


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

	# Les points d'attache, exposes en Marker2D : rien d'autre ne connait ces
	# positions. L'oeillet de suspension depasse un peu du disque, le point bas
	# est la ou pend la masse suivante.
	Marqueurs.poser(self, "crochet", Vector2(0.0, -rayon - 3.5), Marqueurs.SUSPENSION)
	Marqueurs.poser(self, "crochet_bas", Vector2(0.0, rayon), Marqueurs.SUPPORT)
	Marqueurs.poser(self, "porte_stylo", Vector2.ZERO, Marqueurs.PORTE_STYLO)

	_visuel = VisuelMasse.new()
	_visuel.rayon = rayon
	_visuel.crochet = crochet
	_visuel.masse_g = mass
	add_child(_visuel)


func _physics_process(_delta: float) -> void:
	# Relus a chaque frame pour que le panneau de reglage agisse a chaud. La
	# gravite, elle, vient du projet et vaut 9,81 m/s2 : gravity_scale reste a 1.
	angular_damp = Reglages.FREIN_ROULEMENT
	physics_material_override.bounce = Reglages.REBOND
	physics_material_override.friction = Reglages.FRICTION
	if crochet:
		mass = Reglages.MASSE_CROCHET


## Le visuel suit l'etat de la forme. Appele a chaque changement d'etat.
func rafraichir() -> void:
	if _visuel == null:
		return
	_visuel.accrochee = accrochee
	_visuel.saisie = saisie
	_visuel.prete = prete
	_visuel.queue_redraw()


func point_accroche() -> Vector2:
	return Marqueurs.position_de(self, "crochet")


func point_bas() -> Vector2:
	return Marqueurs.position_de(self, "crochet_bas")
