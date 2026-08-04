# Une masse d'etalonnage : la COUCHE FORME. Collision, masse reelle en grammes,
# points d'attache. Elle ne dessine rien et ne change jamais.
#
# Le visuel est un enfant remplacable (visuel_masse.gd) : il prend une texture si
# on en a depose une, sinon il dessine le disque fendu.
#
# Le sachet est une masse comme les autres, avec `sachet = true` : il pend au bout
# du ressort et sa masse AUGMENTE quand on verse dedans. Rien d'autre a prevoir —
# la chaine somme les masses, donc le ressort s'allonge tout seul.
#
# C'EST LUI QUI PORTE LE PIEGE DU NIVEAU, depuis que le crochet a disparu. On
# accroche le sachet vide et on marque son zero la : les graduations valent alors
# pour le contenu, pas pour contenu + emballage. C'est le geste de n'importe qui
# se servant d'une balance, et le piege reste entier — un joueur qui marque son
# zero sur le ressort nu se trompe de la masse du sachet, et rien ne le lui dira.
extends RigidBody2D

const Reglages: GDScript = preload("res://src/atelier/reglages.gd")
const Marqueurs: GDScript = preload("res://src/atelier/marqueurs.gd")
const VisuelMasse: GDScript = preload("res://src/atelier/visuel_masse.gd")

## Rayon en mm. Il sert a la collision et a la prehension, pas au dessin.
var rayon: float = 11.0
## Un contenant qu'on remplit. Sa masse est sa tare plus son contenu.
var sachet: bool = false
## Un etalon porte sa valeur gravee en relief : presse contre le papier, il y
## laisse son chiffre. C'est le seul moyen d'annoter une marque, et sans lui les
## traits du cadran sont anonymes.
var poincon: bool = false
## Ce qu'il y a dedans, en grammes.
var contenu_g: float = 0.0
## Ce que peut contenir un sachet, en grammes. Au-dela, ca deborde.
var capacite_g: float = 165.0
## La masse a vide, relevee a la construction.
var tare_g: float = 0.0
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

	tare_g = mass
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE

	# Les points d'attache, exposes en Marker2D : rien d'autre ne connait ces
	# positions. L'oeillet de suspension depasse un peu du disque, le point bas
	# est la ou pend la masse suivante.
	Marqueurs.poser(self, "crochet", Vector2(0.0, -rayon - 3.5), Marqueurs.SUSPENSION)
	Marqueurs.poser(self, "crochet_bas", Vector2(0.0, rayon), Marqueurs.SUPPORT)
	if sachet:
		# La bouche : le point ou la poudre tombe quand on verse au-dessus.
		Marqueurs.poser(self, "bouche", Vector2(0.0, -rayon), Marqueurs.RECEPTACLE)
		# Un sac ne roule pas : il se pose. Sans ca il finit couche sur l'etabli,
		# bouche vers le mur, et on ne peut plus rien verser dedans.
		lock_rotation = true

	_visuel = VisuelMasse.new()
	_visuel.rayon = rayon
	_visuel.sachet = sachet
	_visuel.masse_g = mass
	add_child(_visuel)


func _physics_process(_delta: float) -> void:
	# Relus a chaque frame pour que le panneau de reglage agisse a chaud. La
	# gravite, elle, vient du projet et vaut 9,81 m/s2 : gravity_scale reste a 1.
	angular_damp = Reglages.FREIN_ROULEMENT
	physics_material_override.bounce = Reglages.REBOND
	physics_material_override.friction = Reglages.FRICTION


## Verse [param grammes] dans le sachet. Rend ce qui est reellement entre : un
## sachet plein deborde, il ne devient pas infini.
func remplir(grammes: float) -> float:
	if not sachet:
		return 0.0
	var recu: float = minf(grammes, capacite_g - contenu_g)
	if recu <= 0.0:
		return 0.0
	contenu_g += recu
	mass = tare_g + contenu_g
	_visuel.remplissage = contenu_g / capacite_g
	_visuel.queue_redraw()
	return recu



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
