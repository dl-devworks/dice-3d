extends Node


const NUMBER_DIE_DEFINITION: DiceDieDefinition3D = preload("res://addons/dice_3d/demo/assets/number_die_definition.tres")
const SYMBOL_DIE_DEFINITION: DiceDieDefinition3D = preload("res://addons/dice_3d/demo/assets/symbol_die_definition.tres")
const D20_DIE_DEFINITION: DiceDieDefinition3D = preload("res://addons/dice_3d/demo/assets/d20_die_definition.tres")
const MAX_DICE := 9
const BASE_ROLL_IMPULSE_MIN := 7.5
const BASE_ROLL_IMPULSE_MAX := 11.5
const BASE_INITIAL_SPIN_MIN := 12.0
const BASE_INITIAL_SPIN_MAX := 20.0
const DICE_TYPE_NORMAL := 0
const DICE_TYPE_ICON := 1
const DICE_TYPE_D20 := 2
const _DICE_TYPES := [DICE_TYPE_NORMAL, DICE_TYPE_ICON, DICE_TYPE_D20]
const _GRAVITY_OPTIONS := [
	{"label": "Away", "bottom_side": DiceRollBox3D.BoxSide.NEG_Z},
	{"label": "Toward", "bottom_side": DiceRollBox3D.BoxSide.POS_Z},
	{"label": "Down", "bottom_side": DiceRollBox3D.BoxSide.NEG_Y},
	{"label": "Up", "bottom_side": DiceRollBox3D.BoxSide.POS_Y},
	{"label": "Left", "bottom_side": DiceRollBox3D.BoxSide.NEG_X},
	{"label": "Right", "bottom_side": DiceRollBox3D.BoxSide.POS_X},
]

@onready var _stage_world: Node3D = $CanvasLayer/AppRoot/StageViewport/SubViewport/StageWorld
@onready var _roll_box: DiceRollBox3D = $CanvasLayer/AppRoot/StageViewport/SubViewport/StageWorld/DiceRollBox3D
@onready var _normal_minus_button: Button = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/DiceTypeRows/NormalRow/MinusButton
@onready var _normal_count_label: Label = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/DiceTypeRows/NormalRow/CountLabel
@onready var _normal_plus_button: Button = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/DiceTypeRows/NormalRow/PlusButton
@onready var _icon_minus_button: Button = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/DiceTypeRows/IconRow/MinusButton
@onready var _icon_count_label: Label = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/DiceTypeRows/IconRow/CountLabel
@onready var _icon_plus_button: Button = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/DiceTypeRows/IconRow/PlusButton
@onready var _d20_minus_button: Button = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/DiceTypeRows/D20Row/MinusButton
@onready var _d20_count_label: Label = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/DiceTypeRows/D20Row/CountLabel
@onready var _d20_plus_button: Button = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/DiceTypeRows/D20Row/PlusButton
@onready var _gravity_button: Button = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/GravityRow/GravityButton
@onready var _gravity_strength_label: Label = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/GravityStrengthRow/GravityStrengthLabel
@onready var _gravity_strength_slider: HSlider = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/GravityStrengthRow/GravityStrengthSlider
@onready var _roll_strength_label: Label = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/RollStrengthRow/RollStrengthLabel
@onready var _roll_strength_slider: HSlider = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/RollStrengthRow/RollStrengthSlider
@onready var _roll_button: Button = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/RollButton
@onready var _status_label: Label = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/StatusLabel
@onready var _result_label: Label = $CanvasLayer/AppRoot/Controls/MarginContainer/VBoxContainer/ResultLabel

var _dice: Array[DiceDie3D] = []
var _typed_dice: Dictionary = {}
var _normal_dice_count := 1
var _icon_dice_count := 1
var _d20_dice_count := 1
var _rolling := false
var _roll_count := 0
var _settled_count := 0
var _gravity_option_index := 0


func _ready() -> void:
	randomize()
	_setup_sky()
	_configure_roll_box()
	_connect_ui()
	_sync_dice_counts()
	_update_ui()


func _setup_sky() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.07, 0.11, 0.16)
	sky_material.sky_horizon_color = Color(0.2, 0.24, 0.28)
	sky_material.ground_bottom_color = Color(0.025, 0.03, 0.035)
	sky_material.ground_horizon_color = Color(0.1, 0.11, 0.12)

	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.58

	var world_environment := WorldEnvironment.new()
	world_environment.name = "SkyEnvironment"
	world_environment.environment = environment
	_stage_world.add_child(world_environment)


func _configure_roll_box() -> void:
	_gravity_option_index = _get_gravity_option_index(DiceRollBox3D.BoxSide.NEG_Z)
	_apply_gravity_option(false)
	_roll_box.roll_source = DiceRollBox3D.RollSource.CUSTOM_LOCAL
	_roll_box.custom_roll_source_local = Vector3(1.0, 1.0, 0.0)
	_roll_box.roll_source_outside_distance = 0.0
	_roll_box.roll_source_spread = 0.2
	_roll_box.roll_target_spread = 0.65
	_roll_box.roll_upward_bias = 0.0
	_roll_box.suspend_gravity_until_inside = false
	_apply_roll_strength(false)


func _connect_ui() -> void:
	_normal_minus_button.pressed.connect(_on_normal_minus_pressed)
	_normal_plus_button.pressed.connect(_on_normal_plus_pressed)
	_icon_minus_button.pressed.connect(_on_icon_minus_pressed)
	_icon_plus_button.pressed.connect(_on_icon_plus_pressed)
	_d20_minus_button.pressed.connect(_on_d20_minus_pressed)
	_d20_plus_button.pressed.connect(_on_d20_plus_pressed)
	_gravity_button.pressed.connect(_on_gravity_pressed)
	_gravity_strength_slider.value_changed.connect(_on_gravity_strength_changed)
	_roll_strength_slider.value_changed.connect(_on_roll_strength_changed)
	_roll_button.pressed.connect(_on_roll_pressed)
	_roll_box.roll_finished.connect(_on_roll_finished)
	_roll_box.all_dice_settled.connect(_on_all_dice_settled)


func _sync_dice_counts() -> void:
	_dice.clear()
	for type in _DICE_TYPES:
		_sync_type_dice(type)
		var dice := _get_typed_dice(type)
		for die in dice:
			if die != null:
				_dice.append(die)

	_apply_roll_strength(false)
	_reset_dice_to_corner()


func _sync_type_dice(type: int) -> void:
	var dice := _get_typed_dice(type)
	var target_count := _get_type_count(type)
	while dice.size() < target_count:
		var definition := _get_definition_for_type(type)
		var die := _roll_box.create_die(definition)
		var display_name := _get_type_display_name(type)
		if definition != null and not definition.display_name.is_empty():
			display_name = definition.display_name
		die.name = "%s%d" % [display_name, dice.size() + 1]
		dice.append(die)

	while dice.size() > target_count:
		var die := dice.pop_back() as DiceDie3D
		_roll_box.remove_die(die)
		die.queue_free()


func _on_normal_minus_pressed() -> void:
	if _rolling:
		return
	_set_type_count(DICE_TYPE_NORMAL, _normal_dice_count - 1)


func _on_normal_plus_pressed() -> void:
	if _rolling:
		return
	_set_type_count(DICE_TYPE_NORMAL, _normal_dice_count + 1)


func _on_icon_minus_pressed() -> void:
	if _rolling:
		return
	_set_type_count(DICE_TYPE_ICON, _icon_dice_count - 1)


func _on_icon_plus_pressed() -> void:
	if _rolling:
		return
	_set_type_count(DICE_TYPE_ICON, _icon_dice_count + 1)


func _on_d20_minus_pressed() -> void:
	if _rolling:
		return
	_set_type_count(DICE_TYPE_D20, _d20_dice_count - 1)


func _on_d20_plus_pressed() -> void:
	if _rolling:
		return
	_set_type_count(DICE_TYPE_D20, _d20_dice_count + 1)


func _set_type_count(type: int, value: int) -> void:
	var current_count := _get_type_count(type)
	var available_growth := MAX_DICE - _get_total_dice_count() + current_count
	var clamped_count := clampi(value, 0, max(available_growth, 0))
	match type:
		DICE_TYPE_NORMAL:
			_normal_dice_count = clamped_count
		DICE_TYPE_ICON:
			_icon_dice_count = clamped_count
		DICE_TYPE_D20:
			_d20_dice_count = clamped_count
	_sync_dice_counts()
	_update_ui()


func _on_gravity_pressed() -> void:
	if _rolling:
		return
	_gravity_option_index = (_gravity_option_index + 1) % _GRAVITY_OPTIONS.size()
	_apply_gravity_option(true)
	_update_ui()


func _on_gravity_strength_changed(value: float) -> void:
	_roll_box.gravity_strength = value
	_update_gravity_labels()


func _on_roll_strength_changed(_value: float) -> void:
	_apply_roll_strength(false)
	_update_roll_strength_label()


func _on_roll_pressed() -> void:
	if _rolling or _dice.is_empty():
		return
	_roll_count += 1
	_settled_count = 0
	_rolling = true
	_status_label.text = "Rolling %d" % _roll_count
	_result_label.text = ""
	_update_buttons()
	for index in range(_dice.size()):
		var die := _dice[index]
		_roll_box.roll(die, _make_corner_roll_options(die, index, _dice.size()))


func _on_roll_finished(_result: DiceRollResult) -> void:
	_settled_count += 1
	_status_label.text = "Settled %d/%d" % [_settled_count, _dice.size()]


func _on_all_dice_settled(results: Dictionary) -> void:
	_rolling = false
	_status_label.text = "Results"
	_result_label.text = _format_results(results)
	_update_buttons()


func _format_results(results: Dictionary) -> String:
	var total := 0
	var parts: Array[String] = []
	for die in _dice:
		if not results.has(die):
			continue
		var result := results[die] as DiceRollResult
		if result == null:
			continue
		total += result.value
		parts.append("%s: %s" % [die.name, result.display_name])
	if parts.is_empty():
		return "No result"
	return "%s\nTotal %d" % [" | ".join(parts), total]


func _update_ui() -> void:
	_update_type_count_labels()
	_update_gravity_labels()
	_update_roll_strength_label()
	if not _rolling:
		_status_label.text = "Ready"
		if _result_label.text.is_empty():
			_result_label.text = ""
	_update_buttons()


func _update_buttons() -> void:
	var total_count := _get_total_dice_count()
	_normal_minus_button.disabled = _rolling or _normal_dice_count <= 0
	_icon_minus_button.disabled = _rolling or _icon_dice_count <= 0
	_d20_minus_button.disabled = _rolling or _d20_dice_count <= 0
	_normal_plus_button.disabled = _rolling or total_count >= MAX_DICE
	_icon_plus_button.disabled = _rolling or total_count >= MAX_DICE
	_d20_plus_button.disabled = _rolling or total_count >= MAX_DICE
	_gravity_button.disabled = _rolling
	_roll_button.disabled = _rolling or _dice.is_empty()


func _apply_gravity_option(reset_dice: bool) -> void:
	var option: Dictionary = _GRAVITY_OPTIONS[_gravity_option_index]
	_roll_box.bottom_side = int(option["bottom_side"])
	_roll_box.gravity_strength = _gravity_strength_slider.value
	if reset_dice and not _dice.is_empty():
		_reset_dice_to_corner()


func _apply_roll_strength(reset_dice: bool) -> void:
	var strength := _roll_strength_slider.value
	_roll_box.default_roll_impulse_min = BASE_ROLL_IMPULSE_MIN * strength
	_roll_box.default_roll_impulse_max = BASE_ROLL_IMPULSE_MAX * strength
	_roll_box.default_initial_spin_min = BASE_INITIAL_SPIN_MIN * strength
	_roll_box.default_initial_spin_max = BASE_INITIAL_SPIN_MAX * strength
	for die in _dice:
		_roll_box.apply_default_roll_settings(die)
	if reset_dice and not _dice.is_empty():
		_reset_dice_to_corner()


func _get_gravity_option_index(bottom_side: int) -> int:
	for index in range(_GRAVITY_OPTIONS.size()):
		if int(_GRAVITY_OPTIONS[index]["bottom_side"]) == bottom_side:
			return index
	return 0


func _update_type_count_labels() -> void:
	_normal_count_label.text = str(_normal_dice_count)
	_icon_count_label.text = str(_icon_dice_count)
	_d20_count_label.text = str(_d20_dice_count)


func _update_gravity_labels() -> void:
	var option: Dictionary = _GRAVITY_OPTIONS[_gravity_option_index]
	_gravity_button.text = "Gravity: %s" % str(option["label"])
	_gravity_strength_label.text = "%.1f" % _roll_box.gravity_strength


func _update_roll_strength_label() -> void:
	_roll_strength_label.text = "%.1fx" % _roll_strength_slider.value


func _get_typed_dice(type: int) -> Array:
	if not _typed_dice.has(type):
		_typed_dice[type] = []
	return _typed_dice[type]


func _get_type_count(type: int) -> int:
	match type:
		DICE_TYPE_NORMAL:
			return _normal_dice_count
		DICE_TYPE_ICON:
			return _icon_dice_count
		DICE_TYPE_D20:
			return _d20_dice_count
	return 0


func _get_total_dice_count() -> int:
	return _normal_dice_count + _icon_dice_count + _d20_dice_count


func _get_definition_for_type(type: int) -> DiceDieDefinition3D:
	match type:
		DICE_TYPE_NORMAL:
			return NUMBER_DIE_DEFINITION
		DICE_TYPE_ICON:
			return SYMBOL_DIE_DEFINITION
		DICE_TYPE_D20:
			return D20_DIE_DEFINITION
	return NUMBER_DIE_DEFINITION


func _get_type_display_name(type: int) -> String:
	match type:
		DICE_TYPE_NORMAL:
			return "NumberDie"
		DICE_TYPE_ICON:
			return "IconDie"
		DICE_TYPE_D20:
			return "D20Die"
	return "Die"


func _reset_dice_to_corner() -> void:
	for index in range(_dice.size()):
		var die := _dice[index]
		if die == null:
			continue
		die.freeze = false
		die.linear_velocity = Vector3.ZERO
		die.angular_velocity = Vector3.ZERO
		die.global_transform = Transform3D(_random_basis(), _get_corner_spawn_position(die, index, _dice.size()))
		die.sleeping = true


func _make_corner_roll_options(die: DiceDie3D, index: int, total: int) -> DiceRollOptions:
	var options := DiceRollOptions.new()
	options.reset_before_roll = true
	options.use_spawn_position = true
	options.spawn_position = _get_corner_spawn_position(die, index, total)
	options.randomize_rotation = true
	return options


func _get_corner_spawn_position(die: DiceDie3D, index: int, total: int) -> Vector3:
	var local_position := _get_corner_spawn_local_position(die, index, total)
	var box_transform := _roll_box.global_transform if _roll_box.is_inside_tree() else _roll_box.transform
	return box_transform * local_position


func _get_corner_spawn_local_position(die: DiceDie3D, index: int, total: int) -> Vector3:
	var source_vector := _roll_box.custom_roll_source_local
	var bottom_normal := _roll_box.get_bottom_side_normal()
	var top_normal := -bottom_normal
	var top_axis := _dominant_axis(top_normal)
	var padding := _get_effective_spawn_padding(die)
	var local_position := Vector3.ZERO

	for axis in [Vector3.AXIS_X, Vector3.AXIS_Y, Vector3.AXIS_Z]:
		var extent := _axis_extent(axis)
		if axis == top_axis:
			local_position = _with_axis_value(
				local_position,
				axis,
				signf(_axis_value(top_normal, axis)) * maxf(extent - padding, 0.0)
			)
			continue

		var source_sign := signf(_axis_value(source_vector, axis))
		if is_zero_approx(source_sign):
			local_position = _with_axis_value(local_position, axis, 0.0)
		else:
			local_position = _with_axis_value(
				local_position,
				axis,
				source_sign * maxf(extent - padding, 0.0)
			)

	var lane_axes := _get_corner_lane_axes(top_axis)
	var primary_lane_axis := int(lane_axes[0])
	var secondary_lane_axis := int(lane_axes[1])
	var primary_lane_sign := _get_lane_sign(source_vector, primary_lane_axis)
	var secondary_lane_sign := _get_lane_sign(source_vector, secondary_lane_axis)
	var lane_spacing := maxf(_get_die_half_extent(die) * 2.35, 0.9)
	var primary_limit := maxf(_axis_extent(primary_lane_axis) - padding, 0.0)
	var secondary_limit := maxf(_axis_extent(secondary_lane_axis) - padding, 0.0)
	var primary_slots := max(1, int(floor((primary_limit * 2.0) / lane_spacing)) + 1)
	var primary_index: int = index % primary_slots
	var secondary_index: int = int(index / primary_slots)
	var primary_value := _axis_value(local_position, primary_lane_axis) - primary_lane_sign * lane_spacing * float(primary_index)
	var secondary_value := _axis_value(local_position, secondary_lane_axis) - secondary_lane_sign * lane_spacing * float(secondary_index)
	local_position = _with_axis_value(local_position, primary_lane_axis, clampf(primary_value, -primary_limit, primary_limit))
	local_position = _with_axis_value(local_position, secondary_lane_axis, clampf(secondary_value, -secondary_limit, secondary_limit))
	return local_position


func _get_corner_lane_axes(top_axis: int) -> Array[int]:
	if top_axis != Vector3.AXIS_Y:
		var secondary_axis := Vector3.AXIS_X if top_axis != Vector3.AXIS_X else Vector3.AXIS_Z
		return [Vector3.AXIS_Y, secondary_axis]
	return [Vector3.AXIS_X, Vector3.AXIS_Z]


func _get_lane_sign(source_vector: Vector3, axis: int) -> float:
	var lane_sign := signf(_axis_value(source_vector, axis))
	if is_zero_approx(lane_sign):
		lane_sign = 1.0
	return lane_sign


func _get_effective_spawn_padding(die: DiceDie3D) -> float:
	var die_half := _get_die_half_extent(die)
	var unclamped_padding := maxf(_roll_box.spawn_padding, 0.0) + die_half
	return minf(unclamped_padding, minf(_roll_box.size.x, minf(_roll_box.size.y, _roll_box.size.z)) * 0.45)


func _get_die_half_extent(die: DiceDie3D) -> float:
	if die == null:
		return 0.0
	return maxf(die.edge_length, 0.0) * 0.5


func _dominant_axis(vector: Vector3) -> int:
	var absolute := vector.abs()
	if absolute.x >= absolute.y and absolute.x >= absolute.z:
		return Vector3.AXIS_X
	if absolute.y >= absolute.z:
		return Vector3.AXIS_Y
	return Vector3.AXIS_Z


func _axis_extent(axis: int) -> float:
	match axis:
		Vector3.AXIS_X:
			return _roll_box.size.x * 0.5
		Vector3.AXIS_Y:
			return _roll_box.size.y * 0.5
		Vector3.AXIS_Z:
			return _roll_box.size.z * 0.5
		_:
			return _roll_box.size.y * 0.5


func _axis_value(vector: Vector3, axis: int) -> float:
	match axis:
		Vector3.AXIS_X:
			return vector.x
		Vector3.AXIS_Y:
			return vector.y
		Vector3.AXIS_Z:
			return vector.z
		_:
			return 0.0


func _with_axis_value(vector: Vector3, axis: int, value: float) -> Vector3:
	var result := vector
	match axis:
		Vector3.AXIS_X:
			result.x = value
		Vector3.AXIS_Y:
			result.y = value
		Vector3.AXIS_Z:
			result.z = value
	return result


func _random_basis() -> Basis:
	var quaternion := Quaternion(Vector3.RIGHT, randf() * TAU)
	quaternion *= Quaternion(Vector3.UP, randf() * TAU)
	quaternion *= Quaternion(Vector3.BACK, randf() * TAU)
	return Basis(quaternion)
