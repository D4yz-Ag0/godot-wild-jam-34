extends Node2D
class_name Projectiles

onready var RailgunBulletScene = preload("res://src/game/bullets/RailgunBullet.tscn")
onready var HitEffectScene = preload("res://src/game/HitEmitter.tscn")


func _ready():
	pass

func _on_projectile_fired(projectile_data):
	print("Projectile shot!")
	print(projectile_data)
	if projectile_data.type == "RAILGUN":
		shoot_railgun_bullet(projectile_data)


func shoot_railgun_bullet(projectile_data):
	var properties = projectile_data.get("properties", {})
	var source = projectile_data.source
	var target = projectile_data.target
	var railgun_bullet_instance = RailgunBulletScene.instance()
	add_child(railgun_bullet_instance)
	railgun_bullet_instance.position = source.global_position
	railgun_bullet_instance.rotation = source.global_rotation + PI

	if target == null:
		railgun_bullet_instance.set_size(properties.distance)
	else:
		var hit_emitter_instance = HitEffectScene.instance()
		add_child(hit_emitter_instance)
		hit_emitter_instance.position = projectile_data.hit_point
		hit_emitter_instance.emitting = true

		# for not overshooting targets
		railgun_bullet_instance.set_size(projectile_data.hit_point.distance_to(source.global_position))

