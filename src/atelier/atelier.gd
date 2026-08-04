# Le niveau 1, et pour l'instant tout le jeu.
#
# Une commande : trois sachets de poudre a 56, 89 et 143 g. La balance de
# l'atelier a un pas de 100 g, elle ne sert a rien. Le joueur a un ressort, des
# masses etalons, des sachets, un pointeau, une feuille, une regle et un pot.
#
# UNE SEULE ACTION PAR ZONE, ET LE SURVOL LA DIT. C'est la regle qui gouverne
# toute la manipulation : si le joueur doit deviner ce qu'un clic va faire, c'est
# rate. Chaque objet a des zones nettes, visuellement distinctes, qui s'allument
# au survol, et le curseur change avec elles.
#
# Il clipse le pointeau au bout du ressort, accroche le SACHET VIDE et frappe :
# un trait franc marque son zero. Les graduations vaudront donc pour le contenu,
# pas pour contenu + emballage — c'est le geste de n'importe qui se servant d'une
# balance, et c'est la que le piege se cache : marquer son zero sur le ressort nu
# fausse tout de la masse du sachet.
#
# Puis il pend un etalon sous le sachet, frappe, et presse l'etalon contre le
# papier pour graver son chiffre a cote du trait. LA FEUILLE NE BOUGE PAS : les
# marques s'empilent sur une meme verticale et forment un cadran, pas un nuage de
# points.
#
# Verser jusqu'a une marque ne demande alors ni regle ni calcul. La regle et le
# compas ne servent qu'a fabriquer les graduations qui manquent — 56, 89, 143 —
# c'est-a-dire la ou le geste mathematique compte vraiment.
#
# Le livrable du niveau n'est pas une equation. C'est un cadran gradue a la main,
# et trois sachets poses sur le plateau. Rien n'affiche de pourcentage : le
# verdict, c'est ce qui est sur la table.
#
# TOUT EST EN MILLIMETRES, GRAMMES ET SECONDES. Pas une ligne de ce fichier ne
# connait le pixel : la seule mention de l'ecran est le zoom de la Camera2D,
# monte une fois au demarrage. Changer la resolution ne change donc rien au
# comportement — en 1152 x 648 comme en 4K, la meme etendue de monde est cadree
# et la meme physique tourne.
#
# Physique hybride : les masses libres sont des RigidBody2D (chute, rebond,
# empilement, roulement — le moteur le fait mieux et gratuitement), le ressort
# est integre a la main. Un PinJoint2D chaine donnerait un pendule mou
# impossible a regler ; deux constantes lisibles se reglent en dix secondes.
#
# Le ressort est libre dans le plan : sa force s'applique le long de son axe
# courant, la gravite reste verticale. Le balancement n'est pas code, il tombe
# de la combinaison des deux.
extends Node2D

const Unites: GDScript = preload("res://src/atelier/unites.gd")
const Reglages: GDScript = preload("res://src/atelier/reglages.gd")
const Marqueurs: GDScript = preload("res://src/atelier/marqueurs.gd")
const Masse: GDScript = preload("res://src/atelier/masse.gd")
const Feuille: GDScript = preload("res://src/atelier/feuille.gd")
const Regle: GDScript = preload("res://src/atelier/regle.gd")
const Pointeau: GDScript = preload("res://src/atelier/pointeau.gd")
const Verseuse: GDScript = preload("res://src/atelier/verseuse.gd")
const Enonce: GDScript = preload("res://src/atelier/enonce.gd")
const Plateau: GDScript = preload("res://src/atelier/plateau.gd")
const VisuelEtabli: GDScript = preload("res://src/atelier/visuel_etabli.gd")
const VisuelRessort: GDScript = preload("res://src/atelier/visuel_ressort.gd")
const PanneauReglages: GDScript = preload("res://src/atelier/panneau_reglages.gd")

const FOND: Color = Color("0d243d")
const TRAIT: Color = Color("e6f0f8")
const TRAIT_EFFACE: Color = Color(0.90, 0.94, 0.97, 0.45)
const PRETE: Color = Color("ffb454")

## Point de suspension du ressort, en mm.
const ANCRE: Vector2 = Vector2(350.0, 28.0)
## Hauteur du plan de travail, en mm. Basse expres : a pleine charge, le ressort
## et ce qui pend dessous doivent tenir au-dessus de l'etabli.
const SOL: float = 336.0
## Jeu entre deux masses de la chaine, en mm.
const ESPACE_CHAINE: float = 2.5
## Le ressort ne se comprime pas au-dela, en mm.
const LONGUEUR_MIN: float = 12.0

## Le jeu de masses d'etalonnage, en grammes.
##
## INVARIANT FATAL, ET INVISIBLE SI ON LE CASSE : aucune ligne du bon de travail
## ne doit etre atteignable en additionnant des etalons. Avec 10/20/50/100 les
## sommes possibles sont 0, 10, 20, 30, 50, 60, 70, 80, 100, 110, 120, 130, 150,
## 160, 170, 180 — ni 56, ni 89, ni 143 n'y sont.
##
## Un seul etalon de plus peut tuer le niveau sans que rien ne le signale : 6 g
## donnerait 56, 39 g donnerait 89, 43 g donnerait 143. Le joueur poserait alors
## la bonne masse au lieu de graduer son cadran, et le niveau n'aurait plus de
## sujet. VERIFIER TOUTES LES SOMMES AVANT DE TOUCHER A CETTE LISTE.
##
## Le 10 g est indispensable : c'est lui qui permet de construire des graduations
## fines entre deux marques larges.
const MASSES_G: Array[float] = [10.0, 20.0, 50.0, 100.0]

## Tolerance d'acceptation d'un sachet, en grammes. A 1,3728 mm par gramme,
## 2 g valent 2,75 mm sur le cadran : c'est lisible a l'oeil, serre a verser.
const TOLERANCE_G: float = 2.0

## Masse a vide d'un sachet, en grammes. C'EST LE PIEGE DU NIVEAU : le zero se
## marque sachet vide accroche, sinon on se trompe de cette masse-la.
const TARE_SACHET: float = 12.0

## Nombre de sachets fournis : autant que la commande en demande.
const SACHETS: int = 3

## Duree de pression d'un poincon contre le papier avant qu'il marque, en s.
const DUREE_TAMPON: float = 0.45
## Vitesse du curseur en dessous de laquelle on considere qu'on appuie, en mm/s.
## Au-dessus, on est en train de deplacer la masse, pas de tamponner.
const VITESSE_TAMPON: float = 22.0
## Distance a laquelle un poincon trouve la marque qu'il annote, en mm.
const PORTEE_TAMPON: float = 20.0

# --- Etat du ressort, libre dans le plan -------------------------------------

var _extremite: Vector2 = ANCRE + Vector2(0.0, Reglages.LONGUEUR_REPOS)
var _vitesse: Vector2 = Vector2.ZERO
var _butee: bool = false
var _butee_angle: float = 0.0

# --- Objets ------------------------------------------------------------------

var _chaine: Array[RigidBody2D] = []
var _libres: Array[RigidBody2D] = []
## Direction courante de chaque maillon, en retard sur la precedente : c'est le
## flottement entre deux masses empilees.
var _directions: Array[Vector2] = []

var _feuille: Node2D = null
var _pointeau: Node2D = null
var _regle: Node2D = null
var _ressort: Line2D = null
var _bout_ressort: Marker2D = null
var _porte_pointeau: Marker2D = null
var _verseuse: Node2D = null
var _plateau: Node2D = null
var _enonce: Node2D = null

# --- Saisie ------------------------------------------------------------------

var _saisie: RigidBody2D = null
var _saisie_index: int = -1
var _offset_saisie: Vector2 = Vector2.ZERO
var _cible: Vector2 = Vector2.ZERO
var _point_aimant: Vector2 = Vector2.ZERO
var _aimant_actif: bool = false
## Ce que le curseur traine qui n'est pas une masse : le pointeau, la regle, le pot.
var _outil_saisi: Node2D = null
var _clipsage_vise: Node2D = null
## La bouche vers laquelle la poudre coule en ce moment, pour dessiner le filet.
var _cible_versage: Marker2D = null
## Ou la poudre deborde d'un sachet plein, pour que ca se voie.
var _debordement: Vector2 = Vector2.INF
## Duree de pression accumulee du poincon contre le papier, en secondes.
var _pression: float = 0.0
var _tampon_pose: bool = false
var _cible_precedente: Vector2 = Vector2.ZERO


func _ready() -> void:
	_construire_camera()
	_construire_etabli()
	_construire_instruments()
	_construire_masses()
	_construire_poudre()
	add_child(PanneauReglages.new())


# --- Construction ------------------------------------------------------------


## Le cadrage est un probleme de camera, pas de simulation. Le monde fait
## 640 x 360 mm quelle que soit la resolution ; c'est la camera qui le ramene a
## l'ecran, et elle est le seul endroit du prototype ou un pixel apparait.
func _construire_camera() -> void:
	var camera: Camera2D = Camera2D.new()
	camera.position = Unites.centre()
	camera.zoom = Unites.zoom_camera()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	add_child(camera)
	camera.make_current()


func _construire_etabli() -> void:
	for donnee: Array in [
		[Vector2(320.0, SOL + 20.0), Vector2(700.0, 40.0)],
		[Vector2(-15.0, 180.0), Vector2(30.0, 450.0)],
		[Vector2(655.0, 180.0), Vector2(30.0, 450.0)],
	]:
		var mur: StaticBody2D = StaticBody2D.new()
		mur.position = donnee[0]
		var forme: RectangleShape2D = RectangleShape2D.new()
		forme.size = donnee[1]
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.shape = forme
		mur.add_child(collision)
		var matiere: PhysicsMaterial = PhysicsMaterial.new()
		matiere.bounce = Reglages.REBOND
		matiere.friction = Reglages.FRICTION
		mur.physics_material_override = matiere
		add_child(mur)


func _construire_instruments() -> void:
	# Le fond est un noeud a part, et non un draw_rect de cet ecran : un enfant en
	# z negatif passe DERRIERE le dessin de son parent, donc un fond peint ici
	# recouvrirait la feuille au lieu de la laisser voir.
	var fond: ColorRect = ColorRect.new()
	fond.color = FOND
	fond.size = Unites.MONDE
	fond.z_index = -20
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)

	# La feuille est punaisee derriere le ressort, devant le fond.
	_feuille = Feuille.new()
	_feuille.position = Vector2(150.0, 70.0)
	_feuille.z_index = -10
	add_child(_feuille)

	var etabli: Node2D = VisuelEtabli.new()
	etabli.ancre = ANCRE
	etabli.sol = SOL
	etabli.z_index = -5
	add_child(etabli)

	_ressort = VisuelRessort.new()
	_ressort.z_index = -4
	add_child(_ressort)

	# L'extremite du ressort est un marqueur comme les autres : c'est a lui que la
	# premiere masse de la chaine vient se pendre.
	_bout_ressort = Marqueurs.poser(self, "extremite_ressort", _extremite, Marqueurs.SUPPORT)
	# Le pointeau se clipse ICI ET NULLE PART AILLEURS. Une seule cible possible,
	# donc aucune ambiguite : peu importe ce qui pend, les marques se referent
	# toujours a la meme extremite et restent comparables entre elles.
	_porte_pointeau = Marqueurs.poser(
		self, "porte_pointeau", _extremite, Marqueurs.PORTE_STYLO
	)

	_regle = Regle.new()
	_regle.position = Vector2(215.0, 264.0)
	_regle.z_index = 6
	add_child(_regle)

	_pointeau = Pointeau.new()
	# A gauche des etalons : sa zone de prehension mordrait sinon sur un poids.
	_pointeau.position = Vector2(262.0, SOL - 12.0)
	_pointeau.z_index = 7
	add_child(_pointeau)

	# La loupe n'est plus du kit : a cette raideur, lire au millimetre suffit et
	# ne demande aucun grossissement. Elle reviendra au niveau 6, quand le bruit
	# de mesure rendra la precision fine reellement necessaire. Le code reste
	# (loupe.gd), il ne coute rien tant qu'on ne l'instancie pas.

	_enonce = Enonce.new()
	_enonce.position = Vector2(10.0, 40.0)
	_enonce.z_index = -6
	add_child(_enonce)

	# Le plateau de livraison : la fin de la boucle, posee sur l'etabli.
	_plateau = Plateau.new()
	_plateau.position = Vector2(10.0, 218.0)
	_plateau.z_index = -5
	add_child(_plateau)


func _construire_masses() -> void:
	var x: float = 420.0
	var rang: int = 0
	for m: float in MASSES_G:
		var rayon: float = _rayon_de(m)
		# Sa valeur est gravee en relief : presse contre le papier, il la tamponne.
		_nouvelle_masse(
			m, rayon, Vector2(x, SOL - rayon - 1.0 - float(rang) * 60.0), false, true
		)
		x += rayon * 2.0 + 6.0
		if x > 625.0:
			x = 420.0
			rang += 1


## Le pot de poudre et les sachets vides. C'est tout ce que le versage demande :
## on incline le pot au-dessus d'un sachet, la poudre coule, la masse accrochee
## augmente et le stylo descend.
func _construire_poudre() -> void:
	_verseuse = Verseuse.new()
	_verseuse.position = Vector2(78.0, SOL - Verseuse.HAUTEUR * 0.5 - 1.0)
	_verseuse.z_index = 8
	add_child(_verseuse)

	for i: int in SACHETS:
		_nouvelle_masse(
			TARE_SACHET, 16.0, Vector2(150.0 + float(i) * 38.0, SOL - 17.0), true
		)


## Rayon d'un poids en fonction de sa masse, en mm.
##
## Un vrai jeu de poids est geometriquement semblable : le rayon suit la racine
## cubique de la masse. On garde cette loi, avec un socle de 3 mm pour que les
## petits restent attrapables a la souris. Le coefficient est calibre pour que le
## poids de 150 g pendu au bout du ressort tienne encore au-dessus de l'etabli.
func _rayon_de(masse_g: float) -> float:
	return 3.0 + 4.2 * pow(maxf(masse_g, 0.01), 1.0 / 3.0)


## La forme se decrit AVANT d'entrer dans l'arbre : c'est a ce moment-la que la
## masse construit sa collision, ses marqueurs et son visuel.
func _nouvelle_masse(
	masse_g: float,
	rayon: float,
	ou: Vector2,
	est_sachet: bool = false,
	est_poincon: bool = false
) -> RigidBody2D:
	var corps: RigidBody2D = Masse.new()
	corps.rayon = rayon
	corps.mass = masse_g
	corps.position = ou
	corps.sachet = est_sachet
	corps.poincon = est_poincon
	add_child(corps)
	_libres.append(corps)
	return corps


# --- Boucle physique ---------------------------------------------------------


func _physics_process(delta: float) -> void:
	_cible = get_global_mouse_position()

	if _saisie != null and _saisie_index >= 0:
		_tirer_la_chaine(delta)
	else:
		_integrer_ressort(delta)

	_bout_ressort.position = _extremite
	_porte_pointeau.position = _extremite
	_ressort.mettre_a_jour(ANCRE, _extremite, _vitesse)
	_poser_la_chaine(delta)
	_traine_au_curseur()
	_detecter_aimantation()
	_detecter_chocs()
	_verser(delta)
	_plateau.maintenir()
	_presser_le_poincon(delta)
	_animer_pointeau()
	_cible_precedente = _cible

	_butee_angle = lerpf(_butee_angle, -1.15 if _butee else 0.0, 1.0 - pow(0.001, delta))
	queue_redraw()


## Le ressort, libre dans le plan.
##
## La force de rappel s'applique le long de l'axe ancrage -> extremite, quelle que
## soit son orientation. La gravite vaut 9,81 m/s2 et reste verticale. C'est la
## combinaison des deux qui produit le pendule, l'ellipse molle et le depart en
## travers, sans qu'aucun de ces comportements soit ecrit quelque part.
##
## L'amortissement est decompose sur l'axe et perpendiculairement a lui, pour que
## le yoyo et le balancement se reglent separement.
func _integrer_ressort(delta: float) -> void:
	var masse: float = _masse_inertielle()
	var pesante: float = _masse_pesante()
	var axial: float = Reglages.AMORTISSEMENT
	var lateral: float = Reglages.AMORTISSEMENT_LATERAL
	if _butee:
		axial = Reglages.AMORTISSEMENT_BUTEE
		lateral = Reglages.AMORTISSEMENT_BUTEE

	var pas: float = delta / 4.0
	for i: int in 4:
		var axe: Vector2 = _extremite - ANCRE
		var longueur: float = maxf(axe.length(), 0.001)
		var direction: Vector2 = axe / longueur

		# Projection de la vitesse sur l'axe et sur sa perpendiculaire.
		var v_axiale: Vector2 = direction * _vitesse.dot(direction)
		var v_laterale: Vector2 = _vitesse - v_axiale

		var force: Vector2 = (
			-direction * Reglages.RAIDEUR * (longueur - Reglages.LONGUEUR_REPOS)
			+ Vector2.DOWN * pesante * Unites.GRAVITE
			# L'axial est normalise en racine de la masse : sans cela le taux
			# d'amortissement croit avec la charge, et le meme reglage donne un
			# retour claquant a vide et sirupeux en charge. Le lateral garde sa
			# normalisation d'origine, son reglage etant valide tel quel.
			- v_axiale * axial * sqrt(masse)
			- v_laterale * lateral * masse
		)
		_vitesse += (force / masse) * pas
		_extremite += _vitesse * pas

	_contraindre_longueur()
	_endormir()


## Masse qui fixe la frequence : la charge, plus le tiers du fil du ressort.
## C'est le resultat classique du ressort pesant.
func _masse_inertielle() -> float:
	return Reglages.MASSE_RESSORT / 3.0 + _masse_chaine()


## Masse qui tire vers le bas : la charge, plus la moitie du fil. Un ressort
## pesant s'etire deja tout seul, sans rien accroche — et le crochet ajoute la
## sienne par-dessus.
func _masse_pesante() -> float:
	return Reglages.MASSE_RESSORT / 2.0 + _masse_chaine()


## Le ressort ne se retourne pas sur lui-meme.
func _contraindre_longueur() -> void:
	var axe: Vector2 = _extremite - ANCRE
	if axe.length() < LONGUEUR_MIN:
		var direction: Vector2 = axe.normalized() if axe.length() > 0.001 else Vector2.DOWN
		_extremite = ANCRE + direction * LONGUEUR_MIN
		_vitesse -= direction * minf(_vitesse.dot(direction), 0.0)


## Sans ce seuil le ressort fremit indefiniment, ce qui est insupportable quand
## on essaie de lire une position au millimetre — et maintenant le millimetre est
## un vrai millimetre du monde.
##
## Le critere porte sur l'amplitude restante de l'oscillation, ecart et vitesse
## combines, et non sur les deux pris separement : un ressort qui passe vite par
## sa position d'equilibre n'est pas au repos, et un ressort momentanement arrete
## au sommet de sa course non plus. Exiger les deux petits au meme instant
## retardait l'endormissement de plus d'une seconde, et c'est ce qui donnait
## l'impression de sirop bien plus que l'amortissement lui-meme.
func _endormir() -> void:
	var repos: Vector2 = ANCRE + Vector2.DOWN * _longueur_equilibre()
	var pulsation: float = sqrt(maxf(Reglages.RAIDEUR, 1.0) / maxf(_masse_inertielle(), 0.01))
	var amplitude: float = Vector2(
		_extremite.distance_to(repos), _vitesse.length() / pulsation
	).length()
	if amplitude > Reglages.SEUIL_REPOS:
		return
	_extremite = repos
	_vitesse = Vector2.ZERO


## On tient une masse accrochee : l'extremite suit le curseur, dans le plan.
## Tirer un peu et lacher relance l'oscillation ; tirer trop fait lacher la prise.
func _tirer_la_chaine(delta: float) -> void:
	var precedente: Vector2 = _extremite
	_extremite = _extremite.lerp(_cible - _offset_saisie, 1.0 - pow(0.000001, delta))
	_contraindre_longueur()
	_vitesse = (_extremite - precedente) / maxf(delta, 0.0001)

	if (_extremite - ANCRE).length() - _longueur_equilibre() > Reglages.SEUIL_DECROCHAGE:
		_decrocher_a_partir_de(_saisie_index)


func _poser_la_chaine(delta: float) -> void:
	var axe: Vector2 = _extremite - ANCRE
	var direction: Vector2 = axe.normalized() if axe.length() > 0.001 else Vector2.DOWN

	_directions.resize(_chaine.size())
	var suivi: float = 1.0 - pow(clampf(1.0 - Reglages.SOUPLESSE_CHAINE, 0.001, 0.999), delta * 60.0)

	var point: Vector2 = _extremite
	var precedente: Vector2 = direction
	for i: int in _chaine.size():
		# Chaque maillon rattrape la direction du precedent avec un peu de retard :
		# deux masses empilees balancent ensemble, mais pas tout a fait en phase.
		if _directions[i] == Vector2.ZERO:
			_directions[i] = precedente
		_directions[i] = _directions[i].lerp(precedente, suivi).normalized()

		var corps: RigidBody2D = _chaine[i]
		var rayon: float = corps.rayon
		corps.global_position = point + _directions[i] * rayon
		corps.linear_velocity = _vitesse
		point += _directions[i] * (rayon * 2.0 + ESPACE_CHAINE)
		precedente = _directions[i]


## La traine au curseur. L'amortissement est en racine de la masse pour que le
## temps de reponse depende du poids sans que les petites masses deviennent
## pateuses — c'est tout l'interet du reglage.
func _traine_au_curseur() -> void:
	if _saisie == null or _saisie_index >= 0:
		return
	var masse: float = _saisie.mass
	var vers: Vector2 = _cible - _offset_saisie - _saisie.global_position
	var force: Vector2 = (
		vers * Reglages.RAIDEUR_CURSEUR
		- _saisie.linear_velocity * Reglages.AMORTISSEMENT_CURSEUR * sqrt(masse)
		+ Vector2.UP * Unites.GRAVITE * masse * Reglages.COMPENSATION_POIDS
	)
	if _aimant_actif:
		var vers_aimant: Vector2 = _point_aimant - _saisie.point_accroche()
		force += vers_aimant.normalized() * Reglages.FORCE_AIMANTATION * masse
	_saisie.apply_central_force(force)


## L'aimantation se juge sur la position du POINTEUR, pas sur celle de l'objet.
## Une masse lourde traine loin derriere le curseur : si on testait l'objet,
## l'assistance ne se declencherait jamais au moment ou le joueur vise.
func _detecter_aimantation() -> void:
	_aimant_actif = false
	if _saisie == null or _saisie_index >= 0:
		return
	_point_aimant = _point_libre()
	var vise: Vector2 = _cible - _offset_saisie + Vector2(0.0, -_saisie.rayon)
	_aimant_actif = vise.distance_to(_point_aimant) < Reglages.RAYON_AIMANTATION
	_saisie.prete = _aimant_actif
	_saisie.rafraichir()


## Une masse qui percute la chaine relance l'oscillation — dans la direction du
## choc, donc un coup de cote fait balancer. Le seuil est en mm/s.
func _detecter_chocs() -> void:
	if _chaine.is_empty():
		return
	for corps: RigidBody2D in _libres:
		if corps == _saisie or corps.linear_velocity.length() < 70.0:
			continue
		for maillon: RigidBody2D in _chaine:
			var portee: float = corps.rayon + maillon.rayon + 3.0
			if corps.global_position.distance_to(maillon.global_position) < portee:
				_vitesse += (
					corps.linear_velocity
					* Reglages.TRANSMISSION_CHOC
					* corps.mass
					/ maxf(_masse_chaine(), 1.0)
				)
				corps.linear_velocity *= -Reglages.REBOND
				break


# --- Versage -----------------------------------------------------------------


## La poudre tombe du goulot vers la bouche du sachet le plus proche en dessous.
## Aucun cas particulier : le sachet est une masse comme une autre, et comme il
## pend a la chaine, le ressort s'allonge tout seul pendant qu'il se remplit.
func _verser(delta: float) -> void:
	_cible_versage = null
	_debordement = Vector2.INF
	if _verseuse == null or not _verseuse.coule():
		return
	var bouche: Marker2D = _bouche_sous_le_bec(_verseuse.goulot())
	if bouche == null:
		return
	_cible_versage = bouche
	# Ce qui sort du pot ne rentre pas forcement. Un sachet plein deborde, et ca
	# DOIT se voir : sinon la poudre disparait en silence et le joueur croit
	# remplir alors qu'il gaspille.
	var sorti: float = _verseuse.prelever(delta)
	var entre: float = float(bouche.get_parent().call("remplir", sorti))
	if sorti - entre > 0.0001:
		_debordement = bouche.global_position


## La bouche qui se trouve SOUS le bec, et la plus proche. La poudre tombe droit :
## viser est le geste, et un sac a cote ne recoit rien.
func _bouche_sous_le_bec(goulot: Vector2) -> Marker2D:
	var meilleure: Marker2D = null
	var chute: float = Verseuse.CHUTE_MAX
	for corps: RigidBody2D in _chaine + _libres:
		var bouche: Marker2D = Marqueurs.nomme(corps, "bouche")
		if bouche == null:
			continue
		var ecart: Vector2 = bouche.global_position - goulot
		if absf(ecart.x) > Verseuse.LARGEUR_FILET or ecart.y <= 0.0 or ecart.y > chute:
			continue
		chute = ecart.y
		meilleure = bouche
	return meilleure


# --- Poincon -----------------------------------------------------------------


## Presser un etalon contre le papier y grave son chiffre.
##
## Le geste est celui d'un tampon : on amene la masse sur le papier et on APPUIE,
## c'est-a-dire qu'on arrete de bouger. Il fallait un geste qui ne se declenche
## pas quand on pose simplement un poids sur la feuille en passant — d'ou le seuil
## de vitesse et le temps de pression, et l'arc qui se remplit pour qu'on voie
## venir la marque au lieu de la subir.
##
## Sans ce tampon les traits du cadran sont anonymes : trois traits sur un papier,
## rien ne dit lequel est le 50. Un releve sans annotation n'est pas une mesure.
func _presser_le_poincon(delta: float) -> void:
	if _saisie == null or _saisie_index >= 0 or not _saisie.poincon:
		_pression = 0.0
		_tampon_pose = false
		return

	# PRIORITE STRICTE : pres du point d'accroche, on accroche ; ailleurs sur le
	# papier, on annote. Les deux zones se recouvrent dans l'espace — les marques
	# tombent juste au-dessus du crochet — et sans cette regle, tamponner une
	# marque rependait la masse au ressort. L'anneau d'aimantation est deja
	# dessine : le joueur voit laquelle des deux actions est armee.
	if _aimant_actif:
		_pression = 0.0
		_tampon_pose = false
		return

	# TOUT SE JUGE SUR LE POINTEUR, jamais sur la masse. Une masse lourde flotte
	# loin du curseur — le poids est compense aux trois quarts, donc un poids de
	# 100 g plane 85 mm au-dessus du point vise — et la tester ferait rater la
	# marque que le joueur vise. C'est la meme raison qu'a l'aimantation du
	# crochet et qu'au depot sur le plateau.
	var vise: Vector2 = _cible - _offset_saisie
	var vitesse: float = (_cible - _cible_precedente).length() / maxf(delta, 0.0001)
	if not _feuille.contient(vise) or vitesse > VITESSE_TAMPON:
		_pression = 0.0
		_tampon_pose = false
		return
	if _tampon_pose:
		return

	# Sans marque a portee, on n'arme meme pas : un chiffre pose dans le vide
	# n'annote rien. L'arc ne se remplit que quand le tampon a quelque chose a
	# annoter, ce qui dit au joueur ou amener sa masse.
	if _feuille.marque_proche(vise, PORTEE_TAMPON) == Vector2.INF:
		_pression = 0.0
		return

	_pression += delta
	if _pression < DUREE_TAMPON:
		return
	# Le chiffre SE COLLE A LA MARQUE, il ne se pose pas ou la main a lache.
	_tampon_pose = _feuille.tamponner(
		vise, "%d" % int(round(_saisie.mass)), PORTEE_TAMPON
	)


# --- Pointeau ----------------------------------------------------------------


## Le pointeau suit ce a quoi il est clipse. Il ne trace RIEN tout seul : il ne
## marque que quand on frappe sa tete. Un instrument qui ecrit en permanence
## laisse une trainee, pas des reperes.
func _animer_pointeau() -> void:
	if _pointeau == null:
		return
	if _pointeau.tenu:
		_pointeau.global_position = _cible - _offset_saisie
	elif _pointeau.support != null and is_instance_valid(_pointeau.support):
		_pointeau.global_position = _pointeau.support.global_position + _pointeau.decalage


## Un coup sec : un trait franc a la hauteur courante, et rien de plus.
func _frapper() -> void:
	var bouts: Array[Vector2] = _pointeau.frapper()
	_feuille.marquer_trait(bouts[0], bouts[1])


# --- Accrochage --------------------------------------------------------------


func _accrocher(corps: RigidBody2D, sursaut: bool = true) -> void:
	corps.global_position = _point_libre() + Vector2(0.0, corps.rayon)
	_libres.erase(corps)
	_chaine.append(corps)
	_directions.append(Vector2.DOWN)
	corps.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	corps.freeze = true
	corps.accrochee = true
	corps.prete = false
	corps.rafraichir()
	if sursaut:
		_vitesse += Vector2.DOWN * Reglages.AMPLITUDE_SURSAUT * corps.mass / maxf(_masse_chaine(), 1.0)


func _decrocher_a_partir_de(index: int) -> void:
	if index < 0 or index >= _chaine.size():
		return
	var vitesse: Vector2 = _vitesse.limit_length(450.0)
	var direction: Vector2 = (_extremite - ANCRE).normalized()
	while _chaine.size() > index:
		var corps: RigidBody2D = _chaine.pop_back()
		corps.freeze = false
		corps.accrochee = false
		corps.linear_velocity = vitesse
		corps.rafraichir()
		_libres.append(corps)
	_directions.resize(_chaine.size())
	_saisie = null
	_saisie_index = -1
	_vitesse -= direction * Reglages.AMPLITUDE_SURSAUT * 0.7


## Le point ou pendre la piece suivante : le marqueur de support le plus bas de
## la chaine, ou l'extremite du ressort si elle est vide.
func _point_libre() -> Vector2:
	if _chaine.is_empty():
		return _bout_ressort.global_position
	return _chaine[-1].point_bas()


func _masse_chaine() -> float:
	var total: float = 0.0
	for corps: RigidBody2D in _chaine:
		total += corps.mass
	return total


func _longueur_equilibre() -> float:
	return Reglages.LONGUEUR_REPOS + _masse_pesante() * Unites.GRAVITE / maxf(Reglages.RAIDEUR, 1.0)


# --- Entrees -----------------------------------------------------------------


func _unhandled_input(evenement: InputEvent) -> void:
	if evenement is InputEventMouseButton:
		if evenement.button_index == MOUSE_BUTTON_LEFT:
			if evenement.pressed:
				_saisir(get_global_mouse_position())
			else:
				_lacher()
	elif evenement is InputEventKey and evenement.pressed and not evenement.echo:
		match evenement.keycode:
			KEY_R:
				_ranger()
			KEY_F:
				_feuille.retourner()
			KEY_P:
				_feuille.effacer_face()
			KEY_N:
				_feuille.nouvelle_feuille()
			KEY_E:
				print("feuille exportee -> ", _feuille.exporter_png())


func _saisir(ou: Vector2) -> void:
	# La tete du pointeau ne se traine pas : elle frappe, et c'est tout ce qu'elle
	# fait. Une zone, une action.
	if _pointeau.zone(ou) == Pointeau.Prise.TETE:
		_frapper()
		return

	if _regle.attraper(ou):
		_outil_saisi = _regle
		_offset_saisie = ou - _regle.global_position
		return

	if _pointeau.attraper(ou):
		_outil_saisi = _pointeau
		_offset_saisie = ou - _pointeau.global_position
		return

	if _verseuse.attraper(ou):
		_outil_saisi = _verseuse
		_offset_saisie = ou - _verseuse.global_position
		return

	for i: int in range(_chaine.size() - 1, -1, -1):
		var maillon: RigidBody2D = _chaine[i]
		if ou.distance_to(maillon.global_position) < maillon.rayon + 3.0:
			_saisie = maillon
			_saisie_index = i
			_offset_saisie = ou - _extremite
			return

	for i: int in range(_libres.size() - 1, -1, -1):
		var corps: RigidBody2D = _libres[i]
		if ou.distance_to(corps.global_position) < corps.rayon + 3.0:
			# Un sachet mal dose se reprend sur le plateau et se corrige.
			if _plateau.retirer(corps):
				_evaluer_commande()
			_saisie = corps
			_saisie_index = -1
			_offset_saisie = ou - corps.global_position
			corps.saisie = true
			corps.rafraichir()
			# Repondre a la frame ou on clique : on coupe la vitesse acquise pour
			# que l'objet parte du curseur, pas de sa trajectoire precedente.
			corps.linear_velocity *= 0.2
			corps.angular_velocity *= 0.2
			return


func _lacher() -> void:
	if _outil_saisi != null:
		if _outil_saisi == _pointeau and _clipsage_vise != null:
			_pointeau.clipser(_clipsage_vise)
		_outil_saisi.call("relacher")
		_outil_saisi = null
		_clipsage_vise = null
		return

	if _saisie == null:
		return
	var corps: RigidBody2D = _saisie
	_saisie = null
	if _saisie_index >= 0:
		_saisie_index = -1
		return
	corps.saisie = false
	corps.prete = false
	corps.rafraichir()
	if _aimant_actif:
		_accrocher(corps)
		_aimant_actif = false
		return
	_aimant_actif = false
	_livrer(corps)


## Un sachet lache au-dessus d'un creux libre s'y depose. C'est toute la
## ceremonie de livraison : pas de bouton, pas de confirmation, on pose.
func _livrer(corps: RigidBody2D) -> void:
	if not corps.sachet:
		return
	# On juge sur le POINTEUR, pas sur le sachet : un sachet plein traine loin
	# derriere le curseur, et le tester lui ferait rater le creux que le joueur
	# vise. C'est la meme raison qu'a l'aimantation du crochet.
	var creux: int = _plateau.creux_libre(_cible - _offset_saisie)
	if creux < 0:
		return
	_plateau.deposer(corps, creux)
	_evaluer_commande()


## La commande est-elle honoree ? Rien ne s'affiche tant qu'elle ne l'est pas :
## pas de verdict ligne par ligne, pas de « faux ». Quand les trois sachets y
## sont, le plateau et le bon de travail le montrent, et c'est tout.
func _evaluer_commande() -> void:
	var honore: bool = _plateau.evaluer(Enonce.COMMANDE, TOLERANCE_G)
	_enonce.honore = honore
	_enonce.queue_redraw()


func _ranger() -> void:
	for corps: RigidBody2D in _libres:
		corps.linear_velocity = Vector2.ZERO
		corps.angular_velocity = 0.0
		corps.global_position = Vector2(
			randf_range(440.0, 620.0), SOL - corps.rayon - 110.0
		)


func _process(_delta: float) -> void:
	# L'echelle de temps globale : le seul levier qui ralentit ou accelere toute
	# la simulation sans qu'aucune grandeur physique ne mente.
	Engine.time_scale = Reglages.ECHELLE_TEMPS

	var ou: Vector2 = get_global_mouse_position()
	if _outil_saisi == _regle:
		if _regle.prise == Regle.Prise.TRANSLATION:
			# On aimante le zero : c'est lui qu'on cale sur un repere.
			var vise: Vector2 = ou - _offset_saisie
			_regle.deplacer(vise, _feuille.encre_proche(vise, Reglages.AIMANT_REGLE))
		else:
			# En pivot, le zero ne bouge pas : c'est lui qu'on a cale sur une
			# marque, il n'est pas question qu'il parte.
			_regle.pivoter(ou)
	elif _outil_saisi == _verseuse:
		if _verseuse.prise == Verseuse.Prise.CORPS:
			_verseuse.global_position = ou - _offset_saisie
		else:
			# On tient la poignee : le pot bascule vers le curseur, et il coule
			# tant qu'on tient. Relacher le redresse.
			_verseuse.incliner(ou)
	elif _outil_saisi == _pointeau:
		# Ou le pointeau se clipsera si on lache maintenant.
		_clipsage_vise = _cible_de_clipsage(ou)
		_pointeau.definir_vise(_clipsage_vise != null)

	_regle.definir_survol(ou)
	_verseuse.definir_survol(ou)
	_pointeau.definir_survol(ou)

	_regler_curseur(ou)

	# Le creux ou le sachet tenu tomberait si on lachait maintenant.
	var vise: int = -1
	if _saisie != null and _saisie_index < 0 and _saisie.sachet:
		vise = _plateau.creux_libre(ou - _offset_saisie)
	_plateau.definir_vise(vise)


## Le curseur annonce ce qu'un clic ferait ici. C'est la moitie de la regle
## « une action par zone » : la zone s'eclaire ET le curseur change. L'autre
## moitie est le dessin de chaque objet, qui distingue ses zones a l'oeil.
func _regler_curseur(ou: Vector2) -> void:
	if _outil_saisi != null or _saisie != null:
		Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		return
	Input.set_default_cursor_shape(
		Input.CURSOR_POINTING_HAND if _quelque_chose_sous(ou) else Input.CURSOR_ARROW
	)


## Y a-t-il quoi que ce soit d'actionnable sous le pointeur ?
func _quelque_chose_sous(ou: Vector2) -> bool:
	if _pointeau.zone(ou) != Pointeau.Prise.AUCUNE:
		return true
	if _regle.zone_sous(ou) != Regle.Prise.AUCUNE:
		return true
	if _verseuse.zone_sous(ou) != Verseuse.Prise.AUCUNE:
		return true
	if ou.distance_to(_pivot_butee()) < 13.0:
		return true
	for corps: RigidBody2D in _chaine + _libres:
		if ou.distance_to(corps.global_position) < corps.rayon + 3.0:
			return true
	return false


## Le point d'attache du pointeau : le bout du ressort, et lui seul.
##
## Une seule cible possible, donc aucune ambiguite. Les masses exposaient elles
## aussi un porte-outil, et le pointeau pouvait se clipser sur n'importe laquelle
## — les marques changeaient alors de reference d'un releve a l'autre et
## devenaient incomparables, sans que rien ne le signale.
func _cible_de_clipsage(ou: Vector2) -> Node2D:
	if ou.distance_to(_porte_pointeau.global_position) > Reglages.RAYON_CLIPSAGE:
		return null
	return _porte_pointeau


# --- Dessin ------------------------------------------------------------------


func _draw() -> void:
	_dessiner_butee()
	if _cible_versage != null:
		# Le filet de poudre. Un trait, rien de plus : le brief demande une masse
		# qui monte et un stylo qui descend, pas un effet.
		draw_line(_verseuse.goulot(), _cible_versage.global_position, PRETE, 1.2)
	if _aimant_actif:
		_dessiner_aimantation()
	if _clipsage_vise != null:
		draw_arc(_clipsage_vise.global_position, 9.0, 0.0, TAU, 24, PRETE, 0.9)
	_dessiner_pression()
	if _debordement != Vector2.INF:
		# La poudre qui deborde tombe par terre. Elle est perdue, et ca se voit.
		draw_line(_debordement, Vector2(_debordement.x, SOL), PRETE.darkened(0.45), 1.6)


## L'arc qui se remplit pendant qu'on presse un poincon : on voit venir la marque
## au lieu de la subir, et on peut relever la masse avant qu'elle tombe.
func _dessiner_pression() -> void:
	if _pression <= 0.0 or _saisie == null:
		return
	var part: float = clampf(_pression / DUREE_TAMPON, 0.0, 1.0)
	draw_arc(
		_cible - _offset_saisie,
		_saisie.rayon + 3.5,
		-PI * 0.5,
		-PI * 0.5 + TAU * part,
		28,
		PRETE,
		1.2
	)


func _dessiner_butee() -> void:
	var pivot: Vector2 = _pivot_butee()
	var bras: Vector2 = Vector2(cos(_butee_angle), sin(_butee_angle)) * 38.0
	draw_circle(pivot, 3.0, FOND)
	draw_arc(pivot, 3.0, 0.0, TAU, 16, TRAIT, 1.0)
	draw_line(pivot, pivot + bras, PRETE if _butee else TRAIT_EFFACE, 1.5)
	var normale: Vector2 = bras.orthogonal().normalized() * 5.5
	draw_line(pivot + bras - normale, pivot + bras + normale, PRETE if _butee else TRAIT_EFFACE, 2.0)


func _dessiner_aimantation() -> void:
	draw_arc(_point_aimant, Reglages.RAYON_AIMANTATION, 0.0, TAU, 40, PRETE.darkened(0.35), 0.5)
	draw_arc(_point_aimant, 4.5, 0.0, TAU, 20, PRETE, 1.0)
	if _saisie != null:
		draw_dashed_line(_saisie.point_accroche(), _point_aimant, PRETE, 0.5, 3.0)


func _pivot_butee() -> Vector2:
	return ANCRE + Vector2(-52.0, 30.0)


func _input(evenement: InputEvent) -> void:
	# La butee se clique directement, c'est un objet et pas un bouton d'interface.
	if evenement is InputEventMouseButton and evenement.pressed and evenement.button_index == MOUSE_BUTTON_LEFT:
		if get_global_mouse_position().distance_to(_pivot_butee()) < 13.0:
			_butee = not _butee
			get_viewport().set_input_as_handled()
