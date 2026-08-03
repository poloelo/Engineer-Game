# Le monde s'exprime en millimetres, en grammes, en secondes.
#
# Toute la simulation vit dans ces unites : une longueur est un millimetre reel,
# une masse est un gramme reel, une force est un g.mm/s2 (10^-6 newton). La
# gravite vaut 9,81 m/s2 et ne se regle pas — si la sensation ne va pas, on
# ajuste les masses, les raideurs ou l'echelle de temps, jamais g.
#
# PIXELS_PAR_MM est la SEULE constante qui relie le monde a l'ecran. Elle ne sert
# qu'au reglage de la camera et au dimensionnement des cibles de rendu ; aucune
# ligne de simulation ne la lit. Changer la resolution ne change donc rien au
# comportement du jeu : c'est la camera qui cadre, pas la physique qui s'adapte.
#
# Consequence recherchee : une graduation gravee a 10 mm sur la regle mesure
# reellement 10 mm du monde. L'instrument cesse de mentir.
extends RefCounted

## Combien de pixels vaut un millimetre du monde, a la resolution de reference
## (1280 x 720). Le mode d'etirement du projet fait le reste : a 1152 x 648 comme
## a 3840 x 2160, la meme etendue de monde remplit l'ecran.
const PIXELS_PAR_MM: float = 2.0

## Etendue de monde visible, en millimetres. Un etabli de 64 cm sur 36 cm.
const MONDE: Vector2 = Vector2(640.0, 360.0)

## Gravite terrestre, en mm/s2. Ce n'est pas un parametre de feel.
const GRAVITE: float = 9810.0

## Un newton, en unites internes (g.mm/s2). Sert a lire les raideurs : une
## raideur de 2600 g/s2 vaut 2600 / NEWTON_PAR_MM = 2,6 N/m.
const NEWTON_PAR_MM: float = 1_000_000.0


## Zoom de camera qui rend PIXELS_PAR_MM a la resolution de reference.
static func zoom_camera() -> Vector2:
	return Vector2.ONE * PIXELS_PAR_MM


## Centre du monde, ou se pose la camera.
static func centre() -> Vector2:
	return MONDE * 0.5
