extends Node2D

@export var fog_color := Color(0.8, 0.8, 0.8, 0.1)
@export var transition_speed := 0.2  # how fast weather blends to target
@export var particle_scene := preload("res://effects/WeatherParticles.tscn")

var current_intensity := 0.0
var target_intensity := 0.0
var current_stage := "clear"

var rain_particles: GPUParticles2D
var fog_rect: ColorRect

func _ready():
	# Screen-space overlay setup
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_as_relative = false
	set_process(true)

	# --- Rain Particles ---
	rain_particles = particle_scene.instantiate()
	add_child(rain_particles)
	rain_particles.emitting = false
	rain_particles.z_index = 1

	# --- Fog Overlay ---
	fog_rect = ColorRect.new()
	fog_rect.color = fog_color
	fog_rect.size = get_viewport_rect().size
	fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_rect.z_index = 0
	add_child(fog_rect)

func _process(delta):
	# Follow viewport center (keeps overlay fixed regardless of pan)
	var vp := get_viewport().get_visible_rect().size
	global_position = vp * 0.5

	# Smooth blend
	current_intensity = lerp(current_intensity, target_intensity, delta * transition_speed)

	# Apply rain emission
	rain_particles.emitting = current_intensity > 0.05
	rain_particles.amount = int(200 * current_intensity)
	rain_particles.modulate = Color(1, 1, 1, current_intensity)

	# Apply fog alpha
	var fog_alpha = clamp(current_intensity * 0.25, 0, 0.35)
	fog_rect.color.a = fog_alpha

func set_weather(stage: String):
	current_stage = stage
	match stage:
		"clear": target_intensity = 0.0
		"sprinkle_light": target_intensity = 0.2
		"sprinkle_heavy": target_intensity = 0.35
		"rain_light": target_intensity = 0.55
		"rain_heavy": target_intensity = 0.75
		"downpour": target_intensity = 1.0
		"snow_light": target_intensity = 0.4
		"snow_heavy": target_intensity = 0.7
		"fog_dense": target_intensity = 0.6
