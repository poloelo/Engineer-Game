# Prototype de feel. Un ressort, un crochet, des masses, une butee — et de quoi
# tracer : une feuille, un stylo, une regle.
# Aucun objectif, aucun chiffre affiche par le jeu. On manipule, c'est tout.
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

const Unites: GDScript = preload("res://unites.gd")
const Reglages: GDScript = preload("res://reglages.gd")
const Marqueurs: GDScript = preload("res://marqueurs.gd")
const Masse: GDScript = preload("res://masse.gd")
const Feuille: GDScript = preload("res://feuille.gd")
const Stylo: GDScript = preload("res://stylo.gd")
const Regle: GDScript = preload("res://regle.gd")
const Loupe: GDScript = preload("res://loupe.gd")
const VisuelEtabli: GDScript = preload("res://visuel_etabli.gd")
const VisuelRessort: GDScript = preload("res://visuel_ressort.gd")
const PanneauReglages: GDScript = preload("res://panneau_reglages.gd")

const FOND: Color = Color("0d243d")
const TRAIT: Color = Color("e6f0f8")
const TRAIT_EFFACE: Color = Color(0.90, 0.94, 0.97, 0.45)
const PRETE: Color = Color("ffb454")

## Point de suspension du ressort, en mm.
const ANCRE: Vector2 = Vector2(350.0, 48.0)
## Hauteur du plan de travail, en mm.
const SOL: float = 324.0
## Jeu entre deux masses de la chaine, en mm.
const ESPACE_CHAINE: float = 2.5
## Le ressort ne se comprime pas au-dela, en mm.
const LONGUEUR_MIN: float = 12.0

## Le jeu de masses d'etalonnage, en grammes. Deliberement du meme ordre que le
## crochet (8 g) : c'est ce qui rend son poids propre impossible a ignorer.
const MASSES_G: Array[float] = [1.0, 2.0, 2.0, 5.0, 5.0, 10.0, 10.0, 20.0]

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
var _stylo: Node2D = null
var _regle: Node2D = null
var _loupe: Node2D = null
var _ressort: Line2D = null
var _bout_ressort: Marker2D = null

# --- Saisie ------------------------------------------------------------------

var _saisie: RigidBody2D = null
var _saisie_index: int = -1
var _offset_saisie: Vector2 = Vector2.ZERO
var _cible: Vector2 = Vector2.ZERO
var _point_aimant: Vector2 = Vector2.ZERO
var _aimant_actif: bool = false
## Ce que le curseur traine qui n'est pas une masse : la feuille, le stylo, la regle.
var _outil_saisi: Node2D = null
var _clipsage_vise: RigidBody2D = null


func _ready() -> void:
	_construire_camera()
	_construire_etabli()
	_construire_instruments()
	_construire_crochet()
	_construire_masses()
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

	_regle = Regle.new()
	_regle.position = Vector2(95.0, 280.0)
	_regle.z_index = 6
	add_child(_regle)

	_stylo = Stylo.new()
	_stylo.position = Vector2(530.0, SOL - 15.0)
	_stylo.z_index = 7
	add_child(_stylo)

	_loupe = Loupe.new()
	_loupe.position = Vector2(505.0, 150.0)
	_loupe.z_index = 12
	add_child(_loupe)


## Le crochet est une piece reelle du montage, pas un poids indetachable ajoute
## pour compenser. Il pese 8 g, il etire le ressort en permanence, il balance
## quand on le pousse et il oscille quand on retire une masse.
##
## C'est le piege du niveau 1 : le zero du joueur n'est pas la ou il croit, parce
## que son instrument pese deja quelque chose avant qu'il n'ait rien accroche.
## Et comme il se devisse — on le prend, on le tire, le ressort remonte de 30 mm
## sous les yeux — le geste qui resout le niveau existe physiquement.
func _construire_crochet() -> void:
	var crochet: RigidBody2D = _nouvelle_masse(
		Reglages.MASSE_CROCHET, 8.0, ANCRE + Vector2(0.0, 60.0), true
	)
	_accrocher(crochet, false)


func _construire_masses() -> void:
	var x: float = 420.0
	var rang: int = 0
	for m: float in MASSES_G:
		var rayon: float = _rayon_de(m)
		# Deux rangs : le jeu de poids ne tient pas sur une seule ligne d'etabli.
		# Le second tombe sur le premier et se range tout seul.
		_nouvelle_masse(m, rayon, Vector2(x, SOL - rayon - 1.0 - float(rang) * 60.0))
		x += rayon * 2.0 + 6.0
		if x > 625.0:
			x = 420.0
			rang += 1


## Rayon d'un poids en fonction de sa masse, en mm.
##
## Un vrai jeu de poids est geometriquement semblable : le rayon suit la racine
## cubique de la masse. On garde cette loi, mais avec 4 mm de socle en plus,
## sinon un poids de 1 g ferait 5 mm de large et deviendrait impossible a
## attraper a la souris. C'est la seule exageration de forme du prototype.
func _rayon_de(masse_g: float) -> float:
	return 4.0 + 5.0 * pow(maxf(masse_g, 0.01), 1.0 / 3.0)


## La forme se decrit AVANT d'entrer dans l'arbre : c'est a ce moment-la que la
## masse construit sa collision, ses marqueurs et son visuel.
func _nouvelle_masse(
	masse_g: float, rayon: float, ou: Vector2, est_crochet: bool = false
) -> RigidBody2D:
	var corps: RigidBody2D = Masse.new()
	corps.rayon = rayon
	corps.mass = masse_g
	corps.position = ou
	corps.crochet = est_crochet
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
	_ressort.mettre_a_jour(ANCRE, _extremite, _vitesse)
	_poser_la_chaine(delta)
	_traine_au_curseur()
	_detecter_aimantation()
	_detecter_chocs()
	_animer_stylo()

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


# --- Stylo -------------------------------------------------------------------


func _animer_stylo() -> void:
	if _stylo == null:
		return
	if _stylo.tenu:
		_stylo.global_position = _cible - _offset_saisie
	elif _stylo.support != null and is_instance_valid(_stylo.support):
		_stylo.global_position = _stylo.support.global_position + _stylo.decalage

	# Le stylo ne trace que si la pointe est baissee et qu'elle touche la feuille.
	if _stylo.pointe_baissee:
		_feuille.tracer(_stylo.pointe())
	else:
		_feuille.lever()


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
		if _stylo != null and _stylo.support == corps:
			_stylo.declipser()
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
		elif evenement.button_index == MOUSE_BUTTON_RIGHT and evenement.pressed:
			_stylo.basculer_pointe()
	elif evenement is InputEventKey and evenement.pressed and not evenement.echo:
		match evenement.keycode:
			KEY_SPACE:
				_stylo.basculer_pointe()
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
	# Ordre de priorite : les instruments sont devant, la feuille est le fond.
	if _loupe.attraper(ou):
		_outil_saisi = _loupe
		_offset_saisie = ou - _loupe.global_position
		return

	if _regle.attraper(ou):
		_outil_saisi = _regle
		_offset_saisie = ou - _regle.global_position
		return

	if _stylo.attraper(ou):
		_outil_saisi = _stylo
		_offset_saisie = ou - _stylo.global_position
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

	if _feuille.attraper(ou):
		_outil_saisi = _feuille
		_offset_saisie = ou - _feuille.global_position


func _lacher() -> void:
	if _outil_saisi != null:
		if _outil_saisi == _stylo and _clipsage_vise != null:
			_stylo.clipser(_clipsage_vise)
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
			# En pivot, c'est le bout tenu qui cherche une marque.
			_regle.pivoter(ou, _feuille.encre_proche(ou, Reglages.AIMANT_REGLE))
	elif _outil_saisi == _loupe:
		_loupe.global_position = ou - _offset_saisie
	elif _outil_saisi == _feuille:
		_feuille.global_position = ou - _offset_saisie
	elif _outil_saisi == _stylo:
		# Ou le stylo se clipsera si on lache maintenant.
		_clipsage_vise = _cible_de_clipsage(ou)
		_stylo.definir_vise(_clipsage_vise != null)

	_regle.definir_survol(ou)
	_loupe.definir_survol(ou)


## Le marqueur porte-stylo le plus proche du pointeur, dans le rayon de clipsage.
## Rien n'est code en dur : chaque objet expose ses points d'attache et le
## clipsage prend le plus proche qui soit compatible.
func _cible_de_clipsage(ou: Vector2) -> RigidBody2D:
	var marqueur: Marker2D = Marqueurs.plus_proche(
		_chaine + _libres, ou, Marqueurs.PORTE_STYLO, Reglages.RAYON_CLIPSAGE
	)
	return null if marqueur == null else marqueur.get_parent() as RigidBody2D


# --- Dessin ------------------------------------------------------------------


func _draw() -> void:
	_dessiner_butee()
	if _aimant_actif:
		_dessiner_aimantation()
	if _clipsage_vise != null:
		draw_arc(
			_clipsage_vise.global_position, _clipsage_vise.rayon + 4.5, 0.0, TAU, 32, PRETE, 0.75
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
