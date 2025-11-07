Extends Control

[gd_scene load_steps=2 format=3]
[node name="WeatherParticles" type="GPUParticles2D"]
amount = 200
lifetime = 1.2
one_shot = false
speed_scale = 1.0
texture = null
gravity = Vector2(0, 800)
direction = Vector2(0, 1)
spread = 10.0
process_material = SubResource("ParticleMaterial")

[sub_resource type="ParticleProcessMaterial" id="ParticleMaterial"]
gravity = Vector3(0, 1200, 0)
initial_velocity_min = 250.0
initial_velocity_max = 300.0
direction = Vector3(0, 1, 0)
scale_min = 0.2
scale_max = 0.4
angle_min = 80
angle_max = 100
color = Color(1, 1, 1, 0.6)
