## Socle commun des suites de test.
##
## Runner maison plutot qu'un addon : zero dependance, et le besoin se limite
## pour l'instant a comparer des flottants. A reevaluer si le nombre de tests
## explose.
##
## GDScript n'a pas d'exceptions : une verification qui echoue est accumulee et
## le test continue, ce qui donne toutes les erreurs d'un coup au lieu de la
## premiere.
extends RefCounted

const TOLERANCE_DEFAUT: float = 1e-6

var _echecs: Array[String] = []
var _verifications: int = 0
var _test_courant: String = ""


func demarrer_test(nom: String) -> void:
	_test_courant = nom


func echecs() -> Array[String]:
	return _echecs


func nb_verifications() -> int:
	return _verifications


func verifier(condition: bool, message: String) -> void:
	_verifications += 1
	if not condition:
		_noter(message)


func verifier_proche(
	obtenu: float, attendu: float, message: String, tolerance: float = TOLERANCE_DEFAUT
) -> void:
	_verifications += 1
	if is_nan(obtenu):
		_noter("%s : obtenu NAN, attendu %s" % [message, attendu])
		return
	if absf(obtenu - attendu) > tolerance:
		# Le formatage de Godot ne connait pas %g : passer les ecarts en %s.
		_noter(
			(
				"%s : obtenu %.6f, attendu %.6f (ecart %s > tolerance %s)"
				% [message, obtenu, attendu, absf(obtenu - attendu), tolerance]
			)
		)


func verifier_egal(obtenu: Variant, attendu: Variant, message: String) -> void:
	_verifications += 1
	if obtenu != attendu:
		_noter("%s : obtenu %s, attendu %s" % [message, obtenu, attendu])


func verifier_nan(obtenu: float, message: String) -> void:
	_verifications += 1
	if not is_nan(obtenu):
		_noter("%s : obtenu %.6f, attendu un echec (NAN)" % [message, obtenu])


func _noter(message: String) -> void:
	_echecs.append("%s : %s" % [_test_courant, message])
