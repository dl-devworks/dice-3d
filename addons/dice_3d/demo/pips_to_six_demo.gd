extends Node3D


class UpgradeDragButton:
	extends Button

	var upgrade_data: Dictionary = {}

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if disabled or upgrade_data.is_empty():
			return null

		var preview := PanelContainer.new()
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 6)
		var label := Label.new()
		label.text = "%s  $%d" % [upgrade_data["title"], upgrade_data["cost"]]
		margin.add_child(label)
		preview.add_child(margin)
		set_drag_preview(preview)

		return {
			"kind": "pip_shift_upgrade",
			"upgrade": upgrade_data,
		}


class FaceDropButton:
	extends Button

	signal upgrade_dropped(face_index: int, upgrade: Dictionary)

	var face_index := 0

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		if not (data is Dictionary):
			return false
		var drag_data := data as Dictionary
		return String(drag_data.get("kind", "")) == "pip_shift_upgrade"

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		var drag_data := data as Dictionary
		upgrade_dropped.emit(face_index, drag_data.get("upgrade", {}))


const DIE_COUNT := 5
const STARTING_MONEY := 0
const ROLL_INCOME_BASE := 5
const WIN_VALUE := 6
const _PIP_OUTER := 0.38
const _PIP_INNER := 0.14
const _PIP_RADIUS := 0.055
const _PIP_SEGMENTS := 18

const _SHOP_UPGRADES := [
	{
		"id": "raise_1",
		"title": "+1 Pip",
		"body": "Add 1 to a face.",
		"cost": 5,
		"delta": 1,
	},
	{
		"id": "raise_2",
		"title": "+2 Pips",
		"body": "Add 2 to a face.",
		"cost": 9,
		"delta": 2,
	},
	{
		"id": "make_6",
		"title": "Make Six",
		"body": "Set one face to 6.",
		"cost": 16,
		"set_value": 6,
	},
]

const _DIE_COLORS := [
	Color(0.96, 0.92, 0.76, 1.0),
	Color(0.74, 0.88, 0.95, 1.0),
	Color(0.95, 0.74, 0.72, 1.0),
	Color(0.77, 0.91, 0.75, 1.0),
	Color(0.86, 0.78, 0.95, 1.0),
]

const _ROLL_SHAKE_SOUNDS := [
	preload("res://addons/dice_3d/demo/assets/audio/dice-shake-1.ogg"),
	preload("res://addons/dice_3d/demo/assets/audio/dice-shake-2.ogg"),
	preload("res://addons/dice_3d/demo/assets/audio/dice-shake-3.ogg"),
]

const _UI_SOUNDS := [
	preload("res://addons/dice_3d/demo/assets/audio/dice-grab-1.ogg"),
	preload("res://addons/dice_3d/demo/assets/audio/dice-grab-2.ogg"),
]

@onready var _roller: DiceCinematicRoller3D = $DiceCinematicRoller3D
@onready var _money_panel: PanelContainer = $CanvasLayer/AppRoot/MoneyPanel
@onready var _money_label: Label = $CanvasLayer/AppRoot/MoneyPanel/MarginContainer/VBoxContainer/MoneyLabel
@onready var _status_label: Label = $CanvasLayer/AppRoot/MoneyPanel/MarginContainer/VBoxContainer/StatusLabel
@onready var _shop_panel: PanelContainer = $CanvasLayer/AppRoot/ScorePanel
@onready var _shop_status_label: Label = $CanvasLayer/AppRoot/ScorePanel/MarginContainer/VBoxContainer/TotalLabel
@onready var _shop_list: VBoxContainer = $CanvasLayer/AppRoot/ScorePanel/MarginContainer/VBoxContainer/MarginContainer/ScoreList
@onready var _play_panel: PanelContainer = $CanvasLayer/AppRoot/PlayPanel
@onready var _round_label: Label = $CanvasLayer/AppRoot/PlayPanel/MarginContainer/HBoxContainer/ActionColumn/RoundLabel
@onready var _roll_button: Button = $CanvasLayer/AppRoot/PlayPanel/MarginContainer/HBoxContainer/RollButton
@onready var _dice_button_row: HBoxContainer = $CanvasLayer/AppRoot/PlayPanel/MarginContainer/HBoxContainer/DiceColumn/DiceButtonRow
@onready var _upgrade_panel: PanelContainer = $CanvasLayer/AppRoot/UpgradePanel
@onready var _upgrade_exit_button: Button = $CanvasLayer/AppRoot/UpgradePanel/MarginContainer/VBoxContainer/HeaderRow/UpgradeExitButton
@onready var _upgrade_title_label: Label = $CanvasLayer/AppRoot/UpgradePanel/MarginContainer/VBoxContainer/HeaderRow/UpgradeTitleLabel
@onready var _selected_die_label: Label = $CanvasLayer/AppRoot/UpgradePanel/MarginContainer/VBoxContainer/SelectedDieLabel
@onready var _face_grid: GridContainer = $CanvasLayer/AppRoot/UpgradePanel/MarginContainer/VBoxContainer/FaceGrid

@export var fullscreen_on_ready := true
@export_range(-48.0, 6.0, 0.5) var sfx_volume_db := -6.0

var _definitions: Array[DiceDieDefinition3D] = []
var _dice: Array[DiceDie3D] = []
var _current_values: Array[int] = []
var _die_buttons: Array[Button] = []
var _shop_buttons: Array[UpgradeDragButton] = []
var _face_buttons: Array[FaceDropButton] = []
var _pip_material: StandardMaterial3D
var _money := STARTING_MONEY
var _displayed_money := STARTING_MONEY
var _money_tween: Tween
var _roll_count := 0
var _last_income := 0
var _selected_die_index := -1
var _rolling := false
var _game_complete := false
var _status_text := "Roll to earn money."
var _roll_audio_player: AudioStreamPlayer
var _ui_audio_player: AudioStreamPlayer
var _active_roll_shake: AudioStream


func _ready() -> void:
	randomize()
	_setup_audio()
	_apply_fullscreen_mode()
	_setup_sky()
	_style_ui()
	_build_shop_buttons()
	_build_die_buttons()
	_build_face_buttons()
	_create_dice_from_definitions()
	_connect_ui()
	_start_game()


func _apply_fullscreen_mode() -> void:
	if not fullscreen_on_ready or Engine.is_editor_hint():
		return
	if DisplayServer.get_name().to_lower() == "headless":
		return
	call_deferred("_enter_fullscreen")


func _enter_fullscreen() -> void:
	var window := get_window()
	if window != null:
		window.mode = Window.MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and DisplayServer.get_name().to_lower() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _setup_sky() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.06, 0.08, 0.12)
	sky_material.sky_horizon_color = Color(0.18, 0.22, 0.27)
	sky_material.ground_bottom_color = Color(0.04, 0.035, 0.03)
	sky_material.ground_horizon_color = Color(0.18, 0.14, 0.11)

	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.62

	var world_environment := WorldEnvironment.new()
	world_environment.name = "SkyEnvironment"
	world_environment.environment = environment
	add_child(world_environment)


func _setup_audio() -> void:
	_roll_audio_player = _make_audio_player("RollAudioPlayer")
	_roll_audio_player.finished.connect(_on_roll_audio_finished)
	_ui_audio_player = _make_audio_player("UiAudioPlayer")


func _make_audio_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = "Master"
	player.volume_db = sfx_volume_db
	add_child(player)
	return player


func _style_ui() -> void:
	_money_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.06, 0.055, 0.94), Color(0.42, 0.84, 0.78, 0.58)))
	_shop_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.055, 0.045, 0.075, 0.92), Color(0.88, 0.68, 0.38, 0.58)))
	_play_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.06, 0.07, 0.92), Color(0.42, 0.84, 0.78, 0.56)))
	_upgrade_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.07, 0.045, 0.03, 0.96), Color(0.94, 0.66, 0.32, 0.68)))
	_style_button(_upgrade_exit_button, Color(0.16, 0.08, 0.055, 0.95), Color(0.94, 0.66, 0.32, 0.55))


func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	return style


func _build_shop_buttons() -> void:
	_clear_children(_shop_list)
	_shop_buttons.clear()
	for upgrade_data in _SHOP_UPGRADES:
		var upgrade := upgrade_data as Dictionary
		var button := UpgradeDragButton.new()
		button.name = "%sUpgradeButton" % String(upgrade["id"]).capitalize().replace(" ", "")
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 70)
		button.mouse_default_cursor_shape = Control.CURSOR_DRAG
		button.upgrade_data = upgrade
		_style_button(button, Color(0.12, 0.09, 0.05, 0.95), Color(0.94, 0.66, 0.32, 0.5))
		_shop_list.add_child(button)
		_shop_buttons.append(button)


func _build_die_buttons() -> void:
	_clear_children(_dice_button_row)
	_die_buttons.clear()
	for index in range(DIE_COUNT):
		var button := Button.new()
		button.name = "Die%dUpgradeButton" % (index + 1)
		button.custom_minimum_size = Vector2(86, 62)
		button.pressed.connect(Callable(self, "_on_die_button_pressed").bind(index))
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var die_color: Color = _DIE_COLORS[index % _DIE_COLORS.size()]
		_style_button(button, die_color.darkened(0.42), die_color)
		_dice_button_row.add_child(button)
		_die_buttons.append(button)


func _build_face_buttons() -> void:
	_clear_children(_face_grid)
	_face_buttons.clear()
	for index in range(6):
		var button := FaceDropButton.new()
		button.name = "Face%dDropButton" % (index + 1)
		button.face_index = index
		button.custom_minimum_size = Vector2(140, 82)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.mouse_default_cursor_shape = Control.CURSOR_CAN_DROP
		button.upgrade_dropped.connect(_on_face_upgrade_dropped)
		_style_button(button, Color(0.11, 0.08, 0.045, 0.95), Color(0.94, 0.66, 0.32, 0.48))
		_face_grid.add_child(button)
		_face_buttons.append(button)


func _style_button(button: Button, background: Color, border: Color) -> void:
	var normal := _make_button_style(background, border)
	var hover := _make_button_style(background.lightened(0.07), border.lightened(0.2))
	var pressed := _make_button_style(background.darkened(0.05), border.lightened(0.35))
	var disabled := _make_button_style(background.darkened(0.26), border.darkened(0.45))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.62, 0.62, 0.62, 1.0))


func _make_button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style


func _connect_ui() -> void:
	_roll_button.pressed.connect(_on_roll_pressed)
	_upgrade_exit_button.pressed.connect(_on_upgrade_exit_pressed)
	_roller.all_dice_finished.connect(_on_all_dice_finished)


func _create_dice_from_definitions() -> void:
	_definitions.clear()
	_dice.clear()
	for index in range(DIE_COUNT):
		var definition := _make_die_definition(index)
		var die := _roller.create_die(definition)
		die.name = "PipDie%d" % (index + 1)
		die.visible = true
		_definitions.append(definition)
		_dice.append(die)
	_roller.layout_dice(_get_visual_layout_dice(), false)


func _make_die_definition(index: int) -> DiceDieDefinition3D:
	var definition := DiceDieDefinition3D.custom("PipDie%d" % (index + 1), _make_faces(index, [1, 2, 3, 4, 5, 6]))
	definition.edge_length = 0.82
	definition.body_shape = DiceDie3D.BodyShape.ROUNDED
	definition.body_color = _DIE_COLORS[index % _DIE_COLORS.size()]
	definition.body_roughness = 0.36
	definition.body_specular = 0.5
	definition.body_clearcoat = 0.24
	definition.body_clearcoat_roughness = 0.18
	definition.side_smoothing = 0.02
	definition.face_decoration_scale = 0.72
	return definition


func _make_faces(die_index: int, values: Array[int]) -> Array[DiceFace3D]:
	var faces: Array[DiceFace3D] = []
	for index in range(values.size()):
		faces.append(_make_face(die_index, index, values[index]))
	return faces


func _make_face(die_index: int, face_index: int, value: int) -> DiceFace3D:
	var safe_value := clampi(value, 1, WIN_VALUE)
	return DiceFace3D.new_face(
		safe_value,
		StringName("die%d_face%d_value%d" % [die_index + 1, face_index + 1, safe_value]),
		null,
		str(safe_value),
		null,
		_make_pip_mesh(safe_value)
	)


func _make_pip_mesh(value: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var pip_count := clampi(value, 1, WIN_VALUE)
	for position in _get_pip_positions(pip_count):
		_append_pip(vertices, normals, position)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _get_pip_material())
	return mesh


func _append_pip(vertices: PackedVector3Array, normals: PackedVector3Array, position: Vector2) -> void:
	var center := Vector3(position.x, position.y, 0.0)
	for segment in range(_PIP_SEGMENTS):
		var angle_a := TAU * float(segment) / float(_PIP_SEGMENTS)
		var angle_b := TAU * float(segment + 1) / float(_PIP_SEGMENTS)
		vertices.append(center)
		vertices.append(Vector3(position.x + cos(angle_a) * _PIP_RADIUS, position.y + sin(angle_a) * _PIP_RADIUS, 0.0))
		vertices.append(Vector3(position.x + cos(angle_b) * _PIP_RADIUS, position.y + sin(angle_b) * _PIP_RADIUS, 0.0))
		normals.append(Vector3.BACK)
		normals.append(Vector3.BACK)
		normals.append(Vector3.BACK)


func _get_pip_positions(value: int) -> Array[Vector2]:
	var left := -_PIP_OUTER
	var right := _PIP_OUTER
	var top := _PIP_OUTER
	var bottom := -_PIP_OUTER
	var middle := 0.0
	match value:
		1:
			return [Vector2.ZERO]
		2:
			return [Vector2(left, bottom), Vector2(right, top)]
		3:
			return [Vector2(left, bottom), Vector2.ZERO, Vector2(right, top)]
		4:
			return [Vector2(left, bottom), Vector2(right, bottom), Vector2(left, top), Vector2(right, top)]
		5:
			return [Vector2(left, bottom), Vector2(right, bottom), Vector2.ZERO, Vector2(left, top), Vector2(right, top)]
		_:
			return [
				Vector2(left, bottom),
				Vector2(left, middle),
				Vector2(left, top),
				Vector2(right, bottom),
				Vector2(right, middle),
				Vector2(right, top),
			]


func _get_pip_material() -> StandardMaterial3D:
	if _pip_material == null:
		_pip_material = StandardMaterial3D.new()
		_pip_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_pip_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_pip_material.albedo_color = Color(0.025, 0.022, 0.018, 1.0)
	return _pip_material


func _start_game() -> void:
	_money = STARTING_MONEY
	_displayed_money = _money
	_refresh_money_label()
	_roll_count = 0
	_last_income = 0
	_current_values = _make_int_array(DIE_COUNT, 0)
	_selected_die_index = -1
	_rolling = false
	_game_complete = false
	_status_text = "Roll to earn money."
	_upgrade_panel.visible = false
	_roller.layout_dice(_get_visual_layout_dice(), true)
	_update_ui()


func _on_roll_pressed() -> void:
	if not _can_roll():
		return

	_selected_die_index = -1
	_upgrade_panel.visible = false
	_roll_count += 1
	_rolling = true
	_status_text = "Rolling..."
	_start_roll_shake_audio()
	_update_ui()

	var requested_faces: Array[DiceFace3D] = []
	for die in _dice:
		requested_faces.append(_pick_random_face(die))

	_roller.roll_dice(_dice, requested_faces, {
		"duration": 1.35,
		"bounce_height": 1.45,
		"bounce_count": 4.0,
		"spin_turns": 12.0,
		"settle_start": 0.76,
		"per_die_delay": 0.04,
	})


func _on_all_dice_finished(results: Dictionary) -> void:
	if not _rolling:
		return

	_stop_roll_shake_audio()
	for die in results:
		var index := _dice.find(die)
		if index >= 0:
			var result := results[die] as DiceRollResult
			_current_values[index] = result.value

	_rolling = false
	_last_income = _calculate_roll_income()
	_money += _last_income
	_animate_money_to(_money)
	if _has_winning_roll():
		_game_complete = true
		_selected_die_index = -1
		_upgrade_panel.visible = false
		_status_text = "All sixes. You win!"
		_play_random_sound(_UI_SOUNDS, _ui_audio_player, 1.12, 1.2)
	else:
		_status_text = "Earned $%d. Upgrade or roll again." % _last_income
	_update_ui()


func _pick_random_face(die: DiceDie3D) -> DiceFace3D:
	var slots := die.get_face_slots()
	var slot := slots[randi() % slots.size()]
	return die.get_face(slot)


func _on_die_button_pressed(index: int) -> void:
	if _rolling or _game_complete or _roll_count == 0:
		return
	_play_random_sound(_UI_SOUNDS, _ui_audio_player, 0.94, 1.04)
	_selected_die_index = index
	_status_text = "Drag an upgrade onto Die %d." % (index + 1)
	_update_ui()


func _on_face_upgrade_dropped(face_index: int, upgrade: Dictionary) -> void:
	_try_buy_upgrade(_selected_die_index, face_index, upgrade)
	_update_ui()


func _on_upgrade_exit_pressed() -> void:
	_selected_die_index = -1
	_upgrade_panel.visible = false
	_status_text = "Upgrade closed."
	_update_ui()


func _try_buy_upgrade(die_index: int, face_index: int, upgrade: Dictionary) -> bool:
	if die_index < 0 or die_index >= _definitions.size():
		return false
	if face_index < 0 or face_index >= _definitions[die_index].faces.size():
		return false

	var cost := int(upgrade.get("cost", 0))
	if _money < cost:
		_status_text = "Need $%d for %s." % [cost, upgrade.get("title", "upgrade")]
		return false

	var old_value: int = (_definitions[die_index].faces[face_index] as DiceFace3D).value
	var new_value := _get_upgraded_value(old_value, upgrade)
	if new_value == old_value:
		_status_text = "That face is already at 6."
		return false

	_money -= cost
	_animate_money_to(_money)
	_mutate_die_face(die_index, face_index, new_value)
	_play_random_sound(_UI_SOUNDS, _ui_audio_player, 0.98, 1.08)
	_status_text = "Die %d side %d: %d -> %d." % [die_index + 1, face_index + 1, old_value, new_value]
	return true


func _get_upgraded_value(current_value: int, upgrade: Dictionary) -> int:
	if upgrade.has("set_value"):
		return clampi(int(upgrade["set_value"]), 1, WIN_VALUE)
	return clampi(current_value + int(upgrade.get("delta", 0)), 1, WIN_VALUE)


func _mutate_die_face(die_index: int, face_index: int, new_value: int) -> void:
	if die_index < 0 or die_index >= _definitions.size():
		return
	var definition := _definitions[die_index]
	if face_index < 0 or face_index >= definition.faces.size():
		return
	definition.faces[face_index] = _make_face(die_index, face_index, new_value)
	_dice[die_index].set_faces(definition.faces)


func _update_ui() -> void:
	_round_label.text = "Rolls: %d\nGoal: all 6s" % _roll_count
	_roll_button.disabled = not _can_roll()
	_roll_button.text = "You Win" if _game_complete else "Roll Dice"
	_refresh_money_label()
	_status_label.text = _status_text
	_shop_status_label.text = _get_shop_status_text()
	_upgrade_panel.visible = _selected_die_index >= 0 and not _game_complete
	_update_die_buttons()
	_update_shop_buttons()
	_update_face_buttons()
	_fit_play_panel()


func _get_shop_status_text() -> String:
	if _roll_count == 0:
		return "Roll first."
	if _selected_die_index < 0:
		return "Open a die."
	if _game_complete:
		return "Complete."
	return "Drag to a face."


func _animate_money_to(target_value: int) -> void:
	if _money_tween != null:
		_money_tween.kill()
		_money_tween = null
	if not is_inside_tree() or _money_label == null:
		_set_displayed_money(float(target_value))
		return

	var start_value := float(_displayed_money)
	var end_value := float(target_value)
	if is_equal_approx(start_value, end_value):
		_refresh_money_label()
		return

	var duration := clampf(absf(end_value - start_value) * 0.025, 0.28, 0.85)
	_money_tween = create_tween()
	_money_tween.set_trans(Tween.TRANS_CUBIC)
	_money_tween.set_ease(Tween.EASE_OUT)
	_money_tween.tween_method(Callable(self, "_set_displayed_money"), start_value, end_value, duration)


func _set_displayed_money(value: float) -> void:
	_displayed_money = int(round(value))
	_refresh_money_label()


func _refresh_money_label() -> void:
	if _money_label != null:
		_money_label.text = "$%d" % _displayed_money


func _start_roll_shake_audio() -> void:
	_active_roll_shake = _pick_random_sound(_ROLL_SHAKE_SOUNDS)
	if _active_roll_shake == null or _roll_audio_player == null:
		return

	_roll_audio_player.stop()
	_roll_audio_player.stream = _active_roll_shake
	_roll_audio_player.pitch_scale = randf_range(0.96, 1.04)
	_roll_audio_player.play()


func _stop_roll_shake_audio() -> void:
	_active_roll_shake = null
	if _roll_audio_player != null:
		_roll_audio_player.stop()


func _on_roll_audio_finished() -> void:
	if not _rolling or _active_roll_shake == null or _roll_audio_player == null:
		return

	_roll_audio_player.stream = _active_roll_shake
	_roll_audio_player.play()


func _play_random_sound(sounds: Array, player: AudioStreamPlayer, pitch_min: float = 1.0, pitch_max: float = 1.0) -> void:
	if player == null:
		return

	var stream := _pick_random_sound(sounds)
	if stream == null:
		return

	player.stop()
	player.stream = stream
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.play()


func _pick_random_sound(sounds: Array) -> AudioStream:
	if sounds.is_empty():
		return null
	return sounds[randi() % sounds.size()] as AudioStream


func _update_die_buttons() -> void:
	for index in range(_die_buttons.size()):
		var button := _die_buttons[index]
		var value_text := "-" if _current_values[index] == 0 else str(_current_values[index])
		button.text = "Die %d\nRoll: %s\nUpgrade" % [
			index + 1,
			value_text,
		]
		button.disabled = _rolling or _game_complete or _roll_count == 0


func _update_shop_buttons() -> void:
	for index in range(_shop_buttons.size()):
		var button := _shop_buttons[index]
		var upgrade := _SHOP_UPGRADES[index] as Dictionary
		var cost := int(upgrade["cost"])
		button.text = "%s\n$%d\n%s" % [upgrade["title"], cost, upgrade["body"]]
		button.disabled = _rolling or _game_complete or _selected_die_index < 0 or _money < cost


func _update_face_buttons() -> void:
	var has_selected_die := _selected_die_index >= 0 and _selected_die_index < _definitions.size()
	var selected_color := Color(0.94, 0.66, 0.32, 1.0)
	if has_selected_die:
		selected_color = _DIE_COLORS[_selected_die_index % _DIE_COLORS.size()]
		_upgrade_title_label.text = "Upgrade Die %d" % (_selected_die_index + 1)
		_selected_die_label.text = "Drop a shop upgrade onto one side."
	else:
		_upgrade_title_label.text = "Upgrade Die"
		_selected_die_label.text = "Open a die from the bottom controls."

	for index in range(_face_buttons.size()):
		var button := _face_buttons[index]
		var value_text := "-"
		if has_selected_die:
			value_text = str((_definitions[_selected_die_index].faces[index] as DiceFace3D).value)
		button.text = "Side %d\nValue %s" % [index + 1, value_text]
		button.disabled = not has_selected_die or _rolling or _game_complete
		_style_button(button, selected_color.darkened(0.48), selected_color)


func _fit_play_panel() -> void:
	var width := 700.0
	var height := 92.0
	_play_panel.offset_left = width * -0.5
	_play_panel.offset_right = width * 0.5
	_play_panel.offset_top = -height - 18.0
	_play_panel.offset_bottom = -18.0


func _can_roll() -> bool:
	return not _rolling and not _game_complete


func _has_winning_roll() -> bool:
	if _current_values.size() != DIE_COUNT:
		return false
	for value in _current_values:
		if value != WIN_VALUE:
			return false
	return true


func _calculate_roll_income() -> int:
	return ROLL_INCOME_BASE + _sum_values(_current_values)


func _sum_values(values: Array[int]) -> int:
	var total := 0
	for value in values:
		total += value
	return total


func _get_visual_layout_dice() -> Array[DiceDie3D]:
	var visual_dice: Array[DiceDie3D] = []
	visual_dice.append_array(_dice)
	visual_dice.reverse()
	return visual_dice


func _get_definition_values(die_index: int) -> Array[int]:
	var values: Array[int] = []
	for face in _definitions[die_index].faces:
		values.append((face as DiceFace3D).value)
	return values


func _make_int_array(count: int, value: int) -> Array[int]:
	var result: Array[int] = []
	for _index in range(count):
		result.append(value)
	return result


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
