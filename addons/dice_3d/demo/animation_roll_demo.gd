extends Node3D


func _ready() -> void:
	_setup_sky()


func _setup_sky() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.13, 0.31, 0.58)
	sky_material.sky_horizon_color = Color(0.72, 0.82, 0.96)
	sky_material.ground_bottom_color = Color(0.14, 0.17, 0.19)
	sky_material.ground_horizon_color = Color(0.38, 0.43, 0.45)

	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.65

	var world_environment := WorldEnvironment.new()
	world_environment.name = "SkyEnvironment"
	world_environment.environment = environment
	add_child(world_environment)
