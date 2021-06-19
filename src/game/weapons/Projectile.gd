extends Area2D
class_name Projectile


var shooter = null
var lifetime = 0.0
var speed = 0
var direction = Vector2(0, 0)
var damage = 0
var own_goal_timer = 0.0


func load_stats(stats: Dictionary):
	speed = stats.speed
	damage = stats.damage
	lifetime = stats.lifetime


func _ready():
	connect("body_entered", self, "_on_body_entered")



func _physics_process(delta):
	lifetime -= delta
	own_goal_timer += delta
	position += speed * direction * delta
	if lifetime < 0.2:
		modulate.a = min(lifetime / 0.2, 0.9) + 0.1
	if lifetime < 0.0:
		get_parent().remove_child(self)
		queue_free()


func _on_body_entered(body):
	if GameFlow.is_ship(body) or GameFlow.is_asteroid(body) or GameFlow.is_container(body):
		if body == shooter:
			if own_goal_timer < 0.5:
				return
		GameFlow.hit_emitter.spawn_hit(position)
		body.take_damage(damage)
		get_parent().remove_child(self)
		queue_free()

