# Prototype de feel. Un ressort, un crochet, des masses, une butee — et de quoi
# tracer : une feuille, un stylo, une regle.
# Aucun objectif, aucun chiffre affiche par le jeu. On manipule, c'est tout.
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

const Reglages: GDScript = preload("res://reglages.gd")
const Masse: GDScript = preload("res://masse.gd")
const Feuille: GDScript = preload("res://feuille.gd")
const Stylo: GDScript = preload("res://stylo.gd")
const Regle: GDScript = preload("res://regle.gd")
const Loupe: GDScript = preload("res://loupe.gd")
const PanneauReglages: GDScript = preload("res://panneau_reglages.gd")

const FOND: Color = Color("0d243d")
const TRAIT: Color = Color("e6f0f8")
const TRAIT_EFFACE: Color = Color(0.90, 0.94, 0.97, 0.45)
const TRAIT_TRES_EFFACE: Color = Color(0.90, 0.94, 0.97, 0.18)
const RESSORT: Color = Color("6fd3ff")
const PRETE: Color = Color("ffb454")

const ANCRE: Vector2 = Vector2(700.0, 96.0)
const SOL: float = 648.0
const ESPACE_CHAINE: float = 5.0
const LONGUEUR_MIN: float = 24.0

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
	_construire_etabli()
	_construire_instruments()
	_construire_crochet()
	_construire_masses()
	add_child(PanneauReglages.new())


# --- Construction ------------------------------------------------------------


func _construire_etabli() -> void:
	for donnee: Array in [
		[Vector2(640.0, SOL + 40.0), Vector2(1400.0, 80.0)],
		[Vector2(-30.0, 360.0), Vector2(60.0, 900.0)],
		[Vector2(1310.0, 360.0), Vector2(60.0, 900.0)],
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
	fond.size = Vector2(1280.0, 720.0)
	fond.z_index = -20
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)

	# La feuille est punaisee derriere le ressort, devant le fond.
	_feuille = Feuille.new()
	_feuille.position = Vector2(300.0, 140.0)
	_feuille.z_index = -10
	add_child(_feuille)

	_regle = Regle.new()
	_regle.position = Vector2(190.0, 560.0)
	_regle.z_index = 6
	add_child(_regle)

	_stylo = Stylo.new()
	_stylo.position = Vector2(1060.0, SOL - 30.0)
	_stylo.z_index = 7
	add_child(_stylo)

	_loupe = Loupe.new()
	_loupe.position = Vector2(1010.0, 300.0)
	_loupe.z_index = 12
	add_child(_loupe)


func _construire_crochet() -> void:
	var crochet: RigidBody2D = _nouvelle_masse(0.25, 17.0, ANCRE + Vector2(0.0, 120.0))
	crochet.set("crochet", true)
	_accrocher(crochet, false)


func _construire_masses() -> void:
	var masses: Array[float] = [0.12, 0.18, 0.28, 0.4, 0.6, 0.85, 1.15, 1.5]
	var x: float = 900.0
	for m: float in masses:
		var rayon: float = 13.0 + 21.0 * sqrt(m)
		_nouvelle_masse(m, rayon, Vector2(x, SOL - rayon - 2.0))
		x += rayon * 2.0 + 18.0
		if x > 1240.0:
			x = 900.0


func _nouvelle_masse(masse: float, rayon: float, ou: Vector2) -> RigidBody2D:
	var corps: RigidBody2D = Masse.new()
	corps.rayon = rayon
	corps.mass = masse
	corps.position = ou
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
## soit son orientation. La gravite reste verticale. C'est la combinaison des deux
## qui produit le pendule, l'ellipse molle et le depart en travers, sans qu'aucun
## de ces comportements soit ecrit quelque part.
##
## L'amortissement est decompose sur l'axe et perpendiculairement a lui, pour que
## le yoyo et le balancement se reglent separement.
func _integrer_ressort(delta: float) -> void:
	var masse: float = Reglages.MASSE_RESSORT + _masse_chaine()
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
			+ Vector2.DOWN * _masse_chaine() * Reglages.GRAVITE
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


## Le ressort ne se retourne pas sur lui-meme.
func _contraindre_longueur() -> void:
	var axe: Vector2 = _extremite - ANCRE
	if axe.length() < LONGUEUR_MIN:
		var direction: Vector2 = axe.normalized() if axe.length() > 0.001 else Vector2.DOWN
		_extremite = ANCRE + direction * LONGUEUR_MIN
		_vitesse -= direction * minf(_vitesse.dot(direction), 0.0)


## Sans ce seuil le ressort fremit indefiniment, ce qui est insupportable quand
## on essaie de lire une position au millimetre.
##
## Le critere porte sur l'amplitude restante de l'oscillation, ecart et vitesse
## combines, et non sur les deux pris separement : un ressort qui passe vite par
## sa position d'equilibre n'est pas au repos, et un ressort momentanement arrete
## au sommet de sa course non plus. Exiger les deux petits au meme instant
## retardait l'endormissement de plus d'une seconde, et c'est ce qui donnait
## l'impression de sirop bien plus que l'amortissement lui-meme.
func _endormir() -> void:
	var repos: Vector2 = ANCRE + Vector2.DOWN * _longueur_equilibre()
	var masse: float = Reglages.MASSE_RESSORT + _masse_chaine()
	var pulsation: float = sqrt(maxf(Reglages.RAIDEUR, 1.0) / maxf(masse, 0.01))
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
		var rayon: float = corps.get("rayon")
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
		+ Vector2.UP * Reglages.GRAVITE * masse * Reglages.COMPENSATION_POIDS
	)
	if _aimant_actif:
		var vers_aimant: Vector2 = _point_aimant - _saisie.call("point_accroche")
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
	var vise: Vector2 = _cible - _offset_saisie + Vector2(0.0, -float(_saisie.get("rayon")))
	_aimant_actif = vise.distance_to(_point_aimant) < Reglages.RAYON_AIMANTATION
	_saisie.set("prete", _aimant_actif)
	_saisie.queue_redraw()


## Une masse qui percute la chaine relance l'oscillation — dans la direction du
## choc, donc un coup de cote fait balancer.
func _detecter_chocs() -> void:
	if _chaine.is_empty():
		return
	for corps: RigidBody2D in _libres:
		if corps == _saisie or corps.linear_velocity.length() < 140.0:
			continue
		for maillon: RigidBody2D in _chaine:
			var portee: float = float(corps.get("rayon")) + float(maillon.get("rayon")) + 6.0
			if corps.global_position.distance_to(maillon.global_position) < portee:
				_vitesse += (
					corps.linear_velocity
					* Reglages.TRANSMISSION_CHOC
					* corps.mass
					/ maxf(_masse_chaine(), 0.2)
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
	corps.global_position = _point_libre() + Vector2(0.0, float(corps.get("rayon")))
	_libres.erase(corps)
	_chaine.append(corps)
	_directions.append(Vector2.DOWN)
	corps.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	corps.freeze = true
	corps.set("accrochee", true)
	corps.set("prete", false)
	corps.queue_redraw()
	if sursaut:
		_vitesse += Vector2.DOWN * Reglages.AMPLITUDE_SURSAUT * corps.mass / maxf(_masse_chaine(), 0.2)


func _decrocher_a_partir_de(index: int) -> void:
	if index < 0 or index >= _chaine.size():
		return
	var vitesse: Vector2 = _vitesse.limit_length(900.0)
	var direction: Vector2 = (_extremite - ANCRE).normalized()
	while _chaine.size() > index:
		var corps: RigidBody2D = _chaine.pop_back()
		corps.freeze = false
		corps.set("accrochee", false)
		corps.linear_velocity = vitesse
		corps.queue_redraw()
		_libres.append(corps)
		if _stylo != null and _stylo.support == corps:
			_stylo.declipser()
	_directions.resize(_chaine.size())
	_saisie = null
	_saisie_index = -1
	_vitesse -= direction * Reglages.AMPLITUDE_SURSAUT * 0.7


func _point_libre() -> Vector2:
	if _chaine.is_empty():
		return _extremite
	return _chaine[-1].call("point_bas")


func _masse_chaine() -> float:
	var total: float = 0.0
	for corps: RigidBody2D in _chaine:
		total += corps.mass
	return total


func _longueur_equilibre() -> float:
	return Reglages.LONGUEUR_REPOS + _masse_chaine() * Reglages.GRAVITE / maxf(Reglages.RAIDEUR, 1.0)


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
		if ou.distance_to(maillon.global_position) < float(maillon.get("rayon")) + 6.0:
			_saisie = maillon
			_saisie_index = i
			_offset_saisie = ou - _extremite
			return

	for i: int in range(_libres.size() - 1, -1, -1):
		var corps: RigidBody2D = _libres[i]
		if ou.distance_to(corps.global_position) < float(corps.get("rayon")) + 6.0:
			_saisie = corps
			_saisie_index = -1
			_offset_saisie = ou - corps.global_position
			corps.set("saisie", true)
			corps.queue_redraw()
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
	corps.set("saisie", false)
	corps.set("prete", false)
	corps.queue_redraw()
	if _aimant_actif:
		_accrocher(corps)
	_aimant_actif = false


func _ranger() -> void:
	for corps: RigidBody2D in _libres:
		corps.linear_velocity = Vector2.ZERO
		corps.angular_velocity = 0.0
		corps.global_position = Vector2(
			randf_range(880.0, 1240.0), SOL - float(corps.get("rayon")) - 220.0
		)


func _process(_delta: float) -> void:
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
		_stylo.vise = _clipsage_vise != null

	_regle.definir_survol(ou)
	_loupe.definir_survol(ou)


## Element mobile le plus proche du pointeur, dans le rayon de clipsage.
func _cible_de_clipsage(ou: Vector2) -> RigidBody2D:
	var meilleure: RigidBody2D = null
	var distance: float = Reglages.RAYON_CLIPSAGE
	for corps: RigidBody2D in _chaine + _libres:
		var d: float = ou.distance_to(corps.global_position)
		if d < distance:
			distance = d
			meilleure = corps
	return meilleure


# --- Dessin ------------------------------------------------------------------


func _draw() -> void:
	_dessiner_etabli()
	_dessiner_potence()
	_dessiner_ressort()
	_dessiner_butee()
	if _aimant_actif:
		_dessiner_aimantation()
	if _clipsage_vise != null:
		draw_arc(_clipsage_vise.global_position, float(_clipsage_vise.get("rayon")) + 9.0,
			0.0, TAU, 32, PRETE, 1.5)


func _dessiner_etabli() -> void:
	draw_line(Vector2(0.0, SOL), Vector2(1280.0, SOL), TRAIT, 2.0)
	for i: int in 32:
		var x: float = float(i) * 40.0
		draw_line(Vector2(x, SOL), Vector2(x - 14.0, SOL + 16.0), TRAIT_TRES_EFFACE, 1.0)


func _dessiner_potence() -> void:
	draw_line(ANCRE + Vector2(-90.0, -26.0), ANCRE + Vector2(60.0, -26.0), TRAIT, 3.0)
	draw_line(ANCRE + Vector2(0.0, -26.0), ANCRE, TRAIT, 2.0)
	for i: int in 10:
		var x: float = ANCRE.x - 86.0 + float(i) * 15.0
		draw_line(
			Vector2(x, ANCRE.y - 26.0), Vector2(x - 10.0, ANCRE.y - 38.0), TRAIT_EFFACE, 1.0
		)


## Le ressort se dessine le long de son axe courant : penche s'il est penche.
## Les spires s'ecartent quand il s'etire et se pincent lateralement. Le ballant
## est un arc perpendiculaire a l'axe, nourri par la composante laterale de la
## vitesse — un ressort qui balance n'est pas droit.
func _dessiner_ressort() -> void:
	var axe: Vector2 = _extremite - ANCRE
	var longueur: float = maxf(axe.length(), 0.001)
	var direction: Vector2 = axe / longueur
	var normale: Vector2 = direction.orthogonal()

	var etirement: float = longueur / maxf(Reglages.LONGUEUR_REPOS, 1.0)
	var largeur: float = Reglages.LARGEUR_SPIRE / sqrt(maxf(etirement, 0.35))
	var v_laterale: float = _vitesse.dot(normale)
	var ballant: float = clampf(v_laterale * Reglages.BALLANT, -26.0, 26.0)

	var points: PackedVector2Array = PackedVector2Array()
	points.append(ANCRE)
	for i: int in Reglages.SPIRES + 1:
		var t: float = float(i) / float(Reglages.SPIRES)
		var cote: float = largeur * (1.0 if i % 2 == 0 else -1.0)
		# Arc de ballant : nul aux deux extremites, maximal au milieu.
		points.append(
			ANCRE + direction * (longueur * t) + normale * (cote + ballant * sin(PI * t))
		)
	points.append(_extremite)
	draw_polyline(points, RESSORT, 2.0)


func _dessiner_butee() -> void:
	var pivot: Vector2 = _pivot_butee()
	var bras: Vector2 = Vector2(cos(_butee_angle), sin(_butee_angle)) * 76.0
	draw_circle(pivot, 6.0, FOND)
	draw_arc(pivot, 6.0, 0.0, TAU, 16, TRAIT, 2.0)
	draw_line(pivot, pivot + bras, PRETE if _butee else TRAIT_EFFACE, 3.0)
	var normale: Vector2 = bras.orthogonal().normalized() * 11.0
	draw_line(pivot + bras - normale, pivot + bras + normale, PRETE if _butee else TRAIT_EFFACE, 4.0)


func _dessiner_aimantation() -> void:
	draw_arc(_point_aimant, Reglages.RAYON_AIMANTATION, 0.0, TAU, 40, PRETE.darkened(0.35), 1.0)
	draw_arc(_point_aimant, 9.0, 0.0, TAU, 20, PRETE, 2.0)
	if _saisie != null:
		draw_dashed_line(_saisie.call("point_accroche"), _point_aimant, PRETE, 1.0, 6.0)


func _pivot_butee() -> Vector2:
	return ANCRE + Vector2(-104.0, 60.0)


func _input(evenement: InputEvent) -> void:
	# La butee se clique directement, c'est un objet et pas un bouton d'interface.
	if evenement is InputEventMouseButton and evenement.pressed and evenement.button_index == MOUSE_BUTTON_LEFT:
		if get_global_mouse_position().distance_to(_pivot_butee()) < 26.0:
			_butee = not _butee
			get_viewport().set_input_as_handled()
