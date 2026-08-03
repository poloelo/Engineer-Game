# textures/

Dépose un PNG ici et il apparaît. Aucun refactor, aucune ligne de code à écrire.

Chaque objet du prototype est coupé en deux couches :

* **la forme** — collision, masse, points d'attache, logique. Elle ne change jamais.
* **le visuel** — un nœud enfant remplaçable, qui prend la texture si elle existe et
  retombe sur le dessin procédural sinon.

Le fichier est cherché par nom au démarrage. S'il n'est pas là, l'objet se dessine comme
avant ; il n'y a pas d'erreur, pas d'avertissement, rien à configurer.

> Godot n'importe un PNG qu'au premier passage par l'éditeur. Après avoir déposé un
> fichier, ouvre le projet une fois dans l'éditeur (ou lance `godot --headless --import`)
> pour qu'il devienne visible au jeu.

## Noms attendus

| Fichier | Objet | Cadrage |
|---|---|---|
| `masse_1g.png`, `masse_2g.png`, `masse_5g.png`, `masse_10g.png`, `masse_20g.png` | un poids précis | carré, tendu sur le diamètre de collision |
| `masse.png` | tous les poids sans fichier dédié | carré |
| `crochet.png` | le crochet | carré, tendu sur son diamètre |
| `ressort.png` | le ressort | **une spire**, dessinée horizontalement — voir plus bas |
| `regle.png` | la règle | **9-patch**, voir plus bas |
| `feuille.png` | le papier | **9-patch** |
| `stylo.png` | le stylo | vertical, pointe en bas, tendu sur la longueur |
| `loupe.png` | la monture et le manche | carré, centré sur le verre, fond transparent |
| `etabli.png` | le plan de travail | 16/9, tendu sur les 640 × 360 mm du monde |

Le nom le plus précis gagne : `masse_50g.png` habille la masse de 50 g, `masse.png`
habille toutes les autres.

## Les deux cas particuliers

**Le ressort** est un `Line2D` en mode répétition. `ressort.png` doit contenir **une
spire dessinée à l'horizontale** : la hauteur de l'image devient le diamètre du ressort,
la largeur devient le pas d'une spire, et la tuile se répète le long du fil. Fond
transparent. Compromis assumé : un ressort qui s'allonge gagne des tours plutôt que
d'écarter les siens — c'est le comportement natif de `Line2D`, et l'autre option (étirer
une tuile unique) rend une spire déformée et floue.

**La règle et la feuille** sont des `NinePatchRect`. Les bords ne se déforment pas quand
l'objet change de taille : seul le centre s'étire (feuille) ou se répète (règle). Les
marges de découpe sont fixées dans le code — 16 px pour la règle, 24 px pour la feuille —
donc prévois une bordure d'au moins cette largeur dans l'image.

Pour la règle, le centre est en mode **répétition** et non étirement : une graduation
étirée mentirait sur la longueur qu'elle mesure, et c'est précisément ce que ce
prototype cherche à ne plus faire. Dessine donc le motif d'un centimètre gradué, et il
se répétera sur les 200 mm.

## Échelle

Le monde est en millimètres. Les tailles physiques utiles :

| Objet | Taille réelle |
|---|---|
| règle | 200 × 22 mm |
| feuille | 330 × 235 mm |
| crochet | 16 mm de diamètre |
| masses | de 18 mm (1 g) à 35 mm (20 g) de diamètre |
| stylo | 29 mm de long |
| loupe | 78 mm de diamètre |
| ressort | 18 mm de diamètre, 48 mm au repos |

L'affichage est à 2 px/mm à la résolution de référence. Une texture à 4 px/mm est donc
confortable, et la loupe (× 3,2) rend justice à une texture à 8 px/mm.
