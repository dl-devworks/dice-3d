# Dice 3D API

## Core Structure

Dice 3D has two main roll nodes: `DiceCinematicRoller3D` for controlled animation rolls, and `DiceRollBox3D` for physics-based rolls. Both consume the same `DiceDieDefinition3D` resources. `DiceDieDefinition3D` describes what a die is, `DiceDieShape3D` provides the shape slot/normal/anchor data, and `DiceDie3D` renders the die from that data.

The shipped shapes are D6 and D20. The shape-data layer is in place so D8/D10/D12 can be added without rewriting the cinematic result alignment, face anchors, or top-face lookup code.

## DiceRollBox3D

`DiceRollBox3D` is the physics integration point. It owns the roll environment: bounds, gravity, collision layers, dice registration, top-face detection, and result signals. By default it builds a closed box with floor, walls, and ceiling so dice stay contained. Gravity points toward the selected `bottom_side`.

Important exports:

- `size: Vector3`
- `wall_thickness: float`
- `bottom_side: int` defaults to `-Y`
- `gravity_strength: float`
- `dice_collision_layer: int`
- `dice_collision_mask: int`
- `auto_configure_collision: bool`
- `floor_enabled: bool`
- `walls_enabled: bool`
- `ceiling_enabled: bool` defaults to `true`
- `debug_visible: bool`
- `debug_surface_alpha: float`
- `debug_edge_alpha: float`
- `spawn_padding: float`
- `spawn_dice_from_definitions_on_ready: bool`
- `dice_definitions: Array[DiceDieDefinition3D]`
- `auto_configure_dice_roll_settings: bool`
- `default_roll_impulse_min: float`
- `default_roll_impulse_max: float`
- `default_initial_spin_min: float`
- `default_initial_spin_max: float`
- `roll_source: int` source side or corner used for default roll placement
- `custom_roll_source_local: Vector3` custom normalized local source vector
- `roll_source_spread: float`
- `roll_source_outside_distance: float`
- `roll_toward_center: bool`
- `roll_target_spread: float`
- `roll_upward_bias: float`
- `launch_opening_duration: float`
- `suspend_gravity_until_inside: bool`
- `suspended_gravity_timeout: float`
- `launch_entry_margin: float`
- `dice_friction: float`
- `dice_bounce: float`
- `reroll_unflat_results: bool`
- `flat_result_threshold: float`
- `max_unflat_rerolls: int`

Important methods:

- `create_die(definition_or_faces := null) -> DiceDie3D`
- `create_die_from_definition(definition: DiceDieDefinition3D) -> DiceDie3D`
- `spawn_dice_from_definitions(reset_existing := true) -> Array[DiceDie3D]`
- `clear_definition_spawned_dice() -> void`
- `add_die_definition(definition: DiceDieDefinition3D, spawn_now := false) -> DiceDie3D`
- `remove_die_definition(definition: DiceDieDefinition3D) -> void`
- `get_die_definitions() -> Array[DiceDieDefinition3D]`
- `set_die_faces(die: DiceDie3D, faces: Array) -> void`
- `add_die(die: DiceDie3D) -> void`
- `remove_die(die: DiceDie3D) -> void`
- `roll(die: DiceDie3D, options: DiceRollOptions = null) -> void`
- `roll_all(options: DiceRollOptions = null) -> void`
- `reset_die(die: DiceDie3D) -> void`
- `reset_all() -> void`
- `get_top_face(die: DiceDie3D) -> DiceFace3D`
- `get_result(die: DiceDie3D) -> DiceRollResult`
- `get_random_spawn_position() -> Vector3`
- `get_roll_source_position(die: DiceDie3D = null) -> Vector3`
- `get_roll_direction_to_center(from_world_position: Vector3) -> Vector3`
- `get_registered_dice() -> Array[DiceDie3D]`
- `get_up_direction() -> Vector3`
- `get_gravity_vector() -> Vector3`
- `should_apply_gravity_to_die(die: DiceDie3D) -> bool`
- `is_die_inside_roll_box(die: DiceDie3D, margin := 0.0) -> bool`
- `is_world_position_inside_roll_box(world_position: Vector3, margin := 0.0) -> bool`
- `get_bottom_side_normal() -> Vector3`
- `apply_default_roll_settings(die: DiceDie3D) -> void`
- `apply_default_dice_settings(die: DiceDie3D) -> void`
- `rebuild() -> void`

Signals:

- `die_added(die)`
- `die_removed(die)`
- `roll_started(die)`
- `roll_finished(result)`
- `unflat_reroll_requested(die, flatness, reroll_count)`
- `all_dice_settled(results: Dictionary)`

Roll source settings:

`roll_source` chooses where dice are reset before a normal roll. The built-in options cover the four X/Z corners and the four X/Z sides, plus `RANDOM_INSIDE` and `CUSTOM_LOCAL`. The chosen source is interpreted in the roll box's local space. The current `bottom_side` axis is reserved for height placement, so dice spawn near the active top side and roll/fall toward the center.

When `roll_toward_center` is enabled, any roll without an explicit `DiceRollOptions.impulse` gets a generated launch impulse from its current/source position toward the center of the box. `roll_target_spread` varies the center target and `roll_upward_bias` adds lift away from the active bottom side.

Set `roll_source_outside_distance` above zero to launch from just outside the selected source wall or corner. The roll box briefly disables those source wall collision shapes for `launch_opening_duration` seconds, then re-enables them. This gives the die a clean entrance path while keeping the box enclosed after launch.

When `suspend_gravity_until_inside` is enabled, outside-launched dice do not receive roll-box gravity until their center enters the box bounds. This prevents them from falling below the floor before they reach the opening. `suspended_gravity_timeout` is a safety release in seconds, and `launch_entry_margin` controls how much tolerance the inside check uses.

## DiceCinematicRoller3D

`DiceCinematicRoller3D` is the non-physics roller. It reuses `DiceDie3D`, `DiceDieDefinition3D`, `DiceFace3D`, and `DiceRollResult`, but dice are frozen and manually animated along a controlled presentation path. Use it for RPG/check flows where you want a predictable roll presentation: gameplay can pass in a chosen result, or the roller can choose a random face when no result is supplied.

Important exports:

- `stage_size: Vector3`
- `result_side: int` local side the final face points toward
- `end_padding: float`
- `dice_spacing: float`
- `spin_clearance: float`
- `layout_tween_duration: float`
- `auto_layout_on_add_remove: bool`
- `debug_visible: bool`
- `debug_edge_alpha: float`
- `spawn_dice_from_definitions_on_ready: bool`
- `dice_definitions: Array[DiceDieDefinition3D]`
- `roll_duration: float`
- `bounce_height: float`
- `bounce_count: float`
- `spin_turns: float`
- `settle_start: float`
- `per_die_delay: float`
- `align_flat_bottom_on_land: bool`
- `randomize_idle_start_side: bool`
- `idle_spin_enabled: bool`
- `randomize_idle_spin_on_layout: bool`
- `idle_spin_speed_min_degrees: float`
- `idle_spin_speed_max_degrees: float`
- `idle_spin_after_result: bool`

Important methods:

- `create_die(definition_or_faces := null) -> DiceDie3D`
- `create_die_from_definition(definition: DiceDieDefinition3D) -> DiceDie3D`
- `spawn_dice_from_definitions(reset_existing := true) -> Array[DiceDie3D]`
- `clear_definition_spawned_dice() -> void`
- `add_die_definition(definition: DiceDieDefinition3D, spawn_now := false) -> DiceDie3D`
- `remove_die_definition(definition: DiceDieDefinition3D) -> void`
- `get_die_definitions() -> Array[DiceDieDefinition3D]`
- `set_die_faces(die: DiceDie3D, faces: Array) -> void`
- `add_die(die: DiceDie3D) -> void`
- `remove_die(die: DiceDie3D) -> void`
- `roll(die: DiceDie3D, requested_result := null, options := {}) -> void`
- `roll_all(requested_results := null, options := {}) -> void`
- `roll_dice(dice_to_roll: Array, requested_results := null, options := {}) -> void`
- `cancel_rolls() -> void`
- `layout_dice(dice_to_layout := [], tweened := true) -> void`
- `reset_die(die: DiceDie3D, index := 0, total := 1) -> void`
- `reset_all() -> void`
- `get_registered_dice() -> Array[DiceDie3D]`
- `get_result(die: DiceDie3D) -> DiceRollResult`
- `get_result_direction() -> Vector3`
- `get_gravity_direction() -> Vector3`
- `get_stage_vertical_direction() -> Vector3`
- `get_result_side_normal() -> Vector3`
- `rebuild() -> void`

Signals:

- `die_added(die)`
- `die_removed(die)`
- `roll_started(die)`
- `roll_finished(result)`
- `all_dice_finished(results: Dictionary)`

`requested_result` can be a face value, a face slot such as `DiceDie3D.SLOT_POS_Y`, a `face_id`, a `DiceFace3D`, or a dictionary with `slot`, `face`, `face_id`, or `value`. If it is omitted, the roller chooses a random face. Per-roll `options` can override `duration`, `bounce_height`, `bounce_count`, `spin_turns`, `settle_start`, `start_delay`, and `per_die_delay`.

The cinematic roller always uses a box-shaped presentation stage and a vertical-bounce result reveal. It does not create physics walls or collision; it is a presentation controller. Use `stage_size` to size the debug frame; the die stays over its landing point, bounces straight up and down, spins rapidly, and settles onto the final face.

When `align_flat_bottom_on_land` is enabled, D6 dice prioritize landing one face flat against the stage bottom, then twist so the requested result face points toward `result_side` as closely as the shape allows. D20 dice prioritize presenting the requested result face directly toward `result_side`, then use the strongest available twist bias toward a stable-looking bottom. `spin_clearance` is the minimum spacing used for multi-die layout, and `layout_dice()` tweens visible dice into evenly spaced positions so adding or hiding dice can make room cleanly. When `randomize_idle_start_side` is enabled, each layout/reset gives the waiting die a random presented side. When `idle_spin_enabled` is on, visible dice that are not rolling or holding a result slowly rotate around the stage vertical axis while waiting; `randomize_idle_spin_on_layout` refreshes the waiting spin speed and direction each time dice are arranged.

The cinematic roller does not use gravity, collision, friction, bounce, or top-face physics. `DiceRollResult.roll_box` is `null` for cinematic results, while `top_normal` is the world-space presentation direction and `gravity_direction` is its opposite for compatibility with code that expects a direction field.

## DiceCinematicRollPanel

`DiceCinematicRollPanel` is a drop-in UI control for the cinematic roller. Instance `res://addons/dice_3d/ui/dice_cinematic_roll_panel.tscn` under a `CanvasLayer` or UI container, then point `roller_path` at a `DiceCinematicRoller3D`. The bundled scene keeps the example intentionally small: Normal, Icons, and D20 rows each have plus/minus controls, and the panel rolls the visible dice through the linked roller before listing the landed faces.

Important exports:

- `roller_path: NodePath`
- `normal_die_definition: DiceDieDefinition3D`
- `icon_die_definition: DiceDieDefinition3D`
- `d20_die_definition: DiceDieDefinition3D`
- `max_dice: int`
- `normal_dice_count: int`
- `icon_dice_count: int`
- `d20_dice_count: int`

Important methods:

- `refresh(tweened := false) -> void`
- `set_dice_type_count(type: int, value: int, tweened := true) -> void`
- `add_normal_die_to_roll() -> void`
- `remove_normal_die_from_roll() -> void`
- `add_icon_die_to_roll() -> void`
- `remove_icon_die_from_roll() -> void`
- `add_d20_die_to_roll() -> void`
- `remove_d20_die_from_roll() -> void`
- `get_dice_count() -> int`
- `get_active_dice() -> Array[DiceDie3D]`

Signals:

- `dice_count_changed(count)`
- `roll_started(dice)`
- `dice_results_finished(results)`

The panel creates dice through the linked `DiceCinematicRoller3D` using the definition assigned to each row. It calls `layout_dice()` whenever dice are added or removed so the 3D dice tween into evenly spaced positions, but it does not relayout right before rolling; rerolls start from the dice's current pose. Finished rolls are formatted as one line per die, such as `NumberDie1: Three`. This keeps the example readable while leaving game-specific checks, bonuses, and success logic in your own UI.

## DiceDieDefinition3D

`DiceDieDefinition3D` is the inspector-friendly die resource. Put these resources in `DiceRollBox3D.dice_definitions` for physics dice or `DiceCinematicRoller3D.dice_definitions` for animated dice when you want the scene tree to own which dice exist. Code can still create, add, or modify definitions at runtime.

See `res://addons/dice_3d/demo/dice_definitions_example.gd` for a compact code example that creates a textured numbered D6, a textured icon D6, and a generated numbered D20, then assigns them to a `DiceCinematicRollPanel` or `DiceCinematicRoller3D`.

Important exports:

- `display_name: String`
- `count: int`
- `metadata: Dictionary`
- `die_shape: int` D6 or D20
- `edge_length: float`
- `body_shape: int`
- `body_material: Material`
- `body_color: Color`
- `body_roughness: float`
- `body_specular: float`
- `body_clearcoat: float`
- `body_clearcoat_roughness: float`
- `side_smoothing: float`
- `side_smoothing_segments: int`
- `roll_impulse_min: float`
- `roll_impulse_max: float`
- `roll_torque_min: float`
- `roll_torque_max: float`
- `settle_linear_velocity: float`
- `settle_angular_velocity: float`
- `settle_duration: float`
- `face_decoration_offset: float`
- `face_decoration_scale: float`
- `faces: Array[DiceFace3D]`

Important methods:

- `create_die() -> DiceDie3D`
- `apply_to_die(die: DiceDie3D) -> void`
- `numbered_d6() -> DiceDieDefinition3D`
- `numbered_d20() -> DiceDieDefinition3D`
- `custom(display_name: String, faces: Array[DiceFace3D]) -> DiceDieDefinition3D`

`count` controls how many dice this definition spawns when a roller or roll box calls `spawn_dice_from_definitions()`. `faces` are interpreted in the selected shape's slot order. The shipped D6 order is `+Y`, `-Y`, `+Z`, `-Z`, `+X`, `-X`; D20 uses `F1` through `F20`.

## DiceDie3D

`DiceDie3D` is the physical die. It stores face definitions and renders face visuals, but it does not decide results when registered with a roll box.

When a die is added to a `DiceRollBox3D`, the box can copy its default roll impulse and initial spin settings onto the die. Shape, body material, face art, and collision smoothing belong to the die itself or to a `DiceDieDefinition3D` resource.

Visual and collision exports:

- `die_shape: int` D6 or D20
- `edge_length: float`
- `body_shape: int`
- `body_material: Material`
- `body_color: Color`
- `body_roughness: float`
- `body_specular: float`
- `body_clearcoat: float`
- `body_clearcoat_roughness: float`
- `side_smoothing: float` collision margin tuning for the simple physics box
- `side_smoothing_segments: int` reserved for future generated rounded visuals

`body_shape` supports `SHARP` and `ROUNDED`. For D6, `SHARP` generates a plain `BoxMesh` cube and `ROUNDED` uses the bundled `res://addons/dice_3d/assets/meshes/d6_rounded.tres` body mesh. D20 currently uses a generated sharp polyhedral `ArrayMesh` body and convex collision shape. v1 intentionally does not accept arbitrary custom body meshes so face anchors, result detection, collision, and scale stay predictable. `edge_length` scales the visible mesh and the collision shape together.

When `body_material` is empty, the die creates a `StandardMaterial3D` from `body_color`, `body_roughness`, `body_specular`, `body_clearcoat`, and `body_clearcoat_roughness`. Lower roughness and higher specular/clearcoat values make the die reflect light more strongly. Assign `body_material` for full control over lighting and shading.

Important methods:

- `set_faces(faces: Array) -> void`
- `set_faces_by_slot(slot_faces: Dictionary) -> void`
- `set_face(slot, face: DiceFace3D) -> void`
- `get_face(slot) -> DiceFace3D`
- `get_face_slots() -> Array[StringName]`
- `get_face_count() -> int`
- `has_face_slot(slot: StringName) -> bool`
- `get_local_face_normal(slot: StringName) -> Vector3`
- `get_default_idle_slot() -> StringName`
- `roll(options: DiceRollOptions = null) -> void`
- `is_rolling() -> bool`
- `is_settled() -> bool`

D6 face slots:

- `+Y`
- `-Y`
- `+Z`
- `-Z`
- `+X`
- `-X`

Default D6 values are `[1, 6, 2, 5, 3, 4]`, so opposite sides sum to 7.

D20 face slots:

- `F1` through `F20`

## DiceDieShape3D

`DiceDieShape3D` is the internal public shape-data helper used by `DiceDie3D`, `DiceDieDefinition3D`, `DiceCinematicRoller3D`, and `DiceRollBox3D`. It centralizes the data that used to live as cube-only assumptions:

- face slot order
- local face normals
- default faces
- default idle/result slot
- visible body mesh creation
- collision shape creation
- face anchor transforms

Current shapes:

- `ShapeType.D6`
- `ShapeType.D20`

Current body styles:

- `BodyStyle.SHARP`
- `BodyStyle.ROUNDED`

This helper is intentionally simple for now. New polyhedral dice should extend this shape layer first, then the cinematic roller can align and present the new face normals without special-casing each die type.

## DiceFace3D

`DiceFace3D` is a resource that defines one die face.

Fields:

- `value: int`
- `face_id: StringName`
- `display_name: String`
- `texture: Texture2D`
- `material: Material`
- `decoration_mesh: Mesh`
- `decoration_scene: PackedScene`
- `metadata: Dictionary`

`face_id` is the stable gameplay identifier. Texture, mesh, and scene names are convenience data exposed through `DiceRollResult`.

Static helpers include `new_face(...)`, `numbered_d6()`, and `numbered_faces(count)`. `get_asset_path()` and `get_asset_name()` expose the assigned texture, material, decoration mesh, or decoration scene resource names for result UI.

## DiceRollResult

Roll results are structured objects with:

- `die`
- `roll_box` physics source, or `null` for cinematic rolls
- `face`
- `value`
- `face_id`
- `display_name`
- `asset_path`
- `asset_name`
- `top_normal`
- `gravity_direction`
- `flatness`
- `is_flat`
- `reroll_count`

`gravity_direction` is the final world-space gravity direction derived from the roll box's `bottom_side`.
`flatness` is the winning face normal's dot product against the box up direction. `is_flat` compares that score to `flat_result_threshold`. If `reroll_unflat_results` is enabled, the box rerolls unflat results until `max_unflat_rerolls` is reached.

## DiceRollOptions

Use `DiceRollOptions` to override one roll without changing die defaults.

- `reset_before_roll`
- `use_spawn_position`
- `spawn_position`
- `randomize_rotation`
- `impulse`
- `torque`

Zero `impulse` uses the roll box's center-aimed launch when `roll_toward_center` is enabled, otherwise it uses the die's random roll range. Zero `torque` uses the die's random spin range.
