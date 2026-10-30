class_name Pedestrian
extends Node2D
## Morador caminhando pela calçada. Às vezes entra em estabelecimentos e
## sai algum tempo depois.

const SKINS := [Color("f9d3b4"), Color("e8b48f"), Color("c68863"), Color("8d5a3b"), Color("5d3a25")]
const SHIRTS := [Color("e53935"), Color("1e88e5"), Color("43a047"), Color("fdd835"), Color("8e24aa"), Color("fb8c00"), Color("00acc1"), Color("f06292"), Color("eceff1")]
const PANTS := [Color("37474f"), Color("1a237e"), Color("5d4037"), Color("455a64"), Color("263238")]
const HAIRS := [Color("212121"), Color("4e342e"), Color("8d6e63"), Color("fbc02d"), Color("bf360c"), Color("9e9e9e")]

enum State { WALK, ENTERING, INSIDE, EXITING }

var dir := 1.0
var speed := 40.0
var phase := 0.0
var frame := 0
var skin: Color
var shirt: Color
var pants: Color
var hair: Color
var long_hair := false
var has_bag := false
var state := State.WALK
var timer := 0.0
var cooldown := 0.0


func randomize_look(rng: RandomNumberGenerator) -> void:
	skin = SKINS[rng.randi() % SKINS.size()]
	shirt = SHIRTS[rng.randi() % SHIRTS.size()]
	pants = PANTS[rng.randi() % PANTS.size()]
	hair = HAIRS[rng.randi() % HAIRS.size()]
	long_hair = rng.randf() < 0.45
	has_bag = rng.randf() < 0.25
	speed = rng.randf_range(28, 50)
	dir = 1.0 if rng.randf() < 0.5 else -1.0
	scale = Vector2(dir, 1) * rng.randf_range(0.92, 1.08)
	state = State.WALK
	modulate.a = 1.0
	visible = true
	cooldown = rng.randf_range(2, 6)
	queue_redraw()


func step(delta: float) -> void:
	match state:
		State.WALK:
			position.x += dir * speed * delta
			phase += delta * speed * 0.16
			cooldown -= delta
			var f := int(phase) % 4
			if f != frame:
				frame = f
				queue_redraw()
		State.ENTERING:
			timer -= delta
			modulate.a = clampf(timer / 0.35, 0.0, 1.0)
			position.y -= delta * 10.0
			if timer <= 0.0:
				state = State.INSIDE
				visible = false
				timer = randf_range(3.0, 9.0)
		State.INSIDE:
			timer -= delta
			if timer <= 0.0:
				state = State.EXITING
				visible = true
				timer = 0.35
				dir = 1.0 if randf() < 0.5 else -1.0
				scale.x = absf(scale.x) * dir
		State.EXITING:
			timer -= delta
			modulate.a = 1.0 - clampf(timer / 0.35, 0.0, 1.0)
			position.y += delta * 10.0
			if timer <= 0.0:
				state = State.WALK
				modulate.a = 1.0
				cooldown = randf_range(6, 14)


func enter_building(door_y: float) -> void:
	state = State.ENTERING
	timer = 0.35
	position.y = door_y


func can_enter() -> bool:
	return state == State.WALK and cooldown <= 0.0


func _draw() -> void:
	var out := BuildingArt.OUT
	var swing: float = [0.0, 5.0, 0.0, -5.0][frame]
	# pernas
	draw_line(Vector2(-2, -14), Vector2(-2 + swing, 0), out, 5.0)
	draw_line(Vector2(2, -14), Vector2(2 - swing, 0), out, 5.0)
	draw_line(Vector2(-2, -14), Vector2(-2 + swing, -1), pants, 3.0)
	draw_line(Vector2(2, -14), Vector2(2 - swing, -1), pants, 3.0)
	# braço de trás
	draw_line(Vector2(0, -26), Vector2(-swing * 0.8, -16), skin.darkened(0.2), 3.0)
	# corpo
	draw_rect(Rect2(-6.5, -30.5, 13, 18), out)
	draw_rect(Rect2(-5, -29, 10, 15), shirt)
	# braço da frente
	draw_line(Vector2(0, -26), Vector2(swing * 0.8 + 1, -16), out, 4.5)
	draw_line(Vector2(0, -26), Vector2(swing * 0.8 + 1, -16.5), skin, 2.5)
	if has_bag:
		draw_rect(Rect2(swing * 0.8 - 3, -17, 8, 9), out)
		draw_rect(Rect2(swing * 0.8 - 2, -16, 6, 7), Color("ffcc80"))
	# cabeça
	draw_circle(Vector2(0, -37), 7.5, out)
	draw_circle(Vector2(0, -37), 6, skin)
	draw_arc(Vector2(0, -38), 6.2, PI * 1.05, TAU * 0.98, 10, hair, 4.0)
	if long_hair:
		draw_line(Vector2(-5, -38), Vector2(-6, -30), hair, 4.0)
	draw_circle(Vector2(3, -37), 1.2, out)
