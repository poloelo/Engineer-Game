# Prototype de feel. Un ressort, un crochet, des masses, une butee, une regle.
# Aucun objectif, aucun chiffre, rien a gagner. On manipule, c'est tout.
#
# Physique hybride : les masses libres sont des RigidBody2D (chute, rebond,
# empilement, roulement — le moteur le fait mieux et gratuitement), le ressort
# est integre a la main sur un seul degre de liberte. Un PinJoint2D chaine
# donnerait un pendule mou impossible a regler ; deux constantes lisibles se
# reglent en dix secondes.
extends Node2D

const Reglages: GDScript = preload("res://reglages.gd")
const Masse: GDScript = preload("res://masse.gd")
const PanneauReglages: GDScript = preload("res://panneau_reglages.gd")

const FOND: Color = Color("0d243d")
const TRAIT: Color = Color("e6f0f8")
const TRAIT_EFFACE: Color = Color(0.90, 0.94, 0.97, 0.45)
const TRAIT_TRES_EFFACE: Color = Color(0.90, 0.94, 0.97, 0.18)
const RESSORT: Color = Color("6fd3ff")
const PRETE: Color = Color("ffb454")

const ANCRE: Vector2 = Vector2(640.0, 96.0)
const SOL: float = 648.0
const ESPACE_CHAINE: float = 5.0

# --- Etat du ressort ---------------------------------------------------------

var _longueur: float = Reglages.LONGUEUR_REPOS
var _vitesse: float = 0.0
var _butee: bool = false
var _butee_angle: float = 0.0

# --- Objets ------------------------------------------------------------------

var _chaine: Array[RigidBody2D] = []
var _libres: Array[RigidBody2D] = []

# --- Saisie ------------------------------------------------------------------

var _saisie: RigidBody2D = null
var _saisie_index: int = -1
var _offset_saisie: Vector2 = Vector2.ZERO
var _cible: Vector2 = Vector2.ZERO
var _regle_saisie: bool = false
var _regle: Vector2 = Vector2(1040.0, 150.0)
var _point_aimant: Vector2 = Vector2.ZERO
var _aimant_actif: bool = false


func _ready() -> void:
	_construire_etabli()
	_construire_crochet()
	_construire_masses()
	add_child(PanneauReglages.new())


# --- Construction ------------------------------------------------------------


func _construire_etabli() -> void:
	for donnee: Array in [
		[Vector2(640.0, SOL + 40.0), Vector2(1400.0, 80.0)],  # plan de travail
		[Vector2(-30.0, 360.0), Vector2(60.0, 900.0)],  # mur gauche
		[Vector2(1310.0, 360.0), Vector2(60.0, 900.0)],  # mur droit
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


func _construire_crochet() -> void:
	var crochet: RigidBody2D = _nouvelle_masse(0.25, 17.0, ANCRE + Vector2(0.0, 120.0))
	crochet.set("crochet", true)
	_accrocher(crochet, false)


func _construire_masses() -> void:
	# Huit masses de tailles nettement differentes : c'est l'ecart de poids
	# ressenti au curseur qu'on teste, il faut qu'il soit franc.
	var masses: Array[float] = [0.12, 0.18, 0.28, 0.4, 0.6, 0.85, 1.15, 1.5]
	var x: float = 120.0
	for m: float in masses:
		var rayon: float = 13.0 + 21.0 * sqrt(m)
		_nouvelle_masse(m, rayon, Vector2(x, SOL - rayon - 2.0))
		x += rayon * 2.0 + 26.0
		if x > 520.0 and x < 780.0:
			x = 790.0  # laisser la place sous le ressort


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

	_poser_la_chaine()
	_traine_au_curseur()
	_detecter_aimantation()
	_detecter_chocs()

	_butee_angle = lerpf(_butee_angle, -1.15 if _butee else 0.0, 1.0 - pow(0.001, delta))
	queue_redraw()


## Le ressort, integre a la main. Quatre sous-pas : la raideur peut monter haut
## dans le panneau de reglage sans que ca parte en vrille.
func _integrer_ressort(delta: float) -> void:
	var masse: float = Reglages.MASSE_RESSORT + _masse_chaine()
	var amortissement: float = Reglages.AMORTISSEMENT_BUTEE if _butee else Reglages.AMORTISSEMENT
	var pas: float = delta / 4.0
	for i: int in 4:
		var force: float = (
			-Reglages.RAIDEUR * (_longueur - Reglages.LONGUEUR_REPOS)
			+ _masse_chaine() * Reglages.GRAVITE
			- amortissement * _vitesse * masse
		)
		_vitesse += (force / masse) * pas
		_longueur += _vitesse * pas
	# Le ressort ne se retourne pas sur lui-meme.
	if _longueur < 24.0:
		_longueur = 24.0
		_vitesse = maxf(_vitesse, 0.0)


## On tient une masse accrochee : le ressort suit le curseur. Tirer un peu et
## lacher relance l'oscillation ; tirer trop fait lacher la prise.
func _tirer_la_chaine(delta: float) -> void:
	var precedente: float = _longueur
	var voulue: float = maxf(_cible.y - ANCRE.y - _offset_saisie.y, 24.0)
	_longueur = lerpf(_longueur, voulue, 1.0 - pow(0.000001, delta))
	_vitesse = (_longueur - precedente) / maxf(delta, 0.0001)

	if _longueur - _equilibre() > Reglages.SEUIL_DECROCHAGE:
		_decrocher_a_partir_de(_saisie_index)


func _poser_la_chaine() -> void:
	var ballant: float = clampf(_vitesse * Reglages.BALLANT, -22.0, 22.0)
	var y: float = ANCRE.y + _longueur
	for corps: RigidBody2D in _chaine:
		var rayon: float = corps.get("rayon")
		corps.global_position = Vector2(ANCRE.x + ballant * 0.35, y + rayon)
		corps.linear_velocity = Vector2(0.0, _vitesse)
		y += rayon * 2.0 + ESPACE_CHAINE


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
## l'assistance ne se declencherait jamais au moment ou le joueur vise. C'est le
## defaut le plus penible qu'a revele le premier essai.
func _detecter_aimantation() -> void:
	_aimant_actif = false
	if _saisie == null or _saisie_index >= 0:
		return
	_point_aimant = _point_libre()
	var vise: Vector2 = _cible - _offset_saisie + Vector2(0.0, -float(_saisie.get("rayon")))
	_aimant_actif = vise.distance_to(_point_aimant) < Reglages.RAYON_AIMANTATION
	_saisie.set("prete", _aimant_actif)
	_saisie.queue_redraw()


## Une masse qui percute la chaine relance l'oscillation.
func _detecter_chocs() -> void:
	if _chaine.is_empty():
		return
	for corps: RigidBody2D in _libres:
		if corps == _saisie or absf(corps.linear_velocity.y) < 140.0:
			continue
		for maillon: RigidBody2D in _chaine:
			var portee: float = float(corps.get("rayon")) + float(maillon.get("rayon")) + 6.0
			if corps.global_position.distance_to(maillon.global_position) < portee:
				_vitesse += (
					corps.linear_velocity.y
					* Reglages.TRANSMISSION_CHOC
					* corps.mass
					/ maxf(_masse_chaine(), 0.2)
				)
				corps.linear_velocity *= -Reglages.REBOND
				break


# --- Accrochage --------------------------------------------------------------


func _accrocher(corps: RigidBody2D, sursaut: bool = true) -> void:
	# On pose l'objet exactement au point d'accroche. L'accrochage est franc :
	# aucun glissement mou vers la position.
	corps.global_position = _point_libre() + Vector2(0.0, float(corps.get("rayon")))
	_libres.erase(corps)
	_chaine.append(corps)
	corps.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	corps.freeze = true
	corps.set("accrochee", true)
	corps.set("prete", false)
	corps.queue_redraw()
	if sursaut:
		# Le ressort accuse le coup : c'est le "clac" de l'accrochage.
		_vitesse += Reglages.AMPLITUDE_SURSAUT * corps.mass / maxf(_masse_chaine(), 0.2)


func _decrocher_a_partir_de(index: int) -> void:
	if index < 0 or index >= _chaine.size():
		return
	var vitesse: Vector2 = Vector2(0.0, clampf(_vitesse, -900.0, 900.0))
	while _chaine.size() > index:
		var corps: RigidBody2D = _chaine.pop_back()
		corps.freeze = false
		corps.set("accrochee", false)
		corps.linear_velocity = vitesse
		corps.queue_redraw()
		_libres.append(corps)
	_saisie = null
	_saisie_index = -1
	# Le ressort se detend d'un coup : recul franc.
	_vitesse -= Reglages.AMPLITUDE_SURSAUT * 0.7


func _point_libre() -> Vector2:
	if _chaine.is_empty():
		return ANCRE + Vector2(0.0, _longueur)
	return _chaine[-1].call("point_bas")


func _masse_chaine() -> float:
	var total: float = 0.0
	for corps: RigidBody2D in _chaine:
		total += corps.mass
	return total


func _equilibre() -> float:
	return Reglages.LONGUEUR_REPOS + _masse_chaine() * Reglages.GRAVITE / maxf(Reglages.RAIDEUR, 1.0)


# --- Entrees -----------------------------------------------------------------


func _unhandled_input(evenement: InputEvent) -> void:
	if evenement is InputEventMouseButton and evenement.button_index == MOUSE_BUTTON_LEFT:
		if evenement.pressed:
			_saisir(get_global_mouse_position())
		else:
			_lacher()
	elif evenement is InputEventKey and evenement.pressed and not evenement.echo:
		if evenement.keycode == KEY_R:
			_ranger()


func _saisir(ou: Vector2) -> void:
	if _rect_regle().has_point(ou):
		_regle_saisie = true
		_offset_saisie = ou - _regle
		return

	if ou.distance_to(_pivot_butee()) < 26.0:
		_butee = not _butee
		return

	# La chaine avant les masses libres : elle est devant, on la vise en premier.
	for i: int in range(_chaine.size() - 1, -1, -1):
		var maillon: RigidBody2D = _chaine[i]
		if ou.distance_to(maillon.global_position) < float(maillon.get("rayon")) + 6.0:
			_saisie = maillon
			_saisie_index = i
			_offset_saisie = ou - Vector2(ANCRE.x, ANCRE.y + _longueur)
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


func _lacher() -> void:
	_regle_saisie = false
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
			randf_range(90.0, 1180.0), SOL - float(corps.get("rayon")) - 200.0
		)


func _process(_delta: float) -> void:
	if _regle_saisie:
		_regle = get_global_mouse_position() - _offset_saisie


# --- Dessin ------------------------------------------------------------------


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), FOND, true)
	_dessiner_etabli()
	_dessiner_potence()
	_dessiner_ressort()
	_dessiner_butee()
	if _aimant_actif:
		_dessiner_aimantation()
	_dessiner_regle()


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


## Le ressort en zigzag : les spires s'ecartent quand il s'etire et il se pince
## lateralement, comme un vrai. Le ballant lateral vient de la vitesse.
func _dessiner_ressort() -> void:
	var etirement: float = _longueur / maxf(Reglages.LONGUEUR_REPOS, 1.0)
	var largeur: float = Reglages.LARGEUR_SPIRE / sqrt(maxf(etirement, 0.35))
	var ballant: float = clampf(_vitesse * Reglages.BALLANT, -26.0, 26.0)

	var points: PackedVector2Array = PackedVector2Array()
	points.append(ANCRE)
	for i: int in Reglages.SPIRES + 1:
		var t: float = float(i) / float(Reglages.SPIRES)
		var cote: float = largeur * (1.0 if i % 2 == 0 else -1.0)
		# Arc de ballant : nul aux deux extremites, maximal au milieu.
		points.append(
			Vector2(ANCRE.x + cote + ballant * sin(PI * t), ANCRE.y + _longueur * t)
		)
	points.append(ANCRE + Vector2(ballant * 0.35, _longueur))
	draw_polyline(points, RESSORT, 2.0)


func _dessiner_butee() -> void:
	var pivot: Vector2 = _pivot_butee()
	var bras: Vector2 = Vector2(cos(_butee_angle), sin(_butee_angle)) * 76.0
	draw_circle(pivot, 6.0, FOND)
	draw_arc(pivot, 6.0, 0.0, TAU, 16, TRAIT, 2.0)
	draw_line(pivot, pivot + bras, PRETE if _butee else TRAIT_EFFACE, 3.0)
	# Le patin, au bout du bras.
	var normale: Vector2 = bras.orthogonal().normalized() * 11.0
	draw_line(pivot + bras - normale, pivot + bras + normale, PRETE if _butee else TRAIT_EFFACE, 4.0)


func _dessiner_aimantation() -> void:
	draw_arc(_point_aimant, Reglages.RAYON_AIMANTATION, 0.0, TAU, 40, PRETE.darkened(0.35), 1.0)
	draw_arc(_point_aimant, 9.0, 0.0, TAU, 20, PRETE, 2.0)
	if _saisie != null:
		draw_dashed_line(_saisie.call("point_accroche"), _point_aimant, PRETE, 1.0, 6.0)


func _dessiner_regle() -> void:
	var rect: Rect2 = _rect_regle()
	draw_rect(rect, FOND, true)
	draw_rect(rect, TRAIT_EFFACE, false, 1.5)
	var millimetres: int = int(rect.size.y / 4.0)
	for i: int in millimetres + 1:
		var y: float = rect.position.y + float(i) * 4.0
		var longue: bool = i % 10 == 0
		draw_line(
			Vector2(rect.position.x, y),
			Vector2(rect.position.x + (18.0 if longue else 8.0), y),
			TRAIT_EFFACE if longue else TRAIT_TRES_EFFACE,
			1.0
		)


func _rect_regle() -> Rect2:
	return Rect2(_regle, Vector2(34.0, 420.0))


func _pivot_butee() -> Vector2:
	return ANCRE + Vector2(-104.0, 60.0)
