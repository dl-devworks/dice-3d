extends Node


const FACE_DIR := "res://addons/dice_3d/demo/assets/faces/"
const NUMBER_BODY_MATERIAL := "res://addons/dice_3d/assets/materials/painted_plaster_number_die.tres"
const ICON_BODY_MATERIAL := "res://addons/dice_3d/assets/materials/rust_coarse_die.tres"


static func make_number_d6() -> DiceDieDefinition3D:
	var definition := DiceDieDefinition3D.custom("NumberDie", [
		DiceFace3D.new_face(1, &"one", load(FACE_DIR + "number_1.svg"), "One"),
		DiceFace3D.new_face(6, &"six", load(FACE_DIR + "number_6.svg"), "Six"),
		DiceFace3D.new_face(2, &"two", load(FACE_DIR + "number_2.svg"), "Two"),
		DiceFace3D.new_face(5, &"five", load(FACE_DIR + "number_5.svg"), "Five"),
		DiceFace3D.new_face(3, &"three", load(FACE_DIR + "number_3.svg"), "Three"),
		DiceFace3D.new_face(4, &"four", load(FACE_DIR + "number_4.svg"), "Four"),
	])
	definition.edge_length = 0.85
	definition.body_shape = DiceDie3D.BodyShape.ROUNDED
	definition.body_material = load(NUMBER_BODY_MATERIAL) as Material
	definition.face_decoration_scale = 0.72
	return definition


static func make_icon_d6() -> DiceDieDefinition3D:
	var definition := DiceDieDefinition3D.custom("SymbolDie", [
		DiceFace3D.new_face(1, &"attack", load(FACE_DIR + "symbol_attack.svg"), "Attack"),
		DiceFace3D.new_face(6, &"blank", load(FACE_DIR + "symbol_blank.svg"), "Blank"),
		DiceFace3D.new_face(2, &"shield", load(FACE_DIR + "symbol_shield.svg"), "Shield"),
		DiceFace3D.new_face(5, &"star", load(FACE_DIR + "symbol_star.svg"), "Star"),
		DiceFace3D.new_face(3, &"heal", load(FACE_DIR + "symbol_heal.svg"), "Heal"),
		DiceFace3D.new_face(4, &"coin", load(FACE_DIR + "symbol_coin.svg"), "Coin"),
	])
	definition.edge_length = 0.85
	definition.body_shape = DiceDie3D.BodyShape.ROUNDED
	definition.body_material = load(ICON_BODY_MATERIAL) as Material
	definition.face_decoration_scale = 0.76
	return definition


static func make_number_d20() -> DiceDieDefinition3D:
	var definition := DiceDieDefinition3D.numbered_d20()
	definition.edge_length = 1.05
	definition.body_material = load(NUMBER_BODY_MATERIAL) as Material
	definition.face_decoration_scale = 0.52
	return definition


static func make_all() -> Array[DiceDieDefinition3D]:
	return [
		make_number_d6(),
		make_icon_d6(),
		make_number_d20(),
	]


static func apply_to_panel(panel: DiceCinematicRollPanel) -> void:
	panel.normal_die_definition = make_number_d6()
	panel.icon_die_definition = make_icon_d6()
	panel.d20_die_definition = make_number_d20()
	panel.normal_dice_count = 1
	panel.icon_dice_count = 1
	panel.d20_dice_count = 1


static func apply_to_roller(roller: DiceCinematicRoller3D) -> void:
	roller.dice_definitions = make_all()
