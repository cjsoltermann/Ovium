extends Node3D

var character_scene := preload("res://character.tscn")
@onready var player_root := $Players
@onready var body_root := $Bodies
@onready var cows := $Bodies/Cows
@onready var aliens := $Bodies/Aliens

@onready var planets: Node3D = $Planets

var swarm_center := Vector3.ZERO
var swarm_velocity := Vector3.ZERO

func _physics_process(delta):
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	for alien in aliens.get_children():
		a += alien.position
		b += alien.velocity
	swarm_center = a / aliens.get_child_count()
	swarm_velocity = b / aliens.get_child_count()

func get_swarm_velocity(pos: Vector3, cur_velocity: Vector3) -> Vector3:
	var separation := Vector3.ZERO
	var cohesion := Vector3.ZERO
	var alignment := Vector3.ZERO
	
	for alien in aliens.get_children():
		var diff = alien.position - pos
		if diff.length_squared() < 200:
			separation = separation - diff
	
	cohesion = swarm_center - pos
	alignment = swarm_velocity - cur_velocity
	
	var ret = cur_velocity + (separation + (cohesion / 10.0) + (alignment / 8.0)) / 10.0
	
	var max_x = 150
	var max_y = 150
	var max_z = 150
	var correction = 20
	
	if pos.x > max_x:
		ret.x = ret.x - correction
	if pos.x < -max_x:
		ret.x = ret.x + correction
	if pos.y > max_y:
		ret.y = ret.y - correction
	if pos.y < -max_y:
		ret.y = ret.y + correction
	if pos.z > max_z:
		ret.z = ret.z - correction
	if pos.z < -max_z:
		ret.z = ret.z + correction
	
	return ret

func get_gravity(pos: Vector3) -> Vector3:
	#var planet := get_closest_body(pos)
	#var dir := planet.position - pos
	#return dir.normalized() * (10 * planet.mass / dir.length_squared())
	var ret := Vector3.ZERO
	for planet: Planet in planets.get_children():
		var dir := planet.position - pos
		ret += dir.normalized() * (10 * planet.mass / (dir.length_squared()))
	return ret
		
func get_closest_body(pos: Vector3) -> Node3D:
	var dist := INF
	if planets.get_child_count() > 0:
		var ret := planets.get_child(0)
		for planet: Planet in planets.get_children():
			var d := (planet.position - pos).length_squared()
			if (d < dist):
				dist = d
				ret = planet
		return ret
	else:
		return null

func get_closest_target(pos: Vector3) -> Node3D:
	var dist := INF
	if cows.get_child_count() > 0:
		var ret := cows.get_child(0)
		for cow: Node3D in cows.get_children():
			var d := (cow.position - pos).length_squared()
			if (d < dist):
				dist = d
				ret = cow
		return ret
	else:
		return null

func _ready():
	var character = character_scene.instantiate()
	character.get_gravity = get_gravity
	character.get_closest_body = get_closest_body
	player_root.add_child(character, true)

	for body_group in body_root.get_children():
		for body in body_group.get_children():
			if ("get_gravity" in body && "get_closest_body" in body):
				body.get_gravity = get_gravity
				body.get_closest_body = get_closest_body
				
	for alien in aliens.get_children():
		alien.get_closest_target = get_closest_target
		alien.get_swarm_velocity = get_swarm_velocity
