extends SceneTree

var _lance: bool = false
var _atelier: Node2D = null


func _process(_d: float) -> bool:
	if not _lance:
		_lance = true
		_jouer()
	return false


func _clic(presse: bool) -> void:
	var e: InputEventMouseButton = InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = presse
	e.position = root.get_mouse_position()
	Input.parse_input_event(e)


func _touche(code: Key) -> void:
	var e: InputEventKey = InputEventKey.new()
	e.keycode = code
	e.pressed = true
	Input.parse_input_event(e)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _glisser(de: Vector2, vers: Vector2, pas: int) -> void:
	Input.warp_mouse(de)
	await _frames(2)
	_clic(true)
	for i: int in pas:
		Input.warp_mouse(de.lerp(vers, float(i + 1) / float(pas)))
		await process_frame
	await _frames(6)
	_clic(false)
	await _frames(2)


func _photo(nom: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://%s.png" % nom)


func _masse_libre(rang: int) -> RigidBody2D:
	var libres: Array = _atelier.get("_libres")
	var triees: Array = libres.duplicate()
	triees.sort_custom(func(a: RigidBody2D, b: RigidBody2D) -> bool: return a.mass < b.mass)
	return triees[mini(rang, triees.size() - 1)]


func _accrocher(rang: int) -> void:
	var masse: RigidBody2D = _masse_libre(rang)
	var arrivee: Vector2 = _atelier.call("_point_libre") + Vector2(0.0, float(masse.get("rayon")))
	await _glisser(masse.global_position, arrivee, 16)
	await _frames(38)


func _jouer() -> void:
	_atelier = (load("res://atelier.tscn") as PackedScene).instantiate()
	root.add_child(_atelier)
	await _frames(40)
	print("etape: scene montee")

	var stylo: Node2D = _atelier.get("_stylo")
	var chaine: Array = _atelier.get("_chaine")
	var crochet: RigidBody2D = chaine[0]

	# Clipser le stylo sur le crochet, puis baisser la pointe.
	await _glisser(stylo.global_position, crochet.global_position + Vector2(26.0, 0.0), 14)
	await _frames(5)
	_touche(KEY_SPACE)
	await _frames(5)
	print("etape: stylo clipse")

	# Trois masses, en decalant la feuille entre chaque : le nuage de points.
	var feuille: Node2D = _atelier.get("_feuille")
	for rang: int in 2:
		await _accrocher(rang)
		var depart: Vector2 = feuille.global_position + Vector2(70.0, 40.0)
		await _glisser(depart, depart + Vector2(-95.0, 0.0), 10)
		await _frames(14)
		print("etape: masse ", rang)
	await _photo("f_nuage")

	# Tirer la chaine en biais et lacher : le pendule trace sa trajectoire.
	var bas: RigidBody2D = (_atelier.get("_chaine") as Array)[-1]
	await _glisser(bas.global_position, bas.global_position + Vector2(-190.0, 70.0), 14)
	await _frames(110)
	await _photo("g_pendule")

	print("captures ok")
	quit(0)
