# Le Jeu de l'Ingénieur

Le joueur est un ingénieur devant un plan technique. Une machine est cassée. Il observe le
symptôme, identifie une grandeur invisible, trouve un proxy mesurable relié par une loi
physique, mesure, inverse la relation, et **spécifie une pièce** en remplissant une fiche
technique. Le banc d'essai simule la machine avec sa pièce et lui montre le résultat.

Aucun QCM, aucune note, aucun texte pédagogique. L'échec n'affiche jamais « faux » : il
affiche un **écart** et une **courbe prédite superposée à la courbe réelle**.

Godot 4.4 · GDScript typé · aucun asset externe, tout est dessiné dans `_draw`.

---

## Lancer

```sh
godot --path . # ou ouvrir le projet dans l'éditeur
```

La scène principale est `src/presentation/machines/peson/peson.tscn`.

## Tester

```sh
tests/run.sh                       # utilise le binaire `godot` du PATH
GODOT=/chemin/vers/godot tests/run.sh
```

Le runner est headless, sans dépendance externe, et rend un code de sortie non nul en cas
d'échec — utilisable tel quel en intégration continue.

```
OK — 40 tests, 189 verifications, 0 echec
```

---

## Le principe d'architecture

**Le contenu est de la donnée, jamais du code.** Ajouter une machine consiste à écrire un
fichier de ressource, sans toucher au moteur.

```
CONTENU  (ressources .tres : machines, lois, grandeurs)
   ↓  lu par
SIMULATION  (pure, déterministe, aucune dépendance à l'affichage)
   ↓  observée par
PRÉSENTATION  (scènes, dessin, UI)
```

Les dépendances ne vont que dans un sens. `src/contenu/` ne dépend de rien.
`src/simulation/` ne contient que des `RefCounted`, aucun `Node` — c'est ce qui rend la
suite headless possible et c'est le critère qui valide toute l'architecture.

La présentation **appelle** les méthodes de la simulation ; la simulation ne répond que par
**signaux** et ne connaît aucun nœud.

---

## Arborescence

```
project.godot                          scène principale, typage statique imposé par les warnings

src/contenu/                           COUCHE CONTENU — schémas de ressources, aucune logique de jeu
  forme.gd                             les 7 formes mathématiques transverses (LINEAIRE, RACINE…)
  grandeur.gd                          une grandeur physique : id, nom, symbole, unité
  primitive.gd                         une des 8 primitives, et sa résolution
  loi.gd                               un couplage orienté entre grandeurs — le cœur, voir plus bas
  evaluateur_expression.gd             rend exécutable une formule écrite dans un .tres
  emplacement_piece.gd                 la fiche technique à remplir : gabarit, champs, axes, récompense
  cas_test.gd                          un cas caché sur lequel le banc éprouve la pièce
  machine_def.gd                       une machine : symptôme, loi cachée, emplacements, cas cachés
  catalogue.gd                         accès par identifiant au contenu posé sur le disque

  data/grandeurs/    14 fichiers       les 14 grandeurs de l'annexe B
  data/primitives/    8 fichiers       les 8 primitives de l'annexe A
  data/lois/          2 fichiers       hooke, peson_ressort
  data/machines/      1 fichier        peson

src/simulation/                        COUCHE SIMULATION — RefCounted uniquement, testable headless
  specification.gd                     le modèle paramétré que le joueur soumet
  generateur_mesure.gd                 traduit une valeur vraie en ce que l'instrument affiche
  resultat_banc.gd                     écart, paliers d'étoiles, deux séries de points
  piece.gd                             une spécification validée, devenue instrument
  simulation_machine.gd                le moteur d'une machine : relevés, banc, courbes

src/presentation/                      COUCHE PRÉSENTATION
  theme/constantes_theme.gd            LE SEUL fichier de couleurs, tailles et épaisseurs
  composants/graphe/                   le graphe : relevés, modèle en surimpression, machine réelle
  composants/fiche_technique/          des champs numériques vides, jamais un curseur
  composants/banc_essai/               l'écart cas par cas, les étoiles dessinées au trait
  composants/barre_primitives/         valeurs de référence et résolution des instruments
  ecran_machine/ecran_machine.gd       l'écran de jeu, valable pour TOUTE machine
  machines/peson/                      plan dessiné du peson + assemblage de la scène

tests/
  run.sh, run_tests.gd                 runner headless, découverte automatique des suites
  support/test_base.gd                 socle d'assertions
  test_loi.gd                          évaluation et inversion depuis la donnée
  test_simulation_machine_peson.gd     le parcours complet du joueur, sans ouvrir une scène
  test_graphe.gd                       géométrie du graphe : graduations, cadrage, découpe
  test_ecran_machine.gd                câblage complet, du bouton au verdict
```

---

## Le modèle de données

### Loi

Une loi porte à la fois sa physique et sa **forme mathématique**, qui est transverse : Hooke,
Ohm et le débit constant sont trois lois sans rapport qui partagent la forme `LINEAIRE`.
C'est le contenu pédagogique du jeu, donc un champ de premier ordre.

Les formules sont du **texte**, évalué par la classe `Expression` du moteur. Les variables
disponibles sont les identifiants des grandeurs couplées, plus les paramètres.

```gdscript
id = &"hooke"
nom_physique = "Hooke"
forme = 0                                   # LINEAIRE
grandeurs_entree = [&"force"]               # toujours un tableau, même à un élément
grandeurs_sortie = [&"longueur"]
parametres = ["l0", "k"]
parametres_defaut = { "l0": 60.0, "k": 0.5 }
expression = "l0 + force / k"
expression_inverse = "(longueur - l0) * k"
invertibilite = 0                           # INVERSIBLE | PARTIELLE | NON_INVERSIBLE
outils_requis = [&"voir"]
```

**L'inverse est une seconde formule déclarée, pas une inversion symbolique calculée.** Il n'y
a que trente-six lois, écrites une fois par un humain qui connaît l'algèbre : un moteur de
calcul formel serait un projet à lui seul pour zéro gain. Les cas non inversibles (le volume
de la boîte : il faut chercher un maximum) portent `NON_INVERSIBLE` et une formule inverse
vide — la résolution est alors un algorithme, pas une formule retournée.

`Loi.verifier()` rend la liste des problèmes structurels en langage clair : formule illisible,
loi déclarée inversible sans inverse, aucun outil requis.

### EmplacementPiece

Le point d'extension central. Il déclare ce que le joueur doit spécifier, et la récompense.

```gdscript
gabarit = "a * lecture + b"                 # le modèle qu'il paramètre
parametres = ["a", "b"]                     # un champ numérique vide par nom
entrees_gabarit = [&"lecture"]              # ce que le banc fournit au gabarit
grandeur_lue = &"longueur"                  # axe des abscisses du graphe
grandeur_produite = &"masse"                # axe des ordonnées, et valeur comparée à la vérité
primitive_amelioree = &"peser"              # la récompense : un instrument plus fin
pas_ameliore = 5.0                          # de 100 g à 5 g
```

### MachineDef

```gdscript
symptome                                    # constaté, jamais expliqué
loi_cachee                                  # la physique réelle, invisible du joueur
parametres_caches                           # surcharge les constantes de la loi
emplacements                                # les pièces à spécifier
cas_test_caches                             # l'épreuve finale, jamais montrée avant
etalons                                     # les valeurs de référence que le joueur peut imposer
primitive_lue / primitive_produite          # ses instruments (null = valeur connue exactement)
matiere_initiale                            # budget de soumissions
```

Le **sens de la loi n'est pas codé en dur** : que la grandeur lue soit l'entrée ou la sortie
de la loi cachée, l'état caché se complète tout seul par évaluation ou par inversion. C'est
ce qui permet au peson (masse → longueur, on lit la sortie) et à une bouilloire
(volume → temps, on lit l'entrée) d'utiliser le même moteur.

---

## La validation

Le joueur ne soumet **jamais un nombre-réponse**. Il soumet une spécification paramétrée,
évaluée sur des cas cachés qu'il n'a jamais vus. Le brute-force est donc mécaniquement
impossible, sans avoir besoin de l'interdire.

Le résultat n'est pas binaire mais un écart relatif, avec des paliers sur le **pire** cas :

| écart maximal | étoiles |
|---|---|
| ≤ 20 % | 1 — ça passe, on avance |
| ≤ 5 % | 2 |
| ≤ 1 % | 3 |

Une pièce à une étoile entre à l'atelier : on peut progresser avec un modèle médiocre et
revenir plus tard. Chaque soumission consomme de la matière (12 au départ) : assez pour que
le tâtonnement reste légitime, pas assez pour balayer au hasard.

Le banc n'applique **aucune** imprécision d'instrument : il simule la machine équipée de la
pièce. Ce que le joueur combat, c'est la grossièreté de ses propres mesures pendant la
calibration, pas un banc capricieux.

---

## La machine 1 : le peson

La balance de l'atelier a un pas de 100 g, inutilisable. Le joueur dispose d'un ressort,
d'une règle graduée au millimètre et de masses étalons.

Physique cachée : longueur à vide 60 mm, sensibilité 0,18 mm/g, **crochet 8 g**. Le crochet
décale la droite : la relation n'est pas proportionnelle mais affine. C'est le piège.

Solution attendue : `masse = 5,556 × lecture − 341,3`, éprouvée sur trois masses cachées.
Récompense : la primitive « peser » passe de ±100 g à ±5 g.

Un joueur qui suppose la proportionnalité (`b = 0`) obtient 136 % d'écart et voit sa courbe
décrocher visiblement de la machine réelle. Rien n'affiche « faux ».

> **Note de conception.** Le jeu d'étalons est `5, 10, 25, 50, 100, 200, 500 g` et non des
> valeurs rondes uniquement. À 0,18 mm/g, toutes les masses rondes au-delà de 50 g tombent sur
> la même erreur d'arrondi au millimètre, ce qui rendait la pente **juste par accident** quel
> que soit le soin du joueur. Les petites valeurs rétablissent l'enjeu : calibrer sur un bras
> de levier court donne une étoile, sur le bras le plus long en donne trois.

---

## Ajouter une machine

C'est le critère qui valide l'architecture. Une machine nouvelle demande :

1. un `.tres` de `Loi` si elle introduit une physique inédite ;
2. un `.tres` de `MachineDef` avec son emplacement de pièce et ses cas cachés ;
3. une scène de deux références — `EcranMachine` avec `definition` et, si on veut un dessin,
   `plan`.

**Aucun fichier de `src/simulation/` ne bouge.** `EcranMachine` est générique : il ne connaît
aucune machine en particulier. Le plan dessiné est optionnel ; une machine sans plan reste
jouable, le graphe suffit.

Les fichiers de données s'éditent dans l'inspecteur Godot. Attention si tu en écris un à la
main : la notation des tableaux typés de ressources n'est pas devinable
(`Array[ExtResource("2_xxx")]([SubResource("...")])`) — passer par l'inspecteur ou par
`ResourceSaver` évite bien des surprises.

---

## État actuel

Fait — le socle complet et la machine 1, jouable de bout en bout, 40 tests headless.

Reste à faire :

- **`Progression`** (pièces obtenues, résolutions courantes, budget, carnet), volontairement
  limité à ces quatre responsabilités.
- **Le carnet** : lois rencontrées et formes mathématiques, signalées à la troisième
  apparition dans un contexte physique différent — jamais avant trois.
- **La commande de diagnostic** du graphe des lois : vérifier que toute grandeur cible est
  atteignable par au moins deux chemins distincts, en remontant jusqu'aux primitives brutes.
- **La machine 2** (bouilloire, calorimétrie, même forme linéaire), qui est le test
  d'acceptance du socle.

### Défaut structurel connu

`Primitive.pas` est un scalaire unique, et c'est faux. « Éclairer / voir » mesure une longueur
*et* un volume — deux unités, donc deux résolutions. Un seul `pas` ne peut pas servir les
deux. Le correctif est `pas_par_grandeur: Dictionary` et un `GenerateurMesure.mesurer()` qui
prend la grandeur mesurée ; il touche les huit `.tres` de primitives et deux fichiers de
simulation. La machine 2 bute dessus — à corriger avant de l'écrire.

### Questions ouvertes

- L'annexe C liste `instrument` comme prérequis de six lois, mais `instrument` n'est pas une
  des huit primitives : c'est une pièce fabriquée. D'où le champ `outils_requis` plutôt que
  `primitives_requises`. Reste à trancher : un seul outil générique, ou plusieurs distincts
  (voltmètre, manomètre) ?
- Les lois `PARTIELLE` (systèmes à plusieurs inconnues) et les lois qui **changent de forme
  selon la variable observée** (Beer-Lambert, linéaire en concentration et exponentielle en
  épaisseur) ont leurs champs prévus mais pas de mécanique conçue. Volontairement reporté à
  la première machine concrète de chaque type, plutôt que deviné à l'avance.
