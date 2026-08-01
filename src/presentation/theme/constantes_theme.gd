## Le seul endroit du projet ou une couleur, une taille de police ou une epaisseur
## de trait est ecrite. Aucune scene n'a le droit d'en definir en dur.
##
## L'esthetique est celle d'un plan technique : un fond bleu, des traits clairs,
## rien d'autre. Tout est dessine dans [method CanvasItem._draw], donc le jeu n'a
## aucun asset — une ligne ne coute rien.
class_name ThemeBlueprint
extends RefCounted

# --- Fonds -------------------------------------------------------------------

const FOND: Color = Color("0d243d")
const FOND_PANNEAU: Color = Color("112c48")
const FOND_CHAMP: Color = Color("0a1d31")

# --- Grille ------------------------------------------------------------------

const GRILLE_FINE: Color = Color(1.0, 1.0, 1.0, 0.05)
const GRILLE_FORTE: Color = Color(1.0, 1.0, 1.0, 0.12)

# --- Traits ------------------------------------------------------------------

const TRAIT: Color = Color("e6f0f8")
const TRAIT_EFFACE: Color = Color(0.90, 0.94, 0.97, 0.45)
const TRAIT_TRES_EFFACE: Color = Color(0.90, 0.94, 0.97, 0.20)

# --- Roles de donnee ---------------------------------------------------------

## Les releves du joueur : ce qu'il a mesure lui-meme.
const RELEVE: Color = Color("6fd3ff")

## Son modele, trace en surimpression. Chaud pour trancher avec ses releves.
const MODELE: Color = Color("ffb454")

## La machine reelle, revelee par le banc d'essai.
const REEL: Color = Color("8ef0b8")

## Un ecart trop grand. Jamais utilise pour dire "faux", seulement pour situer.
const ECART: Color = Color("ff7a7a")

# --- Epaisseurs --------------------------------------------------------------

const TRAIT_FIN: float = 1.0
const TRAIT_NORMAL: float = 2.0
const TRAIT_EPAIS: float = 3.0

const RAYON_POINT: float = 4.0
const LONGUEUR_TIRET: float = 7.0

# --- Typographie -------------------------------------------------------------

const POLICE_PETITE: int = 12
const POLICE_NORMALE: int = 15
const POLICE_GRANDE: int = 20
const POLICE_TITRE: int = 28

# --- Espacements -------------------------------------------------------------

const MARGE: float = 16.0
const MARGE_GRAPHE: float = 52.0
const INTERLIGNE: float = 8.0


## La police par defaut du moteur. Le jeu n'embarque aucun fichier de fonte :
## pas d'asset externe, y compris pour le texte.
static func police() -> Font:
	return ThemeDB.fallback_font
