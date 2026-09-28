extends Node3D

const WORLD_SIZE: float = 150.0
const PLAYER_SPEED: float = 5.2
const SPRINT_SPEED: float = 8.0
const GRAVITY: float = 18.0
var player: CharacterBody3D
var camera: Camera3D
var sun: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var life: float = 100.0
var stamina: float = 100.0
var wood: int = 0
var stone: int = 0
var elapsed: float = 0.0
var sprinting: bool = false
var move_input: Vector2 = Vector2.ZERO
var hud: Label

func _ready() -> void:
    _setup_environment()
    _build_world()
    _build_player()
    _build_hud()
    _update_hud()

func _process(delta: float) -> void:
    elapsed += delta
    _animate_world()
    _update_hud()

func _physics_process(delta: float) -> void:
    if player == null: return
    var input_vec := move_input
    if input_vec.length() < 0.1:
        input_vec = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var dir := Vector3(input_vec.x, 0.0, input_vec.y)
    if dir.length() > 1.0: dir = dir.normalized()
    var speed := SPRINT_SPEED if sprinting and stamina > 1.0 else PLAYER_SPEED
    player.velocity.x = dir.x * speed
    player.velocity.z = dir.z * speed
    if not player.is_on_floor(): player.velocity.y -= GRAVITY * delta
    else: player.velocity.y = 0.0
    player.move_and_slide()
    if sprinting and dir.length() > 0.1: stamina = max(0.0, stamina - 16.0 * delta)
    else: stamina = min(100.0, stamina + 10.0 * delta)
    _follow_camera(delta)

func _setup_environment() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    sky_mat = ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color("#2478a8")
    sky_mat.sky_horizon_color = Color("#bfe4e9")
    sky_mat.ground_bottom_color = Color("#15252b")
    sky_mat.ground_horizon_color = Color("#8aa6a2")
    sky.material = sky_mat
    e.sky = sky
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_energy = 0.75
    e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    e.fog_enabled = true
    e.fog_light_color = Color("#b6d4d4")
    e.fog_light_energy = 0.45
    e.fog_density = 0.006
    env.environment = e
    add_child(env)
    sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48.0, -25.0, 0.0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)

func _mat(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    return m

func _mesh_box(size: Vector3, material: Material) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.material_override = material
    return n

func _mesh_cylinder(radius: float, height: float, material: Material, sides: int = 16) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius * 0.94
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = sides
    n.mesh = mesh
    n.material_override = material
    return n

func _mesh_sphere(radius: float, material: Material) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 20
    mesh.rings = 10
    n.mesh = mesh
    n.material_override = material
    return n

func _build_world() -> void:
    var terrain := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(WORLD_SIZE, WORLD_SIZE)
    plane.subdivide_width = 24
    plane.subdivide_depth = 24
    terrain.mesh = plane
    terrain.material_override = _mat(Color("#6e8f52"), 1.0)
    add_child(terrain)
    var body := StaticBody3D.new()
    body.position.y = -0.5
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(WORLD_SIZE, 1.0, WORLD_SIZE)
    col.shape = shape
    body.add_child(col)
    add_child(body)
    var water := MeshInstance3D.new()
    var water_mesh := PlaneMesh.new()
    water_mesh.size = Vector2(120.0, 120.0)
    water.mesh = water_mesh
    water.position = Vector3(28.0, -0.8, 18.0)
    var water_mat := _mat(Color(0.05, 0.38, 0.58, 0.78), 0.12)
    water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    water.material_override = water_mat
    add_child(water)
    _add_mountains()
    _add_trees()
    _add_rocks()
    _add_grass()
    _add_camp()

func _add_mountains() -> void:
    for i in range(10):
        var a := float(i) / 10.0 * TAU
        var r := 62.0
        var mountain := _mesh_sphere(13.0 + float(i % 3) * 3.0, _mat(Color("#536d55"), 1.0))
        mountain.position = Vector3(cos(a) * r, 5.0, sin(a) * r)
        mountain.scale = Vector3(1.5, 1.2 + float(i % 2) * 0.5, 1.0)
        add_child(mountain)

func _add_trees() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 5050
    for i in range(52):
        var a := rng.randf_range(0.0, TAU)
        var r := rng.randf_range(10.0, 62.0)
        var p := Vector3(cos(a) * r, 0.0, sin(a) * r)
        if p.distance_to(Vector3(0, 0, 4)) < 10.0: continue
        _tree(p, rng.randf_range(0.8, 1.45))

func _tree(p: Vector3, s: float) -> void:
    var root := Node3D.new()
    root.position = p
    root.scale = Vector3.ONE * s
    var trunk := _mesh_cylinder(0.42, 4.0, _mat(Color("#60462f"), 1.0), 14)
    trunk.position.y = 2.0
    root.add_child(trunk)
    var leaf_mat := _mat(Color("#2f7043"), 0.95)
    var c1 := _mesh_sphere(2.2, leaf_mat)
    c1.position = Vector3(0, 4.8, 0)
    c1.scale = Vector3(1.15, 1.0, 1.15)
    root.add_child(c1)
    var c2 := _mesh_sphere(1.65, leaf_mat)
    c2.position = Vector3(1.0, 5.8, 0.3)
    root.add_child(c2)
    var c3 := _mesh_sphere(1.55, leaf_mat)
    c3.position = Vector3(-1.0, 5.5, -0.2)
    root.add_child(c3)
    add_child(root)

func _add_rocks() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 7788
    for i in range(42):
        var p := Vector3(rng.randf_range(-58.0, 58.0), 0.5, rng.randf_range(-58.0, 58.0))
        if p.distance_to(Vector3(0, 0, 4)) < 8.0: continue
        var rock := _mesh_sphere(rng.randf_range(0.45, 1.5), _mat(Color("#777d78"), 0.96))
        rock.position = p
        rock.scale = Vector3(1.5, 0.75, 1.15)
        rock.rotation.y = rng.randf_range(0.0, TAU)
        add_child(rock)

func _add_grass() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 1212
    for i in range(110):
        var p := Vector3(rng.randf_range(-60.0, 60.0), 0.0, rng.randf_range(-60.0, 60.0))
        var h := rng.randf_range(0.25, 0.55)
        var blade := _mesh_box(Vector3(0.08, h, 0.08), _mat(Color("#4f8148"), 1.0))
        blade.position = p + Vector3(0, h / 2.0, 0)
        blade.rotation.y = rng.randf_range(0.0, TAU)
        add_child(blade)

func _add_camp() -> void:
    var camp := Node3D.new()
    camp.position = Vector3(0, 0, 4)
    add_child(camp)
    for x in [-1.2, 0.0, 1.2]:
        var log := _mesh_cylinder(0.22, 2.8, _mat(Color("#70472b"), 1.0), 12)
        log.rotation_degrees = Vector3(0, 0, 90)
        log.position = Vector3(x, 0.3, 0)
        camp.add_child(log)
    var fire := OmniLight3D.new()
    fire.position = Vector3(0, 1.2, 0)
    fire.light_color = Color("#ff9b45")
    fire.light_energy = 2.4
    fire.omni_range = 9.0
    camp.add_child(fire)
    var flame := _mesh_sphere(0.65, _mat(Color("#ffb13b"), 0.35))
    flame.position = Vector3(0, 1.0, 0)
    camp.add_child(flame)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.position = Vector3(0, 1.4, 12)
    add_child(player)
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    player.add_child(collision)
    var body := _mesh_cylinder(0.48, 1.15, _mat(Color("#b86d45"), 0.85), 20)
    body.position.y = 1.0
    player.add_child(body)
    var shirt := _mesh_cylinder(0.52, 0.72, _mat(Color("#2d4f63"), 0.9), 20)
    shirt.position.y = 1.15
    player.add_child(shirt)
    var head := _mesh_sphere(0.38, _mat(Color("#d99b72"), 0.85))
    head.position.y = 2.05
    player.add_child(head)
    var hair := _mesh_sphere(0.39, _mat(Color("#38291f"), 1.0))
    hair.position = Vector3(0, 2.17, -0.02)
    hair.scale = Vector3(1.0, 0.55, 1.0)
    player.add_child(hair)
    var backpack := _mesh_box(Vector3(0.65, 0.8, 0.28), _mat(Color("#514936"), 1.0))
    backpack.position = Vector3(0, 1.2, 0.48)
    player.add_child(backpack)
    camera = Camera3D.new()
    camera.current = true
    camera.position = Vector3(0, 4.0, 7.5)
    add_child(camera)

func _follow_camera(delta: float) -> void:
    var target := player.global_position + Vector3(0, 1.3, 0)
    var desired := target + Vector3(0, 4.2, 7.8)
    camera.global_position = camera.global_position.lerp(desired, min(1.0, delta * 5.0))
    camera.look_at(target, Vector3.UP)

func _animate_world() -> void:
    if sun == null: return
    sun.rotation_degrees.x = -42.0 + sin(elapsed * 0.035) * 24.0
    sun.rotation_degrees.y = -25.0 + elapsed * 0.4
    var daylight := 0.65 + 0.35 * sin(elapsed * 0.035)
    sun.light_energy = 0.65 + daylight * 0.75
    sky_mat.sky_top_color = Color("#1f5c88").lerp(Color("#65b8d6"), daylight)
    sky_mat.sky_horizon_color = Color("#405a73").lerp(Color("#d2eadf"), daylight)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := ColorRect.new()
    panel.color = Color(0.02, 0.04, 0.05, 0.62)
    panel.position = Vector2(24, 22)
    panel.size = Vector2(350, 120)
    layer.add_child(panel)
    hud = Label.new()
    hud.position = Vector2(42, 35)
    hud.add_theme_font_size_override("font_size", 22)
    layer.add_child(hud)
    var title := Label.new()
    title.text = "MUNDO V1  •  V5.0"
    title.position = Vector2(30, 655)
    title.add_theme_font_size_override("font_size", 24)
    layer.add_child(title)
    var hint := Label.new()
    hint.text = "Explore • Corra • Sobreviva"
    hint.position = Vector2(30, 690)
    hint.add_theme_font_size_override("font_size", 16)
    layer.add_child(hint)
    var status := Label.new()
    status.text = "SOBREVIVÊNCIA"
    status.position = Vector2(1040, 30)
    status.add_theme_font_size_override("font_size", 20)
    layer.add_child(status)

func _update_hud() -> void:
    if hud == null: return
    var hour := fmod(8.0 + elapsed * 0.035, 24.0)
    hud.text = "VIDA  %3d\nENERGIA  %3d\nMADEIRA  %02d   PEDRA  %02d\nHORA  %02d:%02d" % [int(life), int(stamina), wood, stone, int(hour), int(fmod(hour * 60.0, 60.0))]
