# Le Jeu de l'Ingénieur

Un jeu d'instruments. On ne répond pas à des questions : **on fabrique ses propres mesures**,
à la main, avec ce qu'on a sur l'établi.

Le joueur reçoit une commande. Ses instruments sont trop grossiers pour l'honorer. Il en
construit un meilleur — un ressort, un crochet, des masses étalons, un stylo, une feuille,
une règle — puis il s'en sert.

Aucun QCM, aucune note, aucune étoile, aucun verdict. Rien ne vérifie ce qui sort de
l'atelier. Le seul texte du jeu est le bon de travail ; les seuls chiffres sont gravés sur
la règle et écrits sur ce bon.

Godot 4.7.1 · GDScript typé · tout est dessiné dans `_draw`, les textures sont optionnelles.

---

## Lancer

```sh
godot --path .        # ou ouvrir le projet dans l'éditeur
```

La scène principale est `src/atelier/atelier.tscn` — c'est le niveau 1, et pour l'instant
tout le jeu.

| Geste | Comment |
|---|---|
| prendre, poser, accrocher | clic gauche maintenu |
| baisser / lever la pointe du stylo | espace, ou clic droit |
| clipser le stylo sur une masse | le lâcher à côté d'elle |
| faire pivoter la règle | l'attraper par un bout au lieu du corps |
| incliner le pot de poudre | l'attraper par sa poignée, en haut |
| ranger les masses · retourner la feuille | `R` · `F` |
| effacer la face · feuille vierge · exporter en PNG | `P` · `N` · `E` |
| régler la physique à chaud | `Tab` |

## Tester

```sh
tests/run.sh                       # utilise le binaire `godot` du PATH
GODOT=/chemin/vers/godot tests/run.sh
```

Le runner est headless, sans dépendance externe, et rend un code de sortie non nul en cas
d'échec.

```
OK — 14 tests, 36 verifications, 0 echec
```

Les tests portent sur le **contenu** (lois, grandeurs, formes) et sur la **physique d'une
machine**. L'atelier lui-même n'est pas testé : c'est de la manipulation, ça se juge à la
main.

---

## Le niveau 1

> Trois sachets de poudre : 56 g, 89 g, 143 g.

La balance de l'atelier a un pas de 100 g. Elle ne bouge pas. Le kit contient un ressort,
un crochet, quatre masses étalons (20, 50, 100, 150 g), un stylo, une feuille, une règle et
une loupe.

Le parcours attendu, que rien n'impose et que rien ne guide :

1. clipser le stylo au crochet, pointe baissée ;
2. accrocher un étalon — le ressort descend, le stylo marque le papier ;
3. recommencer avec les autres étalons, en décalant la feuille entre deux ;
4. poser la règle sur les marques, constater qu'elles sont **régulièrement espacées**,
   subdiviser à la main pour fabriquer les graduations manquantes ;
5. pendre un sachet vide, incliner le pot, et verser jusqu'à sa propre marque.

Le livrable du niveau n'est pas une équation. C'est **un cadran gradué à la main et trois
sachets produits**.

**Deux pièges, et ce sont les mêmes.** Le crochet pèse 8 g et le sachet vide 12 g. Ils
étirent déjà le ressort avant qu'on ait rien accroché : le zéro du joueur n'est pas là où
il croit. Le crochet se dévisse — c'est le geste qui fait comprendre d'où vient l'écart.

Les quatre paliers, mesurés à l'arrêt : **85,81 · 116,47 · 167,56 · 218,65 mm**, soit
1,0219 mm/g d'un bout à l'autre. C'est cette régularité qui autorise la subdivision, et
aucune combinaison d'étalons ne tombe sur 56, 89 ni 143.

---

## Comment c'est fait

### Le monde est en millimètres

Toute la simulation est en **mm, g, s** — forces en g·mm/s². La gravité vaut 9,81 m/s² et
n'est pas réglable. Une seule constante, `unites.gd : PIXELS_PAR_MM`, relie le monde à
l'écran, et elle ne sert qu'au zoom de la `Camera2D`.

Conséquence recherchée : **une graduation gravée à 10 mm couvre réellement 10 mm de monde.**
Pour un jeu dont le sujet est la mesure, l'instrument ne peut pas mentir. Le jeu tourne à
l'identique en 1152 × 648 et en 4K — la résolution est un problème de caméra, jamais de
physique.

### Physique hybride

Les masses libres sont des `RigidBody2D` : chute, rebond, empilement, roulement, le moteur
le fait mieux et gratuitement. **Le ressort est intégré à la main**, et il le reste : un
`DampedSpringJoint2D` donnerait un pendule mou impossible à régler, alors que deux
constantes lisibles se règlent en dix secondes (`Tab`).

Le ressort est libre dans le plan. Sa force s'applique le long de son axe courant, la
gravité reste verticale ; le balancement n'est écrit nulle part, il tombe de la combinaison
des deux.

### Deux couches par objet

Chaque objet est coupé en une **forme** (collision, masse, points d'attache — elle ne change
jamais) et un **visuel** enfant remplaçable, qui prend une texture si elle existe et retombe
sur le dessin procédural sinon. Déposer `textures/masse_50g.png` suffit — voir
`textures/LISEZMOI.md`.

Les points d'attache sont des `Marker2D` nommés (`crochet`, `pointe`, `bord_zero`,
`goulot`, `bouche`), cherchés par genre et par rayon. Aucune position n'est écrite en dur
dans la logique de clipsage.

### La loupe et l'encre sont des `SubViewport`

La **loupe** refilme la même scène à travers une caméra zoomée, en partageant le `World2D`.
Elle grossit donc tout ce qui passe dessous sans qu'un seul cas particulier soit écrit.

L'**encre** est une cible de rendu qui ne s'efface jamais (`CLEAR_MODE_NEVER`, `UPDATE_ONCE`
à la demande). Le stylo dépose son trait une fois et il reste : une trace d'une heure ne
coûte pas une frame de plus qu'une trace vide. C'est aussi ce qui rend l'export PNG trivial
— la texture *est* l'image.

---

## Arborescence

```
src/atelier/            LE JEU. Le niveau 1 et tous ses objets.
  atelier.gd            la scène : le ressort intégré à la main, la saisie, le versage
  unites.gd             mm, g, s — et la seule constante qui connaisse le pixel
  reglages.gd           tous les réglages de feel, modifiables à chaud (Tab)
  masse.gd              une masse, un crochet ou un sachet : même forme, trois états
  ressort/feuille/stylo/regle/loupe/verseuse/enonce
  visuel_*.gd           la couche remplaçable de chacun
  marqueurs.gd          les points d'attache, en Marker2D nommés
  encre.gd              une face de papier : une cible de rendu qui ne s'efface jamais

src/contenu/            DONNÉE. Grandeurs, primitives, lois, formes.
                        Valable pour les niveaux suivants ; ne dépend de rien.
src/simulation/         La physique d'une machine, pure et déterministe, sans aucun Node.
textures/               Déposer un PNG ici suffit à le voir apparaître.
tests/                  Runner headless, sans dépendance.
```

`src/contenu/` ne dépend de rien. `src/simulation/` ne contient que des `RefCounted` —
c'est ce qui rend la suite headless possible.

## État actuel

Le niveau 1 s'enchaîne de bout en bout : lire l'énoncé, clipser le stylo, marquer, décaler
la feuille, poser la règle, verser un sachet. Moche par endroits, mais entier.

C'est encore un prototype et il reste jetable. Il n'y a **pas** de progression, pas de
carnet, pas de niveau 2, pas de kit générique, et rien qui enregistre ce que le joueur a
produit.
