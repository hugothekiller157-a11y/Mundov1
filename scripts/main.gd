extends Node3D

var player: CharacterBody3D
var camera: Camera3D

var speed := 6.0
var gravity := 18.0
var jump_force := 7.0

func _ready():
	create_environment()
	create_world()
	create_player()

func create_environment():
	var environment := WorldEnvironment.new()
	var env := Environment.new()

	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.38, 0.62, 0.88)

	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 1.0)
	env.ambient_light_energy = 0.8

	environment.environment = env
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true

	add_child(sun)

func create_world():
	# Chão
	var ground := StaticBody3D.new()
	ground.position = Vector3(0, -1, 0)
	add_child(ground)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()

	box.size = Vector3(80, 2, 80)
	mesh.mesh = box
	mesh.material_override = create_material(
		Color(0.30, 0.60, 0.25)
	)

	ground.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()

	shape.size = Vector3(80, 2, 80)
	collision.shape = shape

	ground.add_child(collision)

	# Árvores
	create_tree(Vector3(-12, 0, -8))
	create_tree(Vector3(10, 0, -15))
	create_tree(Vector3(20, 0, 5))
	create_tree(Vector3(-20, 0, 12))

	# Pedras
	create_rock(Vector3(5, 0, 5))
	create_rock(Vector3(-7, 0, 10))
	create_rock(Vector3(15, 0, 15))

func create_tree(position: Vector3):
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()

	trunk_mesh.top_radius = 0.35
	trunk_mesh.bottom_radius = 0.45
	trunk_mesh.height = 3.5

	trunk.mesh = trunk_mesh
	trunk.position = position + Vector3(0, 1.75, 0)
	trunk.material_override = create_material(
		Color(0.38, 0.20, 0.08)
	)

	add_child(trunk)

	var leaves := MeshInstance3D.new()
	var leaves_mesh := SphereMesh.new()

	leaves_mesh.radius = 2.2
	leaves_mesh.height = 4.0

	leaves.mesh = leaves_mesh
	leaves.position = position + Vector3(0, 4.2, 0)
	leaves.material_override = create_material(
		Color(0.10, 0.48, 0.18)
	)

	add_child(leaves)

func create_rock(position: Vector3):
	var rock := MeshInstance3D.new()
	var rock_mesh := SphereMesh.new()

	rock_mesh.radius = 1.0
	rock_mesh.height = 1.6

	rock.mesh = rock_mesh
	rock.scale = Vector3(1.4, 0.7, 1.1)
	rock.position = position + Vector3(0, 0.6, 0)

	rock.material_override = create_material(
		Color(0.40, 0.43, 0.45)
	)

	add_child(rock)

func create_player():
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 2, 8)

	add_child(player)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()

	body_mesh.radius = 0.45
	body_mesh.height = 1.8

	body.mesh = body_mesh
	body.position.y = 0.9
	body.material_override = create_material(
		Color(0.15, 0.35, 0.75)
	)

	player.add_child(body)

	var collision := CollisionShape3D.new()
	var collision_shape := CapsuleShape3D.new()

	collision_shape.radius = 0.45
	collision_shape.height = 1.8

	collision.shape = collision_shape
	collision.position.y = 0.9

	player.add_child(collision)

	camera = Camera3D.new()

	camera.position = Vector3(0, 4, 7)
	camera.rotation_degrees = Vector3(-12, 180, 0)

	player.add_child(camera)

	camera.current = true

func create_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()

	material.albedo_color = color
	material.roughness = 0.85

	return material

func _physics_process(delta):
	if player == null:
		return

	var input := Vector2(
		Input.get_action_strength("ui_right") -
		Input.get_action_strength("ui_left"),

		Input.get_action_strength("ui_down") -
		Input.get_action_strength("ui_up")
	)

	var direction := Vector3(
		input.x,
		0,
		input.y
	)

	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed

	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		player.velocity.y = 0

	player.move_and_slide()

	camera.look_at(
		player.global_position + Vector3(0, 1, 0),
		Vector3.UP
	)
