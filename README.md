# Le Jeu de l'Ingénieur — Document de référence

Ce document est la source de vérité du design. **À lire avant toute décision d'implémentation,
et à relire en cas de doute.** Si un choix technique contredit ce document, c'est le choix
technique qui a tort — ou alors ce document doit être modifié explicitement, par moi.

---

## 1. Le jeu en une phrase

Un jeu d'instruments : on répare des machines en mesurant l'invisible avec des outils qu'on
fabrique soi-même, et les mathématiques n'y sont jamais un exercice — elles sont ce que font
les outils.

## 2. Ce que le joueur fait réellement

Devant un plan d'ingénieur bleu et blanc, une machine est cassée. On lui donne un **énoncé de
commande** (« trois sachets : 56, 89 et 143 g ») et une **caisse à outils**. Rien d'autre.

Il monte des objets sur le plan, il mesure, il trace sur du papier, il pose une règle sur ses
traces, et il produit ce qu'on lui a demandé. Il repart avec un instrument de plus.

**Le but n'est jamais « trouve la loi ». Le but est toujours un objectif physique concret que
la loi permet d'atteindre.** C'est la différence entre un jeu et un devoir, et c'est la règle
la plus importante de ce document.

## 3. La doctrine du fun

### Le fun d'abord, la rigueur ensuite

À chaque arbitrage entre réalisme physique et plaisir de manipulation, **choisir le plaisir**.
Un ressort qui s'allonge de 0,18 mm/g est réaliste et invisible. Exagérer est autorisé et
souvent souhaitable. Personne ne joue pour la fidélité d'un module d'Young.

### Le geste avant l'interface

Tout ce qui peut être un objet manipulable doit être un objet manipulable.

- Figer la règle → une punaise qu'on plante, pas une case à cocher
- Arrêter les oscillations → une butée qu'on rabat, pas un bouton
- Faire pivoter → attraper une extrémité, pas cliquer sur une icône
- Choisir une valeur → positionner un objet, pas bouger un curseur

**Un curseur invite à balayer au hasard. Un objet à placer invite à comprendre pourquoi il va
là.**

### Rien ne s'arrête net

Tout a de l'inertie, tout dépasse, tout revient, tout s'amortit. Une masse lâchée rebondit et
roule. Un ressort déchargé dépasse et se calme. Le poids se ressent au curseur : une masse
lourde accuse un retard sur le pointeur, une légère y colle.

C'est ce qui fait qu'on manipule pendant deux minutes sans objectif. Si ce plaisir-là
disparaît, plus rien ne tient.

### Le test permanent

> **Est-ce qu'on continue à jouer avec après avoir vérifié que ça marche ?**

Si on ferme la fenêtre dès que la fonctionnalité est validée, elle est ratée, quelle que soit
sa correction technique.

## 4. La doctrine pédagogique

### Rien n'est enseigné, tout est rencontré

Aucun cours, aucune définition, aucun encadré explicatif, aucun pop-up « le savais-tu »,
aucun tutoriel textuel.

Une balance qui refuse de descendre sous 100 g **est** le tutoriel du niveau 1.

### Les maths émergent de la réutilisation

Le contenu pédagogique n'est pas la loi physique, c'est la **forme mathématique** qui
réapparaît dans des contextes sans rapport. Un ressort, un fil électrique, une bouilloire et
un robinet sont quatre choses différentes et une seule forme linéaire.

Règle ferme : **une forme doit revenir au moins trois fois dans trois contextes physiquement
différents.** Deux occurrences, c'est une coïncidence. Trois, c'est une loi. Une forme vue une
seule fois est décorative et doit être coupée.

### La linéarité se vit, elle ne s'énonce pas

Le joueur ne lit jamais « y = ax + b ». Il constate que **des masses égales font des écarts
égaux** sur son papier, et il en déduit qu'il peut subdiviser pour fabriquer les graduations
manquantes. C'est la même chose, et c'est vécu.

### L'algèbre n'est jamais requise, elle est plus rapide

C'est le seul mécanisme d'apprentissage qui ne se sent pas. Chaque niveau tardif doit rester
résoluble à la règle et au compas — mais laborieusement. Écrire une expression prend deux
minutes au lieu de vingt.

**Le joueur bascule dans l'abstraction parce qu'il en a marre, jamais parce qu'on l'y force.**

### L'objet arrive avant le symbole

Ne jamais faire apparaître un éditeur d'équations nu. Faire apparaître un **instrument qui
contient de l'algèbre** : une règle à calcul, un abaque, un jeu de cames profilées. On
manipule une réglette, elle multiplie. On comprend le logarithme par le geste bien avant de
voir le mot.

## 5. La boucle de jeu

```
énoncé de commande
   ↓
inventaire du kit : qu'est-ce que j'ai ?
   ↓
monter des objets sur le plan
   ↓
mesurer — tracer — poser la règle
   ↓
produire ce qui est demandé
   ↓
un instrument de plus dans le kit
```

Le verdict n'est jamais un tableau de pourcentages. **C'est ce que le joueur a effectivement
produit** : trois sachets sur la table, pesés pour de vrai.

## 6. Le kit

Chaque niveau fournit une caisse à outils. Le joueur sait que la solution s'y trouve, il ne
sait pas comment.

C'est ce qui résout le problème de la page blanche : un établi vide est paralysant, quatre
objets sont une contrainte lisible.

**Toujours inclure un ou deux objets inutiles**, hérités des niveaux précédents. Si tous les
objets servent exactement une fois, le joueur comprend qu'il suffit de tout utiliser et le
puzzle disparaît. L'incertitude sur l'utilité est ce qui fait qu'on réfléchit.

Les objets sont des **modules** avec des points d'attache, qui se clipsent entre eux : le
stylo sur le crochet, la sonnette sur la butée, le stylo sur une masse.

## 7. Le carnet

**Le carnet ne contient rien que le joueur n'ait produit lui-même.**

C'est un classeur où l'on range ses feuilles tracées. Elles restent consultables et surtout
**réutilisables** : on ressort la feuille du niveau 1 au niveau 5 et on pose sa règle dessus.

Un joueur qui range bien s'y retrouve, un joueur qui range mal galère et apprend à annoter.

Le carnet n'apparaît **pas** au niveau 1. Il arrive quand le joueur a sa deuxième feuille et ne
sait pas quoi en faire. Tant qu'il n'a pas envie de garder ses traces, ne pas lui donner de
classeur.

Extension naturelle à prévoir plus tard : un calque translucide qu'on superpose à une ancienne
feuille pour comparer deux courbes. Un outil de comparaison qui est physiquement une feuille
sur une feuille.

## 8. Progression

Ce ne sont pas des chapitres de mathématiques. C'est **de l'outillage qui s'améliore**. Chaque
niveau donne l'instrument qui rend le suivant possible.

| # | Machine | Forme | Ce qu'on gagne |
|---|---|---|---|
| 1 | Le peson | linéaire | une balance à ±5 g |
| 2 | L'horloge | racine | un chronomètre fiable |
| 3 | La bouilloire | linéaire | l'enregistreur à papier défilant |
| 4 | Le four | linéaire | un thermomètre |
| 5 | La cuve enterrée | composition | une jauge de pression |
| 6 | Le colorimètre | linéaire + bruit | la mesure optique |
| 7 | Le doseur chaud | paramétrique | le mode expression |
| 8 | La ligne électrique | quadratique caché | un manque identifié |

**Niveau 1 — Le peson.** Trois sachets à 56, 89 et 143 g. La balance a un pas de 100 g. On
clipse le stylo au crochet, on marque le 50, le 100, le 200. On pose la règle : les traits sont
alignés et régulièrement espacés. On subdivise au compas pour fabriquer les graduations
manquantes. Le livrable est un cadran gradué à la main. Zéro chiffre tapé, zéro formule.

*Le piège : le crochet a une masse. Le zéro n'est pas là où on croit.*

**Niveau 2 — L'horloge.** Il faut mesurer une durée, on n'a rien. Clepsydre d'abord (linéaire,
grossier, dérive). Puis le pendule — et là, quadrupler la longueur double la période. Les
écarts ne sont plus égaux. La forme `RACINE` entre par contraste avec le linéaire maîtrisé.

*Le chrono touche 15 couplages sur 36. Il ne doit pas être donné, il doit être construit.*

**Niveau 3 — La bouilloire.** Elle évapore tout. Avec le chrono, on relie masse d'eau et temps
de chauffe. Le papier se monte sur une manivelle puis sur un mécanisme d'horlogerie : il défile
seul, le stylo trace une **courbe continue en fonction du temps**. La droite ne part pas de
zéro, la cuve met du temps à chauffer — le même terme constant qu'au niveau 1, ailleurs.

**Niveau 4 — Le four.** La charge change à chaque fournée, le temporisé ne suffit plus. Un
bilame, deux points de calibration (glace, eau bouillante), et une règle graduée à la main
devient un thermomètre. On spécifie l'hystérésis du contact : trop serrée il claque, trop large
la température oscille de 40 degrés. Premier vrai arbitrage d'ingénieur.

**Niveau 5 — La cuve enterrée.** Opaque, un seul tube. Un piston sur un ressort au fond. Deux
relations linéaires bout à bout **en redonnent une seule**, de pente le produit des deux.
Premier théorème du jeu, et il justifie rétroactivement tout : n'importe quoi devient mesurable
par chaîne.

**Niveau 6 — Le colorimètre.** On fabrique ses propres étalons par dilutions. Cinq points cette
fois, et **ils ne sont pas alignés**. Première rencontre avec le bruit : on pose la règle au
milieu, pas sur les points. Deux points suffisent quand on fait confiance à la loi ; cinq, c'est
quand on vérifie qu'elle s'applique.

**Niveau 7 — Le doseur chaud.** Le liquide chaud se dilate, donc le coefficient de dosage n'est
plus une constante. Impossible de graduer une règle une fois pour toutes. **C'est ici que le
mode expression s'ouvre**, et parce qu'on en a besoin.

**Niveau 8 — La ligne électrique.** Le four du fond chauffe deux fois trop lentement, le câble
fait 40 m. Aucun ampèremètre : on mesure le courant par la chaleur, donc on ressort la
calorimétrie du 3 et le peson du 1 pour instrumenter un circuit. On cherche une droite et on
n'en trouve pas — il y a un quadratique caché dans la chaîne de linéaires.

*Fin du chapitre : pas une victoire, un manque identifié. C'est l'ouverture du chapitre 2.*

## 9. Anti-patterns — ce qui tue le jeu

À relire à chaque fois qu'une fonctionnalité paraît « propre » mais ennuyeuse.

- **Le formulaire déguisé.** Des champs à remplir avec un joli thème restent un formulaire.
- **Le chocolat sur les brocolis.** Résoudre une équation pour gagner le droit de jouer. Le
  joueur voit le péage immédiatement.
- **Le jeu qui mesure à la place du joueur.** Des points qui apparaissent seuls sur un graphe,
  une valeur affichée en surimpression, une longueur calculée automatiquement. Le relevé *est*
  le métier.
- **Le verdict binaire.** Jamais « faux ». Un écart, une courbe prédite superposée à la courbe
  réelle, et le joueur voit *où* ça décroche.
- **La physique décorative.** Une physique qui ne change pas ce qu'on doit faire est un habillage.
- **Le brute-force possible.** Si une réponse est un nombre dans un champ, on la trouve en
  balayant. La réponse doit être une action, un objet monté, ou une spécification testée sur des
  cas inconnus.
- **La forme vue une seule fois.** Sans trois contextes, aucun transfert.
- **Le mur au changement de palier.** Ne jamais introduire une loi *et* demander de l'inverser
  dans la même énigme. Une nouveauté à la fois.
- **Le chemin unique.** Toute grandeur à déterminer doit être atteignable par au moins deux
  chemins, sinon un joueur bloqué n'a aucune prise.

## 10. Heuristiques de décision

En cas de doute pendant l'implémentation, dans cet ordre :

1. Est-ce que ça se manipule au lieu de se saisir ?
2. Est-ce que le joueur produit la mesure, ou est-ce que le jeu la lui donne ?
3. Est-ce que l'objectif est physique et concret, ou est-ce « trouve la relation » ?
4. Est-ce qu'on aurait envie d'y jouer sans objectif pendant deux minutes ?
5. Est-ce qu'un joueur qui déteste les maths comprendrait quoi faire ?

Si une réponse est non, la fonctionnalité est à revoir même si elle marche.

## 11. Contraintes techniques permanentes

- Godot 4.4, GDScript, typage statique
- **Zéro asset** : tout est dessiné en `_draw`. L'esthétique blueprint est faite de lignes.
- Toutes les constantes de thème et de feel dans **un seul fichier**, réglables à chaud
- La simulation reste pure, déterministe, testable en headless, sans dépendance à l'affichage
- Le contenu est de la donnée, jamais du code : ajouter un niveau ne doit pas modifier le moteur
- **Aucun chiffre affiché par le jeu.** Les seuls chiffres à l'écran sont ceux gravés sur les
  instruments, et c'est au joueur de les lire.

## 12. Hors périmètre pour l'instant

Pas de menu, pas de sauvegarde, pas de son, pas de localisation, pas de textures. La boucle
n'est pas encore prouvée amusante ; tout le reste est prématuré.
