# Tous les reglages de feel, au meme endroit, modifiables a chaud (Tab).
#
# Ce sont des `static var` et non des constantes, justement pour que le panneau
# de debug puisse les tripoter pendant que le jeu tourne.
#
# Prototype jetable : pas de class_name, pour ne rien enregistrer dans le
# registre global du projet principal qui vit a cote.
extends RefCounted

# --- Ressort -----------------------------------------------------------------

## Longueur du ressort sans rien accroche, en pixels.
static var LONGUEUR_REPOS: float = 95.0

## Raideur. Plus c'est haut, moins ca s'allonge et plus ca oscille vite.
static var RAIDEUR: float = 26.0

## Amortissement du ressort. Bas = ca yoyote longtemps, haut = ca se pose vite.
## Vers 10 l'oscillation disparait completement (regime critique).
static var AMORTISSEMENT: float = 2.4

## Amortissement quand la butee est rabattue. Doit etre assez haut pour figer net.
static var AMORTISSEMENT_BUTEE: float = 26.0

## Masse propre du ressort. Evite qu'il devienne infiniment nerveux a vide.
static var MASSE_RESSORT: float = 0.35

## Gravite appliquee au ressort ET aux masses libres.
static var GRAVITE: float = 1500.0

# --- Traine au curseur -------------------------------------------------------

## Rappel vers le pointeur. Bas = l'objet traine loin derriere, haut = il colle.
static var RAIDEUR_CURSEUR: float = 650.0

## Amortissement de la traine. Applique en racine de la masse, pour que le temps
## de reponse depende du poids sans que les petites masses deviennent pateuses.
## Au-dela de ~40 tout devient sirupeux, en dessous de ~20 tout depasse la cible.
static var AMORTISSEMENT_CURSEUR: float = 34.0

## Part du poids compensee pendant qu'on traine. A 1.0 l'objet ne pese plus rien
## au curseur ; a 0.0 il pend franchement sous le pointeur.
static var COMPENSATION_POIDS: float = 0.55

# --- Accrochage --------------------------------------------------------------

## Rayon de la zone d'aimantation autour du point d'accroche.
static var RAYON_AIMANTATION: float = 62.0

## Attraction ressentie quand on entre dans la zone. Met un peu de colle.
static var FORCE_AIMANTATION: float = 900.0

## Coup de fouet donne au ressort au moment ou ca accroche. C'est le "clac".
static var AMPLITUDE_SURSAUT: float = 300.0

## Allongement supplementaire, au-dela de l'equilibre, qui fait lacher la prise.
## Bas = ca decroche tout le temps par accident, haut = on n'arrive plus a retirer.
static var SEUIL_DECROCHAGE: float = 105.0

## Part de la vitesse d'une masse qui percute la chaine, transmise au ressort.
static var TRANSMISSION_CHOC: float = 0.55

# --- Masses libres -----------------------------------------------------------

## Rebond au sol et entre masses. Au-dela de 0.5 ca devient sautillant.
static var REBOND: float = 0.26

## Friction : ce qui decide si une masse roule longtemps ou se pose net.
static var FRICTION: float = 0.62

## Freinage de roulement, pour qu'une masse finisse par s'arreter.
static var FREIN_ROULEMENT: float = 1.4

# --- Dessin ------------------------------------------------------------------

## Nombre de spires. Elles s'ecartent toutes seules quand le ressort s'etire.
static var SPIRES: int = 13

## Demi-largeur d'une spire au repos. Le ressort se pince quand il s'allonge.
static var LARGEUR_SPIRE: float = 18.0

## Ballant lateral du ressort en mouvement. C'est ce qui lui donne l'air vivant.
## A 0 il monte et descend comme un piston.
static var BALLANT: float = 0.075
