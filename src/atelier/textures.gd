# Chargement des textures optionnelles, par convention de nommage.
#
# Le principe : chaque objet est coupe en deux couches. La forme (collision,
# masse, points d'attache) ne change jamais ; le visuel est un noeud enfant
# remplacable, qui accepte une texture et retombe sur le dessin procedural si
# elle n'existe pas. Deposer un PNG dans textures/ suffit donc a le voir
# apparaitre, sans toucher a une ligne de code.
#
# Nommage — voir textures/LISEZMOI.md :
#   masse_50g.png   la masse de 50 g precisement
#   masse.png       toutes les masses qui n'ont pas leur fichier propre
#   crochet.png     le crochet
#   ressort.png     tuile verticale, repetee le long du Line2D
#   regle.png       9-patch, graduations tuilees horizontalement
#   feuille.png     9-patch
#   stylo.png  loupe.png  etabli.png
extends RefCounted

const DOSSIER: String = "res://textures/"


## La texture nommee, ou null si le fichier n'a pas ete depose.
static func charger(nom: String) -> Texture2D:
	var chemin: String = DOSSIER + nom + ".png"
	if not ResourceLoader.exists(chemin):
		return null
	return ResourceLoader.load(chemin) as Texture2D


## La premiere texture disponible de la liste : du plus specifique au plus
## general. `premiere(["masse_50g", "masse"])` prend le fichier dedie s'il
## existe, sinon la texture generique, sinon null et l'objet se dessine.
static func premiere(noms: Array[String]) -> Texture2D:
	for nom: String in noms:
		var texture: Texture2D = charger(nom)
		if texture != null:
			return texture
	return null
