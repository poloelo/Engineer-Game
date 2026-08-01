## Le test qui valide l'architecture.
##
## Il charge une machine, releve des mesures, soumet une specification et lit le
## verdict du banc — sans ouvrir une seule scene. Si ce fichier passe en headless,
## la separation entre simulation et presentation tient.
extends "res://tests/support/test_base.gd"

const PESON: String = "res://src/contenu/data/machines/peson.tres"

# Physique cachee : longueur a vide 60 mm, sensibilite 0,18 mm/g, crochet 8 g.
const SOLUTION_A: float = 1.0 / 0.18
const SOLUTION_B: float = -(60.0 / 0.18) - 8.0


func _machine() -> MachineDef:
	return load(PESON) as MachineDef


func _simulation() -> SimulationMachine:
	return SimulationMachine.new(_machine())


func _emplacement() -> EmplacementPiece:
	return _machine().emplacements[0]


func _spec(a: float, b: float) -> Specification:
	return Specification.new(_emplacement(), {"a": a, "b": b})


func test_machine_chargee_depuis_donnee() -> void:
	var machine: MachineDef = _machine()
	verifier(machine != null, "peson.tres se charge en MachineDef")
	if machine == null:
		return
	verifier_egal(machine.id, &"peson", "id")
	verifier_egal(machine.verifier(), [] as Array[String], "la machine est structurellement saine")
	verifier_egal(machine.cas_test_caches.size(), 3, "trois masses cachees")
	verifier_egal(machine.emplacements[0].gabarit, "a * lecture + b", "gabarit affine")


func test_mesure_limitee_par_la_regle() -> void:
	var simulation: SimulationMachine = _simulation()
	# 50 g pendus : 61,44 + 9 = 70,44 mm, que la regle au mm arrondit a 70.
	var point: Vector2 = simulation.effectuer_mesure(simulation.etat_pour_etalon(50.0))
	verifier_proche(point.x, 70.0, "lecture arrondie au mm")
	# La masse etalon, elle, est connue exactement : elle est gravee, pas pesee.
	verifier_proche(point.y, 50.0, "masse etalon exacte")


func test_mesure_deterministe() -> void:
	# Un instrument grossier ment de facon stable : deux releves identiques
	# donnent la meme valeur, sinon le joueur ne pourrait rien deduire.
	var a: SimulationMachine = _simulation()
	var b: SimulationMachine = _simulation()
	verifier_proche(
		a.effectuer_mesure(a.etat_pour_etalon(200.0)).x,
		b.effectuer_mesure(b.etat_pour_etalon(200.0)).x,
		"deux releves identiques"
	)


func test_releves_accumules() -> void:
	var simulation: SimulationMachine = _simulation()
	for etalon: float in _machine().etalons:
		simulation.effectuer_mesure(simulation.etat_pour_etalon(etalon))
	verifier_egal(simulation.releves().size(), 7, "un point par etalon")


func test_specification_exacte_donne_trois_etoiles() -> void:
	var simulation: SimulationMachine = _simulation()
	var resultat: ResultatBanc = simulation.soumettre_specification(_spec(SOLUTION_A, SOLUTION_B))
	verifier(resultat.est_valide(), "le banc a pu evaluer")
	verifier_egal(resultat.etoiles, 3, "trois etoiles")
	verifier_proche(resultat.ecart_max, 0.0, "ecart nul", 1e-9)
	verifier_egal(resultat.details.size(), 3, "un detail par cas cache")


func test_le_piege_du_crochet() -> void:
	# La faute que la machine est concue pour provoquer : supposer la relation
	# proportionnelle alors qu'elle est affine. Le banc ne dit pas "faux", il
	# rend un ecart enorme et deux courbes qui divergent.
	var simulation: SimulationMachine = _simulation()
	var resultat: ResultatBanc = simulation.soumettre_specification(_spec(SOLUTION_A, 0.0))
	verifier(resultat.est_valide(), "le banc evalue quand meme")
	verifier_egal(resultat.etoiles, 0, "aucune etoile")
	verifier(resultat.ecart_max > 1.0, "l'ecart depasse 100 %")
	verifier_egal(
		resultat.points_reels.size(), resultat.points_predits.size(), "deux courbes superposables"
	)
	verifier(
		resultat.points_predits[0].y > resultat.points_reels[0].y,
		"le modele sans terme constant surestime la masse"
	)


## Calibration a deux points, comme le joueur la fait reellement.
func _calibrer(simulation: SimulationMachine, etalon_bas: float, etalon_haut: float) -> ResultatBanc:
	var bas: Vector2 = simulation.effectuer_mesure(simulation.etat_pour_etalon(etalon_bas))
	var haut: Vector2 = simulation.effectuer_mesure(simulation.etat_pour_etalon(etalon_haut))
	var a: float = (haut.y - bas.y) / (haut.x - bas.x)
	var b: float = bas.y - a * bas.x
	return simulation.soumettre_specification(_spec(a, b))


func test_calibration_en_deux_points_du_joueur() -> void:
	# Le parcours reel : accrocher les deux etalons extremes, lire la regle au
	# millimetre, resoudre le systeme. La quantification laisse un residu, mais un
	# joueur qui prend le bras de levier le plus long atteint le palier le plus fin.
	var resultat: ResultatBanc = _calibrer(_simulation(), 5.0, 500.0)
	verifier_egal(resultat.etoiles, 3, "la calibration soigneuse atteint trois etoiles")
	verifier(resultat.ecart_max < 0.01, "moins de 1 % d'ecart")


func test_le_bras_de_levier_de_la_calibration() -> void:
	# Deux etalons voisins : la regle au millimetre ne resout plus l'ecart entre
	# eux, la pente est fausse et l'erreur s'amplifie en extrapolant. La piece
	# passe quand meme — on avance avec une piece mediocre et on revient plus tard.
	var court: ResultatBanc = _calibrer(_simulation(), 25.0, 50.0)
	var long: ResultatBanc = _calibrer(_simulation(), 5.0, 500.0)

	verifier(court.equipable(), "une piece grossiere reste equipable")
	verifier(court.etoiles < 3, "mais elle n'atteint pas le palier fin")
	verifier(
		court.ecart_max > long.ecart_max * 5.0,
		"un bras de levier court degrade nettement le modele"
	)


func test_paliers() -> void:
	verifier_egal(ResultatBanc.etoiles_pour(0.005), 3, "0,5 %")
	verifier_egal(ResultatBanc.etoiles_pour(0.01), 3, "exactement 1 %")
	verifier_egal(ResultatBanc.etoiles_pour(0.03), 2, "3 %")
	verifier_egal(ResultatBanc.etoiles_pour(0.05), 2, "exactement 5 %")
	verifier_egal(ResultatBanc.etoiles_pour(0.15), 1, "15 %")
	verifier_egal(ResultatBanc.etoiles_pour(0.20), 1, "exactement 20 %")
	verifier_egal(ResultatBanc.etoiles_pour(0.25), 0, "25 %")


func test_piece_validee_ameliore_la_primitive() -> void:
	var simulation: SimulationMachine = _simulation()
	var recues: Array[Piece] = []
	simulation.piece_validee.connect(func(piece: Piece) -> void: recues.append(piece))
	simulation.soumettre_specification(_spec(SOLUTION_A, SOLUTION_B))

	verifier_egal(recues.size(), 1, "une piece est entree a l'atelier")
	if recues.is_empty():
		return
	verifier_egal(recues[0].primitive_amelioree, &"peser", "c'est peser qui s'affine")
	verifier_proche(recues[0].pas_ameliore, 5.0, "de 100 g a 5 g")
	verifier_egal(recues[0].etoiles, 3, "la piece garde ses etoiles")


func test_piece_refusee_sous_le_seuil() -> void:
	var simulation: SimulationMachine = _simulation()
	var recues: Array[Piece] = []
	simulation.piece_validee.connect(func(piece: Piece) -> void: recues.append(piece))
	simulation.soumettre_specification(_spec(SOLUTION_A, 0.0))
	verifier_egal(recues.size(), 0, "une piece a zero etoile n'equipe pas")


func test_precision_amelioree_est_injectee() -> void:
	# La simulation ne lit aucun etat global : l'atelier lui passe les resolutions
	# courantes. Ici la regle est remplacee par un instrument au dixieme.
	var simulation: SimulationMachine = SimulationMachine.new(_machine(), 0, {&"voir": 0.1})
	var point: Vector2 = simulation.effectuer_mesure(simulation.etat_pour_etalon(50.0))
	# Tolerance large : les composantes d'un Vector2 sont en simple precision.
	# Sans consequence ici, la resolution la plus fine du jeu restant cinq ordres
	# de grandeur au-dessus.
	verifier_proche(point.x, 70.4, "lecture au dixieme de mm", 1e-4)


func test_fiche_incomplete_refusee_sans_consommer_de_matiere() -> void:
	var simulation: SimulationMachine = _simulation()
	var avant: int = simulation.matiere_restante()
	var resultat: ResultatBanc = simulation.soumettre_specification(
		Specification.new(_emplacement(), {"a": 5.0})
	)
	verifier(not resultat.est_valide(), "un champ vide n'est pas un zero")
	verifier_egal(simulation.matiere_restante(), avant, "aucune matiere consommee")


func test_budget_de_matiere() -> void:
	var simulation: SimulationMachine = _simulation()
	verifier_egal(simulation.matiere_restante(), 12, "budget initial")

	var consommees: Array[int] = []
	simulation.matiere_modifiee.connect(func(restante: int) -> void: consommees.append(restante))
	for i: int in 12:
		simulation.soumettre_specification(_spec(1.0, 1.0))

	verifier_egal(simulation.matiere_restante(), 0, "budget epuise")
	verifier_egal(consommees.size(), 12, "chaque soumission est signalee")
	var apres: ResultatBanc = simulation.soumettre_specification(_spec(SOLUTION_A, SOLUTION_B))
	verifier(not apres.est_valide(), "le banc refuse sans matiere")


func test_signal_de_resultat() -> void:
	var simulation: SimulationMachine = _simulation()
	var recus: Array[ResultatBanc] = []
	simulation.specification_evaluee.connect(func(r: ResultatBanc) -> void: recus.append(r))
	simulation.soumettre_specification(_spec(SOLUTION_A, SOLUTION_B))
	verifier_egal(recus.size(), 1, "le resultat est diffuse par signal")


func test_courbes_pour_le_graphe() -> void:
	var simulation: SimulationMachine = _simulation()
	var predite: PackedVector2Array = simulation.courbe_predite(_spec(SOLUTION_A, SOLUTION_B), 70.0, 240.0)
	var reelle: PackedVector2Array = simulation.courbe_reelle(70.0, 240.0)

	verifier_egal(predite.size(), 64, "la courbe predite est echantillonnee")
	verifier_egal(reelle.size(), 64, "la courbe reelle aussi")
	# Le modele exact se superpose a la machine : c'est ce que le joueur voit
	# quand il a trouve.
	for i: int in predite.size():
		verifier_proche(predite[i].y, reelle[i].y, "superposition au point %d" % i, 1e-6)


func test_courbe_predite_refusee_si_fiche_incomplete() -> void:
	var simulation: SimulationMachine = _simulation()
	var courbe: PackedVector2Array = simulation.courbe_predite(
		Specification.new(_emplacement(), {}), 70.0, 240.0
	)
	verifier_egal(courbe.size(), 0, "rien a tracer tant que la fiche est vide")
