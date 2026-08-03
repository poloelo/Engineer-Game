# Le visuel de l'etabli et de la potence : la COUCHE VISIBLE. Les murs et le sol
# de collision sont dans atelier.gd et ne dependent pas de ce fichier.
#
# `textures/etabli.png` remplace le trait procedural par un panneau tendu sur le
# monde entier.
extends Node2D

const Unites: GDScript = preload("res://unites.gd")
const Textures: GDScript = preload("res://textures.gd")

const TRAIT: Color = Color("e6f0f8")
const TRAIT_EFFACE: Color = Color(0.90, 0.94, 0.97, 0.45)
const TRAIT_TRES_EFFACE: Color = Color(0.90, 0.94, 0.97, 0.18)

## Position de l'ancrage de la potence, en mm. Fixee par l'atelier.
var ancre: Vector2 = Vector2.ZERO
## Hauteur du plan de travail, en mm.
var sol: float = 0.0

var _panneau: TextureRect = null


func _ready() -> void:
	var texture: Texture2D = Textures.charger("etabli")
	if texture == null:
		return
	_panneau = TextureRect.new()
	_panneau.texture = texture
	_panneau.size = Unites.MONDE
	_panneau.stretch_mode = TextureRect.STRETCH_SCALE
	_panneau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panneau)


func _draw() -> void:
	if _panneau != null:
		return
	_dessiner_etabli()
	_dessiner_potence()


func _dessiner_etabli() -> void:
	draw_line(Vector2(0.0, sol), Vector2(Unites.MONDE.x, sol), TRAIT, 1.0)
	# Les hachures du plan de travail, tous les 20 mm.
	for i: int in 32:
		var x: float = float(i) * 20.0
		draw_line(Vector2(x, sol), Vector2(x - 7.0, sol + 8.0), TRAIT_TRES_EFFACE, 0.5)


func _dessiner_potence() -> void:
	draw_line(ancre + Vector2(-45.0, -13.0), ancre + Vector2(30.0, -13.0), TRAIT, 1.5)
	draw_line(ancre + Vector2(0.0, -13.0), ancre, TRAIT, 1.0)
	for i: int in 10:
		var x: float = ancre.x - 43.0 + float(i) * 7.5
		draw_line(Vector2(x, ancre.y - 13.0), Vector2(x - 5.0, ancre.y - 19.0), TRAIT_EFFACE, 0.5)
