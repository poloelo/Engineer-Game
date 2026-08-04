# Tous les reglages de feel, au meme endroit, modifiables a chaud (Tab).
#
# TOUT EST EN MILLIMETRES, GRAMMES ET SECONDES. Aucune valeur de ce fichier n'est
# en pixels. Une force se compte en g.mm/s2 (10^-6 N), une raideur en g/s2
# (10^-6 N/mm), un amortissement lateral en 1/s.
#
# La gravite n'est pas ici : elle vaut 9,81 m/s2, c'est une constante universelle
# et non un parametre de feel. Voir unites.gd.
#
# Ce sont des `static var` et non des constantes, justement pour que le panneau
# de debug puisse les tripoter pendant que le jeu tourne.
#
# Prototype jetable : pas de class_name, pour ne rien enregistrer dans le
# registre global du projet principal qui vit a cote.
extends RefCounted

# --- Temps -------------------------------------------------------------------

## Echelle de temps globale. A 1.0 le montage tourne en temps reel. En dessous,
## tout ralentit ensemble — le ressort, les chutes, le curseur — sans qu'aucune
## grandeur physique ne mente. C'est le seul levier de feel qui touche a g sans
## y toucher.
static var ECHELLE_TEMPS: float = 1.0

# --- Ressort -----------------------------------------------------------------

## Longueur du ressort sans rien accroche, en mm.
static var LONGUEUR_REPOS: float = 40.0

## Raideur, en g/s2. Elle donne 1,3728 mm par gramme.
##
## LA VALEUR NE DOIT PAS ETRE RONDE, ET C'EST LE POINT LE PLUS FRAGILE DU NIVEAU.
## Calee sur 9810 elle donnait exactement un millimetre par gramme : la regle
## graduee en millimetres devenait une balance en grammes, le joueur lisait 56 mm
## au-dessus de son zero et le niveau n'avait plus de contenu. Plus de
## subdivision, plus d'interpolation, plus de linearite decouverte.
##
## A 1,3728 mm/g, un millimetre vaut 0,728 g : ni un sens ni l'autre ne se lit de
## tete, et il faut vraiment interpoler entre deux marques annotees.
##
## Reste lisible : 2 g de tolerance font 2,75 mm, deux etalons voisins (10 g)
## sont a 13,7 mm l'un de l'autre, et la course de 0 a 143 g fait 196 mm — elle
## tient tout juste sur la regle de 200.
static var RAIDEUR: float = 7146.0

## Masse totale du fil du ressort, en g. Elle sert deux fois, et pas avec le meme
## coefficient — c'est le resultat classique du ressort pesant :
##   - un tiers s'ajoute a l'inertie de la charge (elle fixe la frequence),
##   - une moitie s'ajoute au poids suspendu (elle etire le ressort a vide).
## C'est la « masse lineique » du brief, faite au moins cher.
static var MASSE_RESSORT: float = 18.0

## Amortissement le long de l'axe du ressort : c'est lui qui calme le yoyo.
## Applique en racine de la masse, pour que le taux d'amortissement ne depende
## pas de la charge — sans quoi une masse lourde revient dans du sirop et une
## masse legere claque, avec le meme reglage.
static var AMORTISSEMENT: float = 52.0

## Amortissement perpendiculaire a l'axe : c'est lui qui calme le balancement.
## En 1/s : la moitie de cette valeur est le taux de decroissance du ballant,
## independamment de la charge et des unites.
static var AMORTISSEMENT_LATERAL: float = 2.0

## Amortissement quand la butee est rabattue. Doit etre assez haut pour figer net.
static var AMORTISSEMENT_BUTEE: float = 262.0

## Amplitude d'oscillation restante, en mm, en dessous de laquelle le ressort se
## pose franchement. Sans ce seuil il fremit indefiniment, ce qui est
## insupportable quand on essaie de lire une position au millimetre — et
## maintenant le millimetre est un vrai millimetre, donc le seuil est serre.
static var SEUIL_REPOS: float = 0.6

## Retard angulaire d'un maillon sur le precedent. C'est le flottement entre deux
## masses empilees. A 1.0 la chaine est rigide.
static var SOUPLESSE_CHAINE: float = 0.22

# --- Traine au curseur -------------------------------------------------------

## Rappel vers le pointeur, en g/s2. Bas = l'objet traine loin derriere, haut =
## il colle.
static var RAIDEUR_CURSEUR: float = 8600.0

## Amortissement de la traine. Applique en racine de la masse, pour que le temps
## de reponse depende du poids sans que les petites masses deviennent pateuses.
static var AMORTISSEMENT_CURSEUR: float = 124.0

## Part du poids compensee pendant qu'on traine. A 1.0 l'objet ne pese plus rien
## au curseur ; a 0.0 il pend franchement sous le pointeur.
static var COMPENSATION_POIDS: float = 0.75

# --- Accrochage --------------------------------------------------------------

## Rayon de la zone d'aimantation autour du point d'accroche, en mm.
##
## Resserre : cette zone est prioritaire sur le tampon, et les marques tombent
## juste au-dessus du point d'accroche. Trop large, elle mangeait la zone ou l'on
## annote et le joueur ne pouvait plus tamponner ses marques basses.
static var RAYON_AIMANTATION: float = 20.0

## Attraction ressentie quand on entre dans la zone, en mm/s2. Met un peu de
## colle. Relevee par rapport a l'ancienne valeur : la gravite visible ayant
## augmente avec le passage a g reel, une aimantation convertie telle quelle ne
## faisait plus le poids.
static var FORCE_AIMANTATION: float = 1200.0

## Coup de fouet donne au ressort au moment ou ca accroche, en mm/s. C'est le
## "clac".
static var AMPLITUDE_SURSAUT: float = 150.0

## Allongement supplementaire, au-dela de l'equilibre, qui fait lacher la prise,
## en mm. Bas = ca decroche tout le temps par accident, haut = on n'arrive plus
## a retirer.
static var SEUIL_DECROCHAGE: float = 52.0

## Part de la vitesse d'une masse qui percute la chaine, transmise au ressort.
static var TRANSMISSION_CHOC: float = 0.55

# --- Masses libres -----------------------------------------------------------

## Rebond au sol et entre masses. Au-dela de 0.5 ca devient sautillant.
static var REBOND: float = 0.26

## Friction : ce qui decide si une masse roule longtemps ou se pose net.
static var FRICTION: float = 0.62

## Freinage de roulement, pour qu'une masse finisse par s'arreter.
static var FREIN_ROULEMENT: float = 1.4

# --- Instruments de trace ----------------------------------------------------

## Distance a laquelle le stylo se clipse sur un marqueur, en mm.
static var RAYON_CLIPSAGE: float = 23.0

## Deplacement minimal de la pointe avant d'ajouter un point a la trace, en mm.
## Bas = trace tres fine mais lourde, haut = trace anguleuse.
static var PAS_TRACE: float = 0.8

## Distance en dessous de laquelle le zero de la regle se cale de lui-meme sur une
## marque, en mm. Le geste de base du niveau est « je cale le zero sur un repere
## et je lis l'autre » : il doit se faire tout seul, donc l'aimant est franc.
static var AIMANT_REGLE: float = 18.0

## Ecart angulaire, en degres, en dessous duquel la regle se cale sur l'horizontale
## ou la verticale. On ne s'en sert que droite ; il faut forcer pour l'incliner.
static var AIMANT_ANGLE_REGLE: float = 9.0

## Rayon de la loupe, en mm de monde — elle a une taille physique comme le reste.
static var RAYON_LOUPE: float = 39.0

## Grossissement de la loupe. En dessous de 2 elle ne sert a rien.
static var GROSSISSEMENT_LOUPE: float = 3.2

# --- Dessin ------------------------------------------------------------------

## Nombre de spires. Elles s'ecartent toutes seules quand le ressort s'etire.
static var SPIRES: int = 13

## Demi-largeur d'une spire au repos, en mm. Le ressort se pince quand il
## s'allonge.
static var LARGEUR_SPIRE: float = 9.0

## Ballant lateral du ressort en mouvement, en secondes (il convertit une vitesse
## en un ecart). C'est ce qui lui donne l'air vivant. A 0 il monte et descend
## comme un piston.
static var BALLANT: float = 0.075
