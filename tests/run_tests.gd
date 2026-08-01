## Runner de tests headless.
##
##     godot --headless --script res://tests/run_tests.gd
##
## Decouvre tout fichier tests/test_*.gd, instancie la suite et appelle chacune
## de ses methodes test_*. Code de sortie non nul si une verification echoue, de
## sorte que la commande soit utilisable telle quelle en integration continue.
extends SceneTree

const DOSSIER: String = "res://tests"
const PREFIXE_FICHIER: String = "test_"
const PREFIXE_METHODE: String = "test_"


func _initialize() -> void:
	var chemins: PackedStringArray = _lister_suites()
	if chemins.is_empty():
		print("Aucune suite de test trouvee dans %s" % DOSSIER)
		quit(1)
		return

	var total_verifications: int = 0
	var total_tests: int = 0
	var tous_echecs: Array[String] = []

	for chemin: String in chemins:
		var script: GDScript = load(chemin) as GDScript
		if script == null:
			tous_echecs.append("%s : script illisible" % chemin)
			continue

		var suite: Object = script.new()
		var noms: Array[String] = _lister_tests(suite)
		print("\n  %s  (%d tests)" % [chemin.get_file(), noms.size()])

		for nom: String in noms:
			var avant: int = suite.get("_echecs").size()
			suite.call("demarrer_test", nom)
			suite.call(nom)
			total_tests += 1
			var echecs: Array = suite.get("_echecs")
			var nouveaux: int = echecs.size() - avant
			print("    %s %s" % ["." if nouveaux == 0 else "X", nom])

		total_verifications += int(suite.get("_verifications"))
		for echec: String in suite.get("_echecs"):
			tous_echecs.append("%s > %s" % [chemin.get_file(), echec])

	print("")
	if tous_echecs.is_empty():
		print(
			(
				"OK — %d tests, %d verifications, 0 echec"
				% [total_tests, total_verifications]
			)
		)
		quit(0)
		return

	print("ECHEC — %d tests, %d verifications, %d echecs" % [
		total_tests, total_verifications, tous_echecs.size()
	])
	for echec: String in tous_echecs:
		print("  - %s" % echec)
	quit(1)


func _lister_suites() -> PackedStringArray:
	var chemins: PackedStringArray = PackedStringArray()
	var dossier: DirAccess = DirAccess.open(DOSSIER)
	if dossier == null:
		return chemins
	for fichier: String in dossier.get_files():
		# Godot renomme les scripts en .gd.remap dans un projet exporte.
		var nom: String = fichier.trim_suffix(".remap")
		if nom.begins_with(PREFIXE_FICHIER) and nom.ends_with(".gd"):
			chemins.append("%s/%s" % [DOSSIER, nom])
	chemins.sort()
	return chemins


func _lister_tests(suite: Object) -> Array[String]:
	var noms: Array[String] = []
	for methode: Dictionary in suite.get_method_list():
		var nom: String = methode["name"]
		if nom.begins_with(PREFIXE_METHODE) and not noms.has(nom):
			noms.append(nom)
	noms.sort()
	return noms
