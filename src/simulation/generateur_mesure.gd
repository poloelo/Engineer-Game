## Traduit une valeur vraie en ce que l'instrument du joueur affiche reellement.
##
## L'imprecision est d'abord une resolution, pas un tremblement : une balance a
## pas de 100 g rend toujours la meme valeur pour la meme masse. C'est ce qui
## rend le jeu deterministe et les tests reproductibles, et c'est aussi plus
## honnete — un instrument grossier ment de facon stable.
class_name GenerateurMesure
extends RefCounted

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(graine: int = 0) -> void:
	_rng.seed = graine


## Rend la lecture affichee. [param pas_effectif] permet a l'atelier d'imposer la
## resolution amelioree d'une piece fabriquee sans modifier la primitive d'origine.
func mesurer(valeur_vraie: float, instrument: Primitive, pas_effectif: float = -1.0) -> float:
	# Pas d'instrument : la valeur est connue exactement. Les masses etalons ne
	# se pesent pas, elles sont gravees.
	if instrument == null:
		return valeur_vraie
	if instrument.qualitative:
		return valeur_vraie

	var valeur: float = valeur_vraie
	if instrument.bruit > 0.0:
		valeur += _rng.randfn(0.0, instrument.bruit)

	var pas: float = instrument.pas if pas_effectif < 0.0 else pas_effectif
	if pas <= 0.0:
		return valeur
	return snappedf(valeur, pas)
