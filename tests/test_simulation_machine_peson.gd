## La physique d'une machine, eprouvee sans ouvrir une seule scene.
##
## Il ne reste ici que ce qui decrit la machine elle-meme : charger sa
## definition, lui imposer un etalon, la lire a travers un instrument dont la
## resolution ment. Tout ce qui evaluait une fiche technique sur des cas caches a
## disparu avec le banc d'essai.
extends "res://tests/support/test_base.gd"

const PESON: String = "res://src/contenu/data/machines/peson.tres"


func _machine() -> MachineDef:
	return load(PESON) as MachineDef


func _simulation() -> SimulationMachine:
	return SimulationMachine.new(_machine())


func test_machine_chargee_depuis_donnee() -> void:
	var machine: MachineDef = _machine()
	verifier(machine != null, "peson.tres se charge en MachineDef")
	if machine == null:
		return
	verifier_egal(machine.id, &"peson", "id")
	verifier_egal(machine.verifier(), [] as Array[String], "la machine est structurellement saine")
	verifier_egal(machine.grandeur_lue, &"longueur", "on lit une longueur")
	verifier_egal(machine.grandeur_produite, &"masse", "on en deduit une masse")


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


func test_precision_amelioree_est_injectee() -> void:
	# La simulation ne lit aucun etat global : on lui passe les resolutions
	# courantes. Ici la regle est remplacee par un instrument au dixieme.
	var simulation: SimulationMachine = SimulationMachine.new(_machine(), 0, {&"voir": 0.1})
	var point: Vector2 = simulation.effectuer_mesure(simulation.etat_pour_etalon(50.0))
	# Tolerance large : les composantes d'un Vector2 sont en simple precision.
	verifier_proche(point.x, 70.4, "lecture au dixieme de mm", 1e-4)


func test_courbe_reelle_de_la_machine() -> void:
	var simulation: SimulationMachine = _simulation()
	var courbe: PackedVector2Array = simulation.courbe_reelle(60.0, 120.0, 8)
	verifier_egal(courbe.size(), 8, "huit points sur la plage demandee")
	if courbe.size() < 2:
		return
	# La loi du peson est affine : la masse croit avec la longueur lue.
	verifier(courbe[-1].y > courbe[0].y, "la masse croit avec l'allongement")
