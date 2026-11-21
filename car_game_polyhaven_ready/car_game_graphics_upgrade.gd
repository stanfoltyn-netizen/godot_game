extends Node
# ONE-FILE 3D car game for Godot 4.x (works with GodotPhysics AND Jolt; no VehicleBody3D).
# SETUP: new scene (any root node) -> attach this script -> F5.
#
# CONTROLS: W/Up gas | S/Down brake + reverse | A/D or Left/Right steer
#           Space handbrake (drift) | C camera | L headlights | R respawn
#
# Physics: a sphere RigidBody3D carries the car; engine, 6-speed gearbox, brakes,
# tyre grip limit (with downforce), aero drag and drifting are simulated in code.

const N := 128                       # track segments
const ROAD_W := 16.0
const WHEEL_R := 0.35
const WHEELBASE := 2.8
const MASS := 1200.0
const BALL_R := 0.8
const GEARS := [3.4, 2.3, 1.7, 1.3, 0.95, 0.68]
const FINAL := 3.7
const REV_RATIO := 3.4
const EFF := 0.9
const MAX_TORQUE := 1700.0
const IDLE := 900.0
const REDLINE := 7200.0
const MUSIC_RATE := 11025.0
const BPM := 124.0
const CHORDS := [[220.0, 261.63, 329.63], [174.61, 220.0, 261.63], [261.63, 329.63, 392.0], [196.0, 246.94, 293.66]]
const BASS_ROOTS := [55.0, 43.65, 65.41, 49.0]
const BASS_STEPS := [0, 3, 6, 8, 11, 14]
const TYRE_NAMES := ["SOFT", "MEDIUM", "HARD"]
const TYRE_GRIP := [1.08, 1.0, 0.93]
const TYRE_WEAR := [2.0, 1.0, 0.6]
const CARS := [
	{"name": "Street GT", "price": 0, "body": "gt", "ev": false, "fly": false, "mass": 1200.0, "kw": 330.0, "tf": 0.6, "turbo": false, "torque": 1.0, "gm": 1.0, "grip": 1.0, "df": 9000.0, "off": 0.55, "drag": 1.0, "latk": 14.0, "brk": 10.5, "snd": 30.0, "vol": 1.0, "saw": 0.1, "color": Color(0.78, 0.04, 0.05), "desc": "Balanced rear-wheel-drive sports car\n330 kW, 6-speed, ~330 km/h"},
	{"name": "Roadster EV", "price": 8000, "body": "roadster", "ev": true, "fly": true, "mass": 1350.0, "kw": 380.0, "tf": 0.62, "turbo": false, "torque": 1.0, "gm": 1.0, "grip": 1.0, "df": 9000.0, "off": 0.55, "drag": 0.9, "latk": 14.0, "brk": 10.5, "snd": 8.0, "vol": 0.5, "saw": 0.1, "color": Color(0.72, 0.76, 0.82), "desc": "Electric open-top roadster\nInstant torque. FLIGHT (F):\nSpace up, Ctrl down"},
	{"name": "Muscle V8", "price": 5000, "body": "muscle", "ev": false, "fly": false, "mass": 1650.0, "kw": 380.0, "tf": 0.55, "turbo": false, "torque": 1.45, "gm": 1.3, "grip": 0.9, "df": 12000.0, "off": 0.5, "drag": 1.25, "latk": 12.0, "brk": 9.5, "snd": 40.0, "vol": 1.3, "saw": 0.3, "color": Color(0.05, 0.2, 0.55), "desc": "Heavy, torquey, deep V8 rumble\nBig burnouts, loose rear end"},
	{"name": "Hypercar", "price": 30000, "body": "hyper", "ev": false, "fly": false, "mass": 1100.0, "kw": 700.0, "tf": 0.75, "turbo": true, "torque": 1.35, "gm": 0.9, "grip": 1.1, "df": 4500.0, "off": 0.45, "drag": 0.7, "latk": 18.0, "brk": 14.0, "snd": 14.0, "vol": 1.0, "saw": 0.25, "color": Color(1.0, 0.8, 0.05), "desc": "700 kW turbo, AWD, huge downforce\nBrutal grip and braking"},
	{"name": "Rally Hatch", "price": 6000, "body": "rally", "ev": false, "fly": false, "mass": 1250.0, "kw": 200.0, "tf": 0.9, "turbo": true, "torque": 1.0, "gm": 1.15, "grip": 1.05, "df": 11000.0, "off": 0.9, "drag": 1.2, "latk": 15.0, "brk": 11.0, "snd": 28.0, "vol": 1.0, "saw": 0.15, "color": Color(0.1, 0.35, 0.95), "desc": "Turbo AWD rally hatch\nKeeps grip on grass and in the wet"},
	{"name": "Drift King", "price": 12000, "body": "drift", "ev": false, "fly": false, "mass": 1250.0, "kw": 380.0, "tf": 0.6, "turbo": true, "torque": 1.3, "gm": 1.0, "grip": 1.2, "df": 9000.0, "off": 0.5, "drag": 1.0, "latk": 8.5, "brk": 10.5, "snd": 26.0, "vol": 1.1, "saw": 0.15, "color": Color(0.92, 0.2, 0.6), "desc": "Turbo, tuned for sideways action\nBig wing, neon underglow"},
	{"name": "Compact Hatch", "price": 1500, "body": "hatch", "ev": false, "fly": false, "mass": 950.0, "kw": 90.0, "tf": 0.55, "turbo": false, "torque": 0.55, "gm": 1.6, "grip": 0.95, "df": 14000.0, "off": 0.6, "drag": 1.6, "latk": 13.0, "brk": 9.5, "snd": 34.0, "vol": 0.8, "saw": 0.1, "color": Color(0.2, 0.7, 0.35), "desc": "Cheap, light and slow\n90 kW, ~200 km/h. Learn here"},
	{"name": "Trail Truck", "price": 7000, "body": "truck", "ev": false, "fly": false, "mass": 2300.0, "kw": 250.0, "tf": 0.8, "turbo": false, "torque": 1.6, "gm": 1.8, "grip": 0.85, "df": 14000.0, "off": 0.95, "drag": 2.0, "latk": 10.0, "brk": 8.5, "snd": 38.0, "vol": 1.2, "saw": 0.25, "color": Color(0.85, 0.45, 0.1), "desc": "Heavy 4x4 pickup, ~180 km/h\nAlmost no penalty off-road"},
	{"name": "Formula Racer", "price": 45000, "body": "formula", "ev": false, "fly": false, "mass": 750.0, "kw": 560.0, "tf": 0.7, "turbo": false, "torque": 1.2, "gm": 0.95, "grip": 1.5, "df": 3500.0, "off": 0.35, "drag": 0.6, "latk": 20.0, "brk": 16.0, "snd": 12.0, "vol": 1.0, "saw": 0.3, "color": Color(0.95, 0.95, 0.95), "desc": "Open-wheel racer, 750 kg\nInsane downforce and cornering"},
	{"name": "Sky Coupe", "price": 25000, "body": "sky", "ev": true, "fly": true, "mass": 1100.0, "kw": 300.0, "tf": 0.62, "turbo": false, "torque": 1.0, "gm": 1.0, "grip": 1.0, "df": 9000.0, "off": 0.55, "drag": 0.8, "latk": 14.0, "brk": 10.5, "snd": 6.0, "vol": 0.4, "saw": 0.1, "color": Color(0.3, 0.8, 1.0), "desc": "Winged electric hover coupe\nFLIGHT (F), neon wing tips"},
]

var center: Array[Vector3] = []
var dirs: Array[Vector3] = []
var ball: RigidBody3D
var car_vis: Node3D
var front_pivots: Array[Node3D] = []
var spin_nodes: Array[Node3D] = []
var lights: Array[SpotLight3D] = []
var smoke: Array[CPUParticles3D] = []
var cam: Camera3D
var hud: Hud
var brake_mat: StandardMaterial3D
var zero_fric: PhysicsMaterial

var yaw := 0.0
var steer := 0.0
var wheel_spin := 0.0
var gear := 1
var rpm_vis := IDLE
var shift_timer := 0.0
var cam_dir := Vector3(0, 0, -1)
var cam_mode := 0
var lap := 0
var lap_time := 0.0
var best_lap := -1.0
var last_lap := -1.0
var prev_idx := 0
var half_passed := false
var off_road := false
var throttle_vis := 0.0
var prev_fwd := 0.0
var a_long := 0.0
var pitch_vis := 0.0
var roll_vis := 0.0
var yaw_rate_vis := 0.0

var player: AudioStreamPlayer
var pb: AudioStreamGeneratorPlayback
var phase := 0.0
var spin_slip := false
var squeal_vis := 0.0
var wind_vis := 0.0
var skid_tick := 0
var nitro := 1.0
var nitro_on := false
var flames: Array[CPUParticles3D] = []
var nearest_pt := Vector3.ZERO
var cs: Dictionary = CARS[0]
var steer_wheel: Node3D
var env_ref: Environment
var sky_ref: ProceduralSkyMaterial
var sun_ref: DirectionalLight3D
var tod := 0.46
var prev_speed := 0.0
var impact_vis := 0.0
var spark_t := 0.0
var sparks: CPUParticles3D
var car_mass := 1200.0
var fuel := 1.0
var tires := 1.0
var brake_temp := 0.0
var car_hp := 100.0
var boost := 0.0
var bov_t := 0.0
var turbo_ph := 0.0
var manual := false
var wet := 0.0
var rain_on := false
var rain_node: CPUParticles3D
var asphalt_ref: StandardMaterial3D
var kerb_vis := 0.0
var eng_smoke: CPUParticles3D
var pit_btn: Button
var seg_len_a: Array[float] = []
var cum_len: Array[float] = []
var total_len := 0.0
var v_corner: Array[float] = []
var ais: Array[Dictionary] = []
var p_prog := 0.0
var prev_sp := 0.0
var race_pos := 1
var car_type := 0
var flying := false
var thrusters: Array[CPUParticles3D] = []
var fly_hold_y := 12.0
var money := 40000
var owned: Array[bool] = [true, false, false, false, false, false, false, false, false, false]
var shop_open := false
var shop_layer: CanvasLayer
var money_label: Label
var shop_buttons: Array[Button] = []
var shop_ang := 0.0
var earn_acc := 0.0
var music_on := true
var music_player: AudioStreamPlayer
var m_pb: AudioStreamGeneratorPlayback
var m_pos := 0
var m_ph_bass := 0.0
var m_ph_arp := 0.0
var m_ph_pad: Array[float] = [0.0, 0.0, 0.0]
var bld_pos: Array[Vector3] = []
var nitro_light: OmniLight3D
var skid_mesh: Mesh
var skid_mat: StandardMaterial3D
var skid_nodes: Array[MeshInstance3D] = []
var countdown := 3.0
var tunnel_on := false
var puddles: Array[Vector3] = []
var puddle_nodes: Array[MeshInstance3D] = []
var was_pud := false
var props: Array[RigidBody3D] = []
var prop_home: Array[Vector3] = []
var prop_hit: Array[bool] = []
var cones_hit := 0
var tyre_c := 1
var use_mph := false
var dust_node: CPUParticles3D
var boost_pads: Array[Vector3] = []
var pad_cd := 0.0
var pad_t := 0.0
var drift_pts := 0.0
var drift_combo := 1.0
var drift_gap := 0.0
var drift_bank := 0
var drift_bank_t := 0.0
var firework_t := 0.0
var next_fw := 0.0
var explode_t := 0.0
var broken_t := 0.0
var abs_on := true
var tc_on := false
var tire_temp := 0.3
var backfire_t := 0.0
var draft := 0.0
var lightning_t := 0.0
var next_bolt := 8.0
var locked := false
var finished := false
var finish_pos := 0
var race_laps := 3


func _ready() -> void:
	randomize()
	get_viewport().msaa_3d = Viewport.MSAA_8X
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	zero_fric = PhysicsMaterial.new()
	zero_fric.friction = 0.0
	zero_fric.bounce = 0.0
	build_track_data()
	build_environment()
	build_world()
	build_road()
	build_city()
	build_scenery()
	build_boost_pads()
	build_track_extras()
	build_features()
	build_ball()
	build_car_visual()
	make_sparks()
	make_rain()
	make_dust()
	build_ai()
	build_camera()
	build_hud()
	build_audio()
	reset_car(N - 1)
	build_shop()
	shop_open = false
	toggle_shop()


# ------------------------------------------------------------ helpers
func make_mat(color: Color, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m


func noise_mat(c1: Color, c2: Color, freq: float, tile: float, rough := 0.95) -> StandardMaterial3D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_octaves = 5
	var g := Gradient.new()
	g.set_color(0, c1)
	g.set_color(1, c2)
	var t := NoiseTexture2D.new()
	t.noise = n
	t.color_ramp = g
	t.width = 256
	t.height = 256
	t.seamless = true
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(tile, tile, tile)
	return m


# Optional real scanned PBR material from Poly Haven. The game remains playable
# without downloaded assets; these files replace the procedural fallback when present.
func apply_polyhaven_asphalt(mat: StandardMaterial3D) -> void:
	var root := "res://assets/polyhaven/asphalt_track/"
	var albedo_path := root + "asphalt_track_diff_2k.jpg"
	var normal_path := root + "asphalt_track_nor_gl_2k.jpg"
	var rough_path := root + "asphalt_track_rough_2k.jpg"
	var ao_path := root + "asphalt_track_ao_2k.jpg"
	if ResourceLoader.exists(albedo_path):
		mat.albedo_texture = load(albedo_path)
		mat.albedo_color = Color(0.82, 0.82, 0.82)
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
		mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
	if ResourceLoader.exists(normal_path):
		mat.normal_enabled = true
		mat.normal_texture = load(normal_path)
		mat.normal_scale = 0.7
	if ResourceLoader.exists(rough_path):
		mat.roughness_texture = load(rough_path)
		mat.roughness = 1.0
	if ResourceLoader.exists(ao_path):
		mat.ao_enabled = true
		mat.ao_texture = load(ao_path)
		mat.ao_light_affect = 0.35


func apply_polyhaven_hdri(env: Environment) -> void:
	# Optional 2K HDRI: put the downloaded file at this path in your Godot project.
	var hdri_path := "res://assets/polyhaven/sunset_jhbcentral_2k.hdr"
	if not ResourceLoader.exists(hdri_path):
		return
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = load(hdri_path)
	var hdri_sky := Sky.new()
	hdri_sky.sky_material = panorama
	env.background_mode = Environment.BG_SKY
	env.sky = hdri_sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG


func mesh_box(parent: Node, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func add_box(parent: Node, size: Vector3, xf: Transform3D, mat: Material, collide := false) -> Node3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	if collide:
		var body := StaticBody3D.new()
		body.transform = xf
		body.physics_material_override = zero_fric
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
		body.add_child(mi)
		parent.add_child(body)
		return body
	mi.transform = xf
	parent.add_child(mi)
	return mi


func nearest_on_track(p: Vector3) -> Vector2:
	var best_i := 0
	var best_d2 := INF
	for i in N:
		var a := center[i]
		var b := center[(i + 1) % N]
		var abx := b.x - a.x
		var abz := b.z - a.z
		var t := clampf(((p.x - a.x) * abx + (p.z - a.z) * abz) / (abx * abx + abz * abz), 0.0, 1.0)
		var dx := p.x - (a.x + abx * t)
		var dz := p.z - (a.z + abz * t)
		var d2 := dx * dx + dz * dz
		if d2 < best_d2:
			best_d2 = d2
			best_i = i
			nearest_pt = Vector3(a.x + abx * t, 0.0, a.z + abz * t)
	return Vector2(best_i, sqrt(best_d2))


# ------------------------------------------------------------ world
func build_track_data() -> void:
	for i in N:
		var t := float(i) / N * TAU
		var r := 1.0 + 0.2 * sin(2.0 * t + 0.6) + 0.1 * cos(3.0 * t) + 0.05 * sin(5.0 * t + 1.0)
		center.append(Vector3(cos(t) * 360.0 * r, 0.0, sin(t) * 230.0 * r))
	# fast S-bend chicane
	var base: Array[Vector3] = []
	for v in center:
		base.append(v)
	for i in N:
		if i >= 40 and i <= 56:
			var tg := (base[(i + 1) % N] - base[(i - 1 + N) % N]).normalized()
			center[i] += tg.cross(Vector3.UP).normalized() * 22.0 * sin(float(i - 40) / 16.0 * TAU)
	for i in N:
		dirs.append((center[(i + 1) % N] - center[i]).normalized())
	var kap: Array[float] = []
	for i in N:
		var l := center[i].distance_to(center[(i + 1) % N])
		seg_len_a.append(l)
		cum_len.append(total_len)
		total_len += l
	for i in N:
		var ang := acos(clampf(dirs[(i - 1 + N) % N].dot(dirs[i]), -1.0, 1.0))
		kap.append(ang / maxf(seg_len_a[i], 1.0))
	for i in N:
		var k := (kap[(i - 1 + N) % N] + kap[i] + kap[(i + 1) % N]) / 3.0
		v_corner.append(clampf(sqrt(14.0 / maxf(k, 0.0008)), 25.0, 95.0))


func build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.055, 0.12, 0.27)
	sky_mat.sky_horizon_color = Color(0.78, 0.48, 0.34)
	sky_mat.ground_horizon_color = Color(0.42, 0.38, 0.31)
	sky_mat.ground_bottom_color = Color(0.12, 0.16, 0.13)
	sky_mat.sun_angle_max = 18.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.55, 0.49)
	env.fog_density = 0.00032
	env.fog_sun_scatter = 0.45
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.15
	env.glow_bloom = 0.12
	env.ssao_enabled = true
	env.ssao_radius = 3.0
	env.ssao_intensity = 2.8
	env.ssr_enabled = true
	env.ssr_max_steps = 48
	env.ssr_fade_in = 0.15
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.16
	env.adjustment_saturation = 1.22
	env.adjustment_brightness = 1.02
	apply_polyhaven_hdri(env)
	env_ref = env
	sky_ref = sky_mat
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28, -32, 0)
	sun.light_energy = 1.85
	sun.light_color = Color(1.0, 0.78, 0.61)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 420.0
	sun.shadow_bias = 0.035
	sun.shadow_blur = 1.8
	sun_ref = sun
	add_child(sun)


func build_world() -> void:
	var grass := noise_mat(Color(0.12, 0.30, 0.09), Color(0.28, 0.5, 0.17), 0.02, 0.08, 1.0)
	add_box(self, Vector3(3000, 1, 3000), Transform3D(Basis(), Vector3(0, -0.55, 0)), grass, true)
	# distant hills
	var hill_mat := noise_mat(Color(0.2, 0.34, 0.2), Color(0.38, 0.45, 0.35), 0.01, 0.01, 1.0)
	var hill_mesh := SphereMesh.new()
	hill_mesh.radius = 1.0
	hill_mesh.height = 2.0
	for i in 28:
		var a := float(i) / 28.0 * TAU + randf_range(-0.1, 0.1)
		var d := randf_range(1250.0, 1450.0)
		var h := MeshInstance3D.new()
		h.mesh = hill_mesh
		h.material_override = hill_mat
		var s := randf_range(160.0, 300.0)
		h.scale = Vector3(s, s * randf_range(0.35, 0.7), s)
		h.position = Vector3(cos(a) * d, 0, sin(a) * d)
		add_child(h)


func build_road() -> void:
	var asphalt := noise_mat(Color(0.045, 0.05, 0.058), Color(0.16, 0.17, 0.18), 0.12, 0.18, 0.82)
	apply_polyhaven_asphalt(asphalt)
	asphalt_ref = asphalt
	var white := make_mat(Color(0.95, 0.95, 0.95), 0.8)
	var red := make_mat(Color(0.85, 0.08, 0.08), 0.8)
	var yellow := make_mat(Color(1, 0.78, 0.08), 0.72)
	var edge_white := make_mat(Color(0.88, 0.9, 0.88), 0.78)
	var runoff_a := make_mat(Color(0.16, 0.18, 0.2), 0.95)
	var runoff_b := make_mat(Color(0.72, 0.08, 0.06), 0.85)
	var bar_red := make_mat(Color(0.85, 0.1, 0.1), 0.5, 0.2)
	var bar_white := make_mat(Color(0.92, 0.92, 0.92), 0.5, 0.2)
	for i in N:
		var a := center[i]
		var b := center[(i + 1) % N]
		var mid := (a + b) * 0.5
		var seg_len := a.distance_to(b) + 2.5
		var basis := Basis.looking_at(dirs[i], Vector3.UP)
		var right := dirs[i].cross(Vector3.UP).normalized()
		add_box(self, Vector3(ROAD_W, 0.2, seg_len), Transform3D(basis, mid + Vector3(0, -0.1, 0)), asphalt, true)
		# Continuous painted edge lines and broad textured runoff beyond the kerbs.
		for side in [-1.0, 1.0]:
			add_box(self, Vector3(0.16, 0.025, seg_len), Transform3D(basis, mid + right * side * (ROAD_W * 0.5 - 1.55) + Vector3(0, 0.025, 0)), edge_white, false)
			var run_mat: Material = runoff_a if (i % 4) < 2 else runoff_b
			add_box(self, Vector3(3.4, 0.035, seg_len), Transform3D(basis, mid + right * side * (ROAD_W * 0.5 + 3.2) + Vector3(0, 0.01, 0)), run_mat, false)
		for side in [-1.0, 1.0]:
			var kerb: Material = red if i % 2 == 0 else white
			add_box(self, Vector3(0.9, 0.03, seg_len), Transform3D(basis, mid + right * side * (ROAD_W * 0.5 - 0.45) + Vector3(0, 0.015, 0)), kerb, false)
			add_box(self, Vector3(0.18, 0.025, seg_len), Transform3D(basis, mid + right * side * (ROAD_W * 0.5 - 1.3) + Vector3(0, 0.012, 0)), white, false)
			var bmat: Material = bar_red if i % 2 == 0 else bar_white
			add_box(self, Vector3(1.2, 2.2, seg_len + 4.0), Transform3D(basis, mid + right * side * (ROAD_W * 0.5 + 1.6) + Vector3(0, 1.1, 0)), bmat, true)
		if i % 2 == 0:
			add_box(self, Vector3(0.25, 0.02, 6.0), Transform3D(basis, mid + Vector3(0, 0.012, 0)), yellow, false)
	# start / finish line + gantry
	var sb := Basis.looking_at(dirs[0], Vector3.UP)
	var sr := dirs[0].cross(Vector3.UP).normalized()
	var cell := ROAD_W / 8.0
	var blk := make_mat(Color.BLACK, 0.8)
	for k in 8:
		for row in 2:
			var m: Material = blk if (k + row) % 2 == 0 else white
			var off := sr * (-ROAD_W * 0.5 + (k + 0.5) * cell) + dirs[0] * (row - 0.5) * 1.0
			add_box(self, Vector3(cell, 0.02, 1.0), Transform3D(sb, center[0] + off + Vector3(0, 0.018, 0)), m, false)
	var gantry := make_mat(Color(0.75, 0.08, 0.08), 0.4, 0.4)
	for side in [-1.0, 1.0]:
		add_box(self, Vector3(0.6, 7.0, 0.6), Transform3D(sb, center[0] + sr * side * (ROAD_W * 0.5 + 3.0) + Vector3(0, 3.5, 0)), gantry, true)
	add_box(self, Vector3(ROAD_W + 6.6, 1.2, 0.8), Transform3D(sb, center[0] + Vector3(0, 7.2, 0)), gantry, false)


func make_window_tex(lit: bool, grid: Array) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0) if lit else Color(0.1, 0.12, 0.16))
	for gx in 4:
		for gy in 4:
			var on: bool = grid[gx * 4 + gy]
			var c := Color(0.04, 0.06, 0.1)
			if lit:
				c = Color(1.0, 0.82, 0.5) if on else Color(0, 0, 0)
			elif on:
				c = Color(0.9, 0.75, 0.45)
			for px in 8:
				for py in 8:
					img.set_pixel(gx * 16 + 4 + px, gy * 16 + 4 + py, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func glow_mat(color: Color, energy := 4.0) -> StandardMaterial3D:
	var m := make_mat(color, 0.3)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


func build_city() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var grid: Array = []
	for i in 16:
		grid.append(rng.randf() < 0.55)
	var albedo := make_window_tex(false, grid)
	var emis := make_window_tex(true, grid)
	var tints := [Color(0.9, 0.9, 0.95), Color(0.7, 0.78, 0.95), Color(0.95, 0.82, 0.7), Color(0.78, 0.78, 0.8)]
	var mats: Array[StandardMaterial3D] = []
	for t in tints:
		var m := StandardMaterial3D.new()
		m.albedo_texture = albedo
		m.albedo_color = t
		m.emission_enabled = true
		m.emission_texture = emis
		m.emission_energy_multiplier = 1.6
		m.roughness = 0.7
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.1, 0.1, 0.1)
		mats.append(m)
	# skyscrapers / city blocks around the circuit
	for i in range(0, N, 2):
		var right := dirs[i].cross(Vector3.UP).normalized()
		for side in [-1.0, 1.0]:
			if randf() < 0.25:
				continue
			var p: Vector3 = center[i] + right * side * (ROAD_W * 0.5 + randf_range(26.0, 80.0))
			if nearest_on_track(p).y < 28.0:
				continue
			var w := randf_range(16.0, 34.0)
			var d := randf_range(16.0, 34.0)
			var h := randf_range(14.0, 85.0)
			var ang := atan2(-dirs[i].x, -dirs[i].z)
			var xf := Transform3D(Basis(Vector3.UP, ang), p + Vector3(0, h * 0.5, 0))
			add_box(self, Vector3(w, h, d), xf, mats[randi() % 4], true)
			bld_pos.append(p)
	# street lamps
	var lamp_mat := make_mat(Color(0.15, 0.15, 0.17), 0.5, 0.6)
	var lamp_glow := glow_mat(Color(1.0, 0.8, 0.45), 4.0)
	for i in range(0, N, 3):
		var right := dirs[i].cross(Vector3.UP).normalized()
		var basis := Basis.looking_at(dirs[i], Vector3.UP)
		for side in [-1.0, 1.0]:
			var base: Vector3 = center[i] + right * side * (ROAD_W * 0.5 + 4.0)
			add_box(self, Vector3(0.3, 9.0, 0.3), Transform3D(basis, base + Vector3(0, 4.5, 0)), lamp_mat, false)
			add_box(self, Vector3(2.4, 0.2, 0.3), Transform3D(basis, base - right * side * 1.1 + Vector3(0, 9.0, 0)), lamp_mat, false)
			add_box(self, Vector3(0.9, 0.2, 0.5), Transform3D(basis, base - right * side * 2.0 + Vector3(0, 8.85, 0)), lamp_glow, false)
	# neon arches over the road
	var arch_cols := [Color(0.1, 0.9, 1.0), Color(1.0, 0.1, 0.8), Color(0.2, 1.0, 0.3), Color(1.0, 0.55, 0.1)]
	for k in 4:
		var ai := (k * N / 4 + 6) % N
		var ar := dirs[ai].cross(Vector3.UP).normalized()
		var ab := Basis.looking_at(dirs[ai], Vector3.UP)
		var gm := glow_mat(arch_cols[k], 5.0)
		for side in [-1.0, 1.0]:
			add_box(self, Vector3(0.8, 9.0, 0.8), Transform3D(ab, center[ai] + ar * side * (ROAD_W * 0.5 + 3.8) + Vector3(0, 4.5, 0)), lamp_mat, true)
		add_box(self, Vector3(ROAD_W + 8.4, 0.7, 0.9), Transform3D(ab, center[ai] + Vector3(0, 9.2, 0)), gm, false)
		add_box(self, Vector3(ROAD_W + 8.4, 0.2, 0.3), Transform3D(ab, center[ai] + Vector3(0, 8.5, 0)), gm, false)
	# grandstand along the start straight
	var sb := Basis.looking_at(dirs[0], Vector3.UP)
	var sr := dirs[0].cross(Vector3.UP).normalized()
	var crowd := noise_mat(Color(0.9, 0.2, 0.2), Color(0.2, 0.4, 0.95), 0.4, 0.3)
	for r in 6:
		var hh := 1.2 + r * 1.0
		add_box(self, Vector3(2.2, hh, 70.0), Transform3D(sb, center[0] + sr * (ROAD_W * 0.5 + 12.0 + r * 2.2) + Vector3(0, hh * 0.5, 0)), crowd, true)
	var roof_mat := make_mat(Color(0.2, 0.2, 0.24), 0.5, 0.5)
	add_box(self, Vector3(12.0, 0.4, 72.0), Transform3D(sb, center[0] + sr * (ROAD_W * 0.5 + 19.0) + Vector3(0, 10.0, 0)), roof_mat, false)
	for zz in [-34.0, 34.0]:
		for oo in [13.0, 25.0]:
			add_box(self, Vector3(0.6, 10.0, 0.6), Transform3D(sb, center[0] + sr * (ROAD_W * 0.5 + oo) + dirs[0] * zz + Vector3(0, 5.0, 0)), roof_mat, false)


func build_scenery() -> void:
	var trunk_mat := make_mat(Color(0.32, 0.2, 0.1), 1.0)
	var leaf_mats := [
		make_mat(Color(0.08, 0.32, 0.1), 1.0),
		make_mat(Color(0.12, 0.40, 0.12), 1.0),
		make_mat(Color(0.2, 0.42, 0.1), 1.0),
	]
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.25
	trunk_mesh.bottom_radius = 0.38
	trunk_mesh.height = 4.0
	var foliage_mesh := SphereMesh.new()
	foliage_mesh.radius = 1.0
	foliage_mesh.height = 2.0
	foliage_mesh.radial_segments = 12
	foliage_mesh.rings = 8
	var placed := 0
	var tries := 0
	while placed < 80 and tries < 3000:
		tries += 1
		var p := Vector3(randf_range(-1100, 1100), 0, randf_range(-1100, 1100))
		if nearest_on_track(p).y < 30.0:
			continue
		var blocked := false
		for bp in bld_pos:
			if bp.distance_to(p) < 45.0:
				blocked = true
				break
		if blocked:
			continue
		var s := randf_range(0.8, 1.8)
		var tree := Node3D.new()
		tree.position = p
		tree.scale = Vector3(s, s, s)
		var t := MeshInstance3D.new()
		t.mesh = trunk_mesh
		t.material_override = trunk_mat
		t.position = Vector3(0, 2, 0)
		tree.add_child(t)
		for cluster in 5:
			var l := MeshInstance3D.new()
			l.mesh = foliage_mesh
			l.material_override = leaf_mats[randi() % leaf_mats.size()]
			var angle := float(cluster) / 5.0 * TAU
			var radius := 1.0 if cluster < 4 else 0.0
			l.position = Vector3(cos(angle) * radius, 5.0 + randf_range(-0.25, 1.1), sin(angle) * radius)
			var sc := randf_range(1.35, 1.8) if cluster < 4 else 1.65
			l.scale = Vector3(sc, randf_range(1.0, 1.35), sc)
			tree.add_child(l)
		add_child(tree)
		placed += 1


# ------------------------------------------------------------ car
func build_ball() -> void:
	ball = RigidBody3D.new()
	ball.mass = MASS
	ball.physics_material_override = zero_fric
	ball.axis_lock_angular_x = true
	ball.axis_lock_angular_y = true
	ball.axis_lock_angular_z = true
	ball.axis_lock_linear_y = true   # flat track: car can never hop or jump
	ball.continuous_cd = true
	ball.can_sleep = false
	ball.linear_damp = 0.0
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = BALL_R
	cs.shape = shape
	ball.add_child(cs)
	add_child(ball)


func make_smoke(pos: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 30
	p.lifetime = 1.1
	p.emitting = false
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 30.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.6
	p.gravity = Vector3(0, 0.8, 0)
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.6
	var m := SphereMesh.new()
	m.radius = 0.3
	m.height = 0.6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.85, 0.85, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material = mat
	p.mesh = m
	p.position = pos
	return p


func make_flame(pos: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 0.25
	p.emitting = false
	p.local_coords = false
	p.direction = Vector3(0, 0, 1)
	p.spread = 6.0
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 12.0
	p.gravity = Vector3.ZERO
	var m := SphereMesh.new()
	m.radius = 0.12
	m.height = 0.24
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.6, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.55, 1.0)
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material = mat
	p.mesh = m
	p.position = pos
	return p


func build_car_visual() -> void:
	if car_vis != null:
		car_vis.queue_free()
	spin_nodes.clear()
	front_pivots.clear()
	lights.clear()
	smoke.clear()
	flames.clear()
	thrusters.clear()
	car_vis = Node3D.new()
	add_child(car_vis)

	var paint := make_mat(cs["color"], 0.22, 0.7)
	paint.clearcoat_enabled = true
	paint.clearcoat = 1.0
	var glass := make_mat(Color(0.03, 0.05, 0.08), 0.03, 0.4)
	var black := make_mat(Color(0.03, 0.03, 0.03), 0.8)

	# rounded body (capsule laid along Z)
	var cap := CapsuleMesh.new()
	cap.radius = 0.5
	cap.height = 4.3
	var body := MeshInstance3D.new()
	body.mesh = cap
	body.material_override = paint
	body.rotation_degrees = Vector3(90, 0, 0)
	body.scale = Vector3(1.9, 1.0, 0.55)
	body.position = Vector3(0, 0.66, 0)
	car_vis.add_child(body)
	# cabin
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	var cabin := MeshInstance3D.new()
	cabin.mesh = sph
	cabin.material_override = glass
	cabin.scale = Vector3(1.5, 0.55, 2.3)
	cabin.position = Vector3(0, 0.98, 0.35)
	car_vis.add_child(cabin)
	# roof panel, spoiler, splitter, skirts
	var roof := MeshInstance3D.new()
	roof.mesh = sph
	roof.material_override = paint
	roof.scale = Vector3(1.4, 0.18, 1.5)
	roof.position = Vector3(0, 1.22, 0.45)
	car_vis.add_child(roof)
	mesh_box(car_vis, Vector3(1.8, 0.07, 0.45), Vector3(0, 1.28, 1.95), black)
	mesh_box(car_vis, Vector3(0.08, 0.3, 0.3), Vector3(0.6, 1.1, 1.95), black)
	mesh_box(car_vis, Vector3(0.08, 0.3, 0.3), Vector3(-0.6, 1.1, 1.95), black)
	mesh_box(car_vis, Vector3(1.9, 0.08, 0.35), Vector3(0, 0.36, -2.1), black)
	mesh_box(car_vis, Vector3(0.1, 0.12, 2.6), Vector3(0.95, 0.4, 0), black)
	mesh_box(car_vis, Vector3(0.1, 0.12, 2.6), Vector3(-0.95, 0.4, 0), black)
	if car_type != 0 and car_type != 5:
		for ch in car_vis.get_children():
			ch.queue_free()
		match car_type:
			1: build_roadster_body()
			2: build_muscle_body()
			3: build_hyper_body()
			4: build_rally_body()
			6: build_hatch_body()
			7: build_truck_body()
			8: build_formula_body()
			9: build_sky_body()
	elif car_type == 5:
		build_drift_extras()

	# Shared high-detail trim: grille, splitter, mirrors, vents and rear diffuser.
	var trim_mat := make_mat(Color(0.012, 0.016, 0.022), 0.38, 0.42)
	var carbon_mat := make_mat(Color(0.025, 0.03, 0.04), 0.32, 0.28)
	var chrome_mat := make_mat(Color(0.52, 0.57, 0.62), 0.22, 0.88)
	mesh_box(car_vis, Vector3(1.15, 0.22, 0.07), Vector3(0, 0.48, -2.12), trim_mat)
	mesh_box(car_vis, Vector3(1.95, 0.08, 0.42), Vector3(0, 0.34, -2.12), carbon_mat)
	mesh_box(car_vis, Vector3(1.45, 0.06, 0.18), Vector3(0, 0.43, 2.12), carbon_mat)
	for side in [-1.0, 1.0]:
		mesh_box(car_vis, Vector3(0.12, 0.11, 0.24), Vector3(side * 1.02, 1.0, -0.48), trim_mat)
		mesh_box(car_vis, Vector3(0.08, 0.055, 0.28), Vector3(side * 0.72, 0.55, -1.68), chrome_mat)
		mesh_box(car_vis, Vector3(0.12, 0.08, 0.55), Vector3(side * 0.78, 0.4, 1.72), trim_mat)
		mesh_box(car_vis, Vector3(0.1, 0.09, 0.42), Vector3(side * 0.55, 0.31, 2.12), trim_mat)
	var head_mat := make_mat(Color(1, 1, 0.9), 0.2)
	head_mat.emission_enabled = true
	head_mat.emission = Color(1, 1, 0.85)
	head_mat.emission_energy_multiplier = 2.5
	brake_mat = make_mat(Color(0.8, 0, 0), 0.3)
	brake_mat.emission_enabled = true
	brake_mat.emission = Color(1, 0, 0)
	brake_mat.emission_energy_multiplier = 0.8
	for side in [-1.0, 1.0]:
		mesh_box(car_vis, Vector3(0.45, 0.12, 0.08), Vector3(0.65 * side, 0.7, -2.1), head_mat)
		mesh_box(car_vis, Vector3(0.5, 0.1, 0.08), Vector3(0.65 * side, 0.75, 2.1), brake_mat)
		var sl := SpotLight3D.new()
		sl.position = Vector3(0.65 * side, 0.7, -2.15)
		sl.rotation_degrees.x = -3.0
		sl.spot_range = 70.0
		sl.spot_angle = 32.0
		sl.light_energy = 4.0
		car_vis.add_child(sl)
		lights.append(sl)

	for side in [-1.0, 1.0]:
		var fl := make_flame(Vector3(0.5 * side, 0.45, 2.2))
		car_vis.add_child(fl)
		flames.append(fl)
	nitro_light = OmniLight3D.new()
	nitro_light.position = Vector3(0, 0.6, 3.0)
	nitro_light.light_color = Color(0.3, 0.6, 1.0)
	nitro_light.light_energy = 4.0
	nitro_light.omni_range = 8.0
	nitro_light.visible = false
	car_vis.add_child(nitro_light)

	eng_smoke = make_smoke(Vector3(0, 0.9, -1.4))
	car_vis.add_child(eng_smoke)
	# dashboard + steering wheel (visible in cockpit view, turns with the front wheels)
	var dash_mat := make_mat(Color(0.04, 0.04, 0.05), 0.6)
	mesh_box(car_vis, Vector3(1.5, 0.14, 0.45), Vector3(0, 0.92, -0.62), dash_mat)
	var tilt := Node3D.new()
	tilt.position = Vector3(-0.35, 0.98, -0.3)
	tilt.rotation_degrees.x = -28.0
	car_vis.add_child(tilt)
	steer_wheel = Node3D.new()
	tilt.add_child(steer_wheel)
	var tor := TorusMesh.new()
	tor.inner_radius = 0.13
	tor.outer_radius = 0.17
	var tor_mi := MeshInstance3D.new()
	tor_mi.mesh = tor
	tor_mi.material_override = dash_mat
	tor_mi.rotation_degrees.x = 90.0
	steer_wheel.add_child(tor_mi)
	mesh_box(steer_wheel, Vector3(0.3, 0.03, 0.03), Vector3.ZERO, dash_mat)
	mesh_box(steer_wheel, Vector3(0.03, 0.15, 0.03), Vector3(0, -0.07, 0), dash_mat)

	var tire_mat := make_mat(Color(0.04, 0.04, 0.04), 0.9)
	var rim_mat := make_mat(Color(0.8, 0.8, 0.85), 0.2, 0.9)
	var tire_mesh := CylinderMesh.new()
	tire_mesh.top_radius = WHEEL_R
	tire_mesh.bottom_radius = WHEEL_R
	tire_mesh.height = 0.3
	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = 0.22
	rim_mesh.bottom_radius = 0.22
	rim_mesh.height = 0.32
	var defs := [
		[-0.95, -1.4, true], [0.95, -1.4, true],
		[-0.95, 1.4, false], [0.95, 1.4, false],
	]
	for d in defs:
		var pivot := Node3D.new()
		pivot.position = Vector3(d[0], WHEEL_R, d[1])
		car_vis.add_child(pivot)
		var spin := Node3D.new()
		pivot.add_child(spin)
		var tm := MeshInstance3D.new()
		tm.mesh = tire_mesh
		tm.material_override = tire_mat
		tm.rotation_degrees.z = 90.0
		spin.add_child(tm)
		var rm := MeshInstance3D.new()
		rm.mesh = rim_mesh
		rm.material_override = rim_mat
		rm.rotation_degrees.z = 90.0
		spin.add_child(rm)
		for s in 5:
			var spoke := mesh_box(spin, Vector3(0.34, 0.05, 0.4), Vector3.ZERO, black)
			spoke.rotation.x = float(s) / 5.0 * PI
		spin_nodes.append(spin)
		if d[2]:
			front_pivots.append(pivot)
		else:
			var sm := make_smoke(Vector3(d[0], 0.15, d[1]))
			car_vis.add_child(sm)
			smoke.append(sm)


func build_camera() -> void:
	cam = Camera3D.new()
	cam.fov = 66.0
	cam.far = 3500.0
	cam.near = 0.08
	add_child(cam)
	cam.current = true


func build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)
	var pts := PackedVector2Array()
	for c in center:
		pts.append(Vector2(c.x, c.z))
	hud.track = pts


func build_audio() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.15
	player = AudioStreamPlayer.new()
	player.stream = gen
	add_child(player)
	player.play()
	pb = player.get_stream_playback() as AudioStreamGeneratorPlayback
	var mgen := AudioStreamGenerator.new()
	mgen.mix_rate = MUSIC_RATE
	mgen.buffer_length = 0.3
	music_player = AudioStreamPlayer.new()
	music_player.stream = mgen
	music_player.volume_db = -8.0
	add_child(music_player)
	music_player.play()
	m_pb = music_player.get_stream_playback() as AudioStreamGeneratorPlayback


func reset_car(idx: int) -> void:
	var d := dirs[idx]
	var p := center[idx] + Vector3(0, BALL_R, 0)
	ball.global_position = p
	ball.linear_velocity = Vector3.ZERO
	var rid := ball.get_rid()
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), p))
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, Vector3.ZERO)
	set_flying(false)
	ball.axis_lock_linear_y = true
	yaw = atan2(-d.x, -d.z)
	steer = 0.0
	gear = 1
	shift_timer = 0.0
	prev_fwd = 0.0
	prev_speed = 0.0
	prev_sp = cum_len[idx]
	cam_dir = Vector3(d.x, 0, d.z).normalized()
	prev_idx = idx
	car_vis.global_position = p - Vector3(0, BALL_R, 0)


# ------------------------------------------------------------ input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_C:
				cam_mode = (cam_mode + 1) % 3
			KEY_L:
				for l in lights:
					l.visible = not l.visible
			KEY_R:
				reset_car(int(nearest_on_track(ball.global_position).x))
			KEY_B, KEY_ESCAPE:
				toggle_shop()
			KEY_F:
				if cs["fly"] and not shop_open:
					set_flying(not flying)
			KEY_M:
				music_on = not music_on
				music_player.stream_paused = not music_on
			KEY_T:
				tod = fposmod(tod + 0.2, 1.0)
			KEY_X:
				rain_on = not rain_on
			KEY_G:
				manual = not manual
			KEY_H:
				explode_car()
			KEY_Y:
				if ball.linear_velocity.length() < 3.0 and money >= 200:
					money -= 200
					tyre_c = (tyre_c + 1) % 3
					tires = 1.0
					tire_temp = 0.3
			KEY_U:
				use_mph = not use_mph
			KEY_Z:
				abs_on = not abs_on
			KEY_V:
				tc_on = not tc_on
			KEY_N:
				restart_race()
			KEY_E:
				if manual and gear < 6:
					gear += 1
					shift_timer = 0.2
			KEY_Q:
				if manual and gear > 1:
					gear -= 1
					shift_timer = 0.15


# ------------------------------------------------------------ physics
var boom_tex: GradientTexture2D


func boom_gradient(offs: Array, cols: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offs)
	g.colors = PackedColorArray(cols)
	return g


func boom_layer(parent: Node3D, amount: int, life: float, vmin: float, vmax: float, smin: float, smax: float, grad: Gradient, additive: bool, spread: float, grav: Vector3, damp: float, burst: float) -> void:
	var p := CPUParticles3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = boom_tex
	q.material = m
	p.mesh = q
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = burst
	p.direction = Vector3.UP
	p.spread = spread
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.gravity = grav
	p.damping_min = damp
	p.damping_max = damp * 1.5
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	var cv := Curve.new()
	cv.add_point(Vector2(0.0, 0.35))
	cv.add_point(Vector2(1.0, 1.0))
	p.scale_amount_curve = cv
	p.color_ramp = grad
	parent.add_child(p)
	p.emitting = true


func ensure_boom_tex() -> void:
	if boom_tex != null:
		return
	var sg := Gradient.new()
	sg.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	sg.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	boom_tex = GradientTexture2D.new()
	boom_tex.gradient = sg
	boom_tex.fill = GradientTexture2D.FILL_RADIAL
	boom_tex.fill_from = Vector2(0.5, 0.5)
	boom_tex.fill_to = Vector2(1.0, 0.5)
	boom_tex.width = 128
	boom_tex.height = 128


func make_dust() -> void:
	ensure_boom_tex()
	dust_node = CPUParticles3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = boom_tex
	q.material = m
	dust_node.mesh = q
	dust_node.amount = 50
	dust_node.lifetime = 1.5
	dust_node.emitting = false
	dust_node.local_coords = false
	dust_node.direction = Vector3.UP
	dust_node.spread = 40.0
	dust_node.initial_velocity_min = 1.0
	dust_node.initial_velocity_max = 3.5
	dust_node.gravity = Vector3(0, 0.6, 0)
	dust_node.scale_amount_min = 1.2
	dust_node.scale_amount_max = 2.6
	var cv := Curve.new()
	cv.add_point(Vector2(0.0, 0.4))
	cv.add_point(Vector2(1.0, 1.0))
	dust_node.scale_amount_curve = cv
	dust_node.color_ramp = boom_gradient([0.0, 0.3, 1.0], [Color(0.55, 0.45, 0.3, 0.0), Color(0.55, 0.45, 0.3, 0.45), Color(0.6, 0.5, 0.35, 0.0)])
	add_child(dust_node)


func build_track_extras() -> void:
	var white := make_mat(Color(0.95, 0.95, 0.95), 0.6)
	var black := make_mat(Color(0.05, 0.05, 0.05), 0.6)
	var metal := make_mat(Color(0.15, 0.15, 0.18), 0.4, 0.6)
	var red := make_mat(Color(0.8, 0.08, 0.08), 0.6)
	# start / finish line and gantry
	var d0 := dirs[0]
	var r0 := d0.cross(Vector3.UP).normalized()
	var yaw0 := atan2(-d0.x, -d0.z)
	for row in 2:
		for k in 8:
			var tile := mesh_box(self, Vector3(2.0, 0.04, 1.0), center[0] + r0 * (-7.0 + k * 2.0) + d0 * (row - 0.5) + Vector3(0, 0.07, 0), white if (k + row) % 2 == 0 else black)
			tile.rotation.y = yaw0
	for sgn in [-1.0, 1.0]:
		mesh_box(self, Vector3(0.8, 7.5, 0.8), center[0] + r0 * (ROAD_W * 0.5 + 1.6) * sgn + Vector3(0, 3.75, 0), metal)
	var beam := mesh_box(self, Vector3(ROAD_W + 4.4, 1.2, 0.9), center[0] + Vector3(0, 7.4, 0), metal)
	beam.rotation.y = yaw0
	for k in 7:
		var lamp := mesh_box(beam, Vector3(0.6, 0.35, 0.1), Vector3(-5.0 + k * 1.7, 0.0, 0.5), glow_mat(Color(1.0, 0.15, 0.1), 3.0))
	# braking-distance boards before the tightest corners (3 bars = 150 m, 2 = 100 m, 1 = 50 m)
	var placed := 0
	for i in N:
		if placed >= 6:
			break
		if v_corner[i] < 48.0 and v_corner[(i - 1 + N) % N] >= 48.0:
			placed += 1
			for bars_v in [3, 2, 1]:
				var bars: int = bars_v
				var want: float = 50.0 * (4 - bars)
				var acc := 0.0
				var j := i
				while acc < want:
					j = (j - 1 + N) % N
					acc += seg_len_a[j]
				var dj := dirs[j]
				var rj := dj.cross(Vector3.UP).normalized()
				var bp := center[j] - rj * (ROAD_W * 0.5 + 3.0) + Vector3(0, 1.4, 0)
				var board := mesh_box(self, Vector3(0.15, 1.6, 1.6), bp, red)
				board.rotation.y = atan2(-dj.x, -dj.z)
				mesh_box(self, Vector3(0.1, 2.8, 0.1), bp - Vector3(0, 0.7, 0), metal)
				for b in bars:
					var bar := mesh_box(board, Vector3(0.4, 1.3, 0.2), Vector3(0.0, 0.0, -0.5 + b * 0.5), white)


func splash(pos: Vector3) -> void:
	ensure_boom_tex()
	var root := Node3D.new()
	add_child(root)
	root.global_position = pos + Vector3(0, 0.2, 0)
	boom_layer(root, 40, 1.0, 3.0, 9.0, 0.5, 1.4, boom_gradient([0.0, 0.4, 1.0], [Color(0.85, 0.9, 1.0, 0.0), Color(0.85, 0.92, 1.0, 0.55), Color(0.85, 0.92, 1.0, 0.0)]), false, 50.0, Vector3(0, -9, 0), 0.8, 0.9)
	get_tree().create_timer(2.0).timeout.connect(root.queue_free)


func register_prop(rb: RigidBody3D, p: Vector3, lift: float) -> void:
	add_child(rb)
	rb.global_position = p + Vector3(0, lift, 0)
	props.append(rb)
	prop_home.append(rb.global_position)
	prop_hit.append(false)


func make_cone(p: Vector3) -> void:
	var rb := RigidBody3D.new()
	rb.mass = 6.0
	rb.linear_damp = 1.2
	rb.angular_damp = 2.0
	var col := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.28
	sh.height = 0.7
	col.shape = sh
	rb.add_child(col)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.04
	cm.bottom_radius = 0.28
	cm.height = 0.7
	cm.material = make_mat(Color(1.0, 0.4, 0.05), 0.6)
	mi.mesh = cm
	rb.add_child(mi)
	var band := MeshInstance3D.new()
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = 0.13
	bmesh.bottom_radius = 0.17
	bmesh.height = 0.12
	bmesh.material = make_mat(Color(0.95, 0.95, 0.95), 0.5)
	band.mesh = bmesh
	band.position = Vector3(0, 0.08, 0)
	rb.add_child(band)
	register_prop(rb, p, 0.36)


func make_tyre_stack(p: Vector3) -> void:
	var rb := RigidBody3D.new()
	rb.mass = 40.0
	rb.linear_damp = 1.5
	rb.angular_damp = 2.5
	var col := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.5
	sh.height = 1.1
	col.shape = sh
	rb.add_child(col)
	for k in 3:
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.5
		cm.bottom_radius = 0.5
		cm.height = 0.34
		cm.material = make_mat(Color(0.8, 0.1, 0.1) if k == 1 else Color(0.06, 0.06, 0.06), 0.8)
		mi.mesh = cm
		mi.position = Vector3(0, -0.38 + k * 0.38, 0)
		rb.add_child(mi)
	register_prop(rb, p, 0.56)


func reset_props() -> void:
	for i in props.size():
		var rid := props[i].get_rid()
		PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), prop_home[i]))
		PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)
		PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, Vector3.ZERO)
		prop_hit[i] = false
	cones_hit = 0


func build_features() -> void:
	var conc := make_mat(Color(0.42, 0.42, 0.45), 0.95)
	var lamp_m := glow_mat(Color(1.0, 0.95, 0.8), 3.0)
	# tunnel (segments 70-84)
	for i in range(70, 85):
		var d := dirs[i]
		var r := d.cross(Vector3.UP).normalized()
		var mid := (center[i] + center[(i + 1) % N]) * 0.5
		var l := seg_len_a[i] + 0.8
		var yw := atan2(-d.x, -d.z)
		var roof := mesh_box(self, Vector3(ROAD_W + 7.0, 1.2, l), mid + Vector3(0, 7.8, 0), conc)
		roof.rotation.y = yw
		for sgn in [-1.0, 1.0]:
			var wall := mesh_box(self, Vector3(1.0, 8.4, l), mid + r * (ROAD_W * 0.5 + 3.3) * sgn + Vector3(0, 3.6, 0), conc)
			wall.rotation.y = yw
		for sx in [-3.5, 3.5]:
			var strip := mesh_box(self, Vector3(0.5, 0.1, 4.0), mid + r * sx + Vector3(0, 7.1, 0), lamp_m)
			strip.rotation.y = yw
	# overpasses
	for bi in [20, 98]:
		var d2 := dirs[bi]
		var r2 := d2.cross(Vector3.UP).normalized()
		var deck := mesh_box(self, Vector3(ROAD_W + 26.0, 1.0, 8.0), center[bi] + Vector3(0, 9.0, 0), conc)
		deck.rotation.y = atan2(-d2.x, -d2.z)
		for sgn in [-1.0, 1.0]:
			mesh_box(self, Vector3(1.6, 9.0, 1.6), center[bi] + r2 * (ROAD_W * 0.5 + 5.0) * sgn + Vector3(0, 4.5, 0), conc)
		mesh_box(deck, Vector3(ROAD_W + 26.0, 0.25, 0.2), Vector3(0, 0.9, 4.0), lamp_m)
	# puddles
	var pm := make_mat(Color(0.04, 0.06, 0.09, 0.55), 0.05, 0.9)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for pe in [[18, 3.0], [47, -2.0], [64, 2.5], [101, -3.0], [120, 1.0]]:
		var pidx: int = pe[0]
		var plat: float = pe[1]
		var pp := center[pidx] + dirs[pidx].cross(Vector3.UP).normalized() * plat
		var cyl := CylinderMesh.new()
		cyl.top_radius = 3.4
		cyl.bottom_radius = 3.4
		cyl.height = 0.02
		cyl.material = pm
		var pmi := MeshInstance3D.new()
		pmi.mesh = cyl
		add_child(pmi)
		pmi.global_position = pp + Vector3(0, 0.07, 0)
		pmi.visible = false
		puddles.append(pp)
		puddle_nodes.append(pmi)
	# chicane cones on both edges, tyre stacks at corners
	for i in range(41, 57, 2):
		var r3 := dirs[i].cross(Vector3.UP).normalized()
		for sgn in [-1.0, 1.0]:
			make_cone(center[i] + r3 * (ROAD_W * 0.5 - 1.8) * sgn)
	var side := 1.0
	for k in [28, 66, 92, 118]:
		var r4 := dirs[k].cross(Vector3.UP).normalized()
		make_tyre_stack(center[k] + r4 * 6.4 * side)
		make_tyre_stack(center[k] + dirs[k] * 1.2 + r4 * 6.4 * side)
		side = -side


func firework(pos: Vector3) -> void:
	ensure_boom_tex()
	var root := Node3D.new()
	add_child(root)
	root.global_position = pos
	var cols := [Color(1, 0.3, 0.3), Color(0.3, 1, 0.4), Color(0.4, 0.6, 1), Color(1, 0.85, 0.2), Color(1, 0.4, 1)]
	var c: Color = cols[randi() % cols.size()]
	boom_layer(root, 120, 1.8, 14.0, 22.0, 0.35, 0.6, boom_gradient([0.0, 0.6, 1.0], [Color(1, 1, 1, 1), c, Color(c.r, c.g, c.b, 0)]), true, 180.0, Vector3(0, -6, 0), 1.5, 1.0)
	get_tree().create_timer(3.0).timeout.connect(root.queue_free)


func build_boost_pads() -> void:
	var pm := glow_mat(Color(0.1, 0.8, 1.0), 3.0)
	for i in [10, 35, 60, 85, 110]:
		var d := dirs[i]
		var pad := mesh_box(self, Vector3(7.0, 0.06, 9.0), center[i] + Vector3(0, 0.06, 0), pm)
		pad.rotation.y = atan2(-d.x, -d.z)
		for k in 3:
			var ch := mesh_box(pad, Vector3(4.0, 0.08, 0.5), Vector3(0, 0.03, -2.5 + k * 2.5), make_mat(Color(1, 1, 1), 0.5))
		boost_pads.append(center[i])


func explode_car() -> void:
	if shop_open or explode_t > 0.0:
		return
	ensure_boom_tex()
	var root := Node3D.new()
	add_child(root)
	root.global_position = ball.global_position + Vector3(0, 0.7, 0)
	# white-hot core flash
	boom_layer(root, 30, 0.55, 1.0, 8.0, 3.0, 6.5, boom_gradient([0.0, 0.3, 1.0], [Color(1, 1, 0.9, 1), Color(1, 0.7, 0.2, 0.8), Color(1, 0.3, 0.05, 0)]), true, 180.0, Vector3(0, 1, 0), 2.0, 1.0)
	# rolling fireball
	boom_layer(root, 70, 1.3, 4.0, 15.0, 2.0, 5.0, boom_gradient([0.0, 0.25, 0.6, 1.0], [Color(1, 0.85, 0.3, 0.9), Color(1, 0.45, 0.08, 0.8), Color(0.5, 0.1, 0.02, 0.45), Color(0.1, 0.05, 0.03, 0)]), true, 120.0, Vector3(0, 4, 0), 1.8, 0.95)
	# thick black smoke column
	boom_layer(root, 55, 4.0, 2.0, 8.0, 3.0, 7.5, boom_gradient([0.0, 0.2, 0.7, 1.0], [Color(0.05, 0.05, 0.05, 0), Color(0.08, 0.08, 0.08, 0.75), Color(0.2, 0.2, 0.2, 0.4), Color(0.3, 0.3, 0.3, 0)]), false, 60.0, Vector3(0, 3.0, 0), 1.2, 0.5)
	# hot sparks
	boom_layer(root, 90, 1.4, 12.0, 38.0, 0.12, 0.3, boom_gradient([0.0, 0.5, 1.0], [Color(1, 0.95, 0.6, 1), Color(1, 0.55, 0.1, 0.9), Color(1, 0.2, 0.0, 0)]), true, 90.0, Vector3(0, -16, 0), 0.5, 1.0)
	# car debris chunks
	var dp := CPUParticles3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.35, 0.12, 0.5)
	bm.material = make_mat(cs["color"], 0.4, 0.6)
	dp.mesh = bm
	dp.amount = 22
	dp.lifetime = 2.6
	dp.one_shot = true
	dp.explosiveness = 1.0
	dp.direction = Vector3.UP
	dp.spread = 75.0
	dp.initial_velocity_min = 8.0
	dp.initial_velocity_max = 24.0
	dp.gravity = Vector3(0, -22, 0)
	dp.angular_velocity_min = 200.0
	dp.angular_velocity_max = 700.0
	dp.scale_amount_min = 0.5
	dp.scale_amount_max = 2.2
	root.add_child(dp)
	dp.emitting = true
	# shockwave ring
	var ring := MeshInstance3D.new()
	var rs := SphereMesh.new()
	rs.radius = 1.0
	rs.height = 0.5
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rm.cull_mode = BaseMaterial3D.CULL_DISABLED
	rm.albedo_color = Color(1.0, 0.75, 0.4, 0.5)
	rs.material = rm
	ring.mesh = rs
	root.add_child(ring)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(24, 2, 24), 0.5)
	tw.tween_property(rm, "albedo_color:a", 0.0, 0.5)
	# light flash
	var fl := OmniLight3D.new()
	fl.light_color = Color(1.0, 0.6, 0.2)
	fl.light_energy = 20.0
	fl.omni_range = 60.0
	root.add_child(fl)
	var tw2 := create_tween()
	tw2.tween_property(fl, "light_energy", 0.0, 1.0)
	get_tree().create_timer(6.0).timeout.connect(root.queue_free)
	impact_vis = 1.0
	car_vis.visible = false
	ball.linear_velocity = Vector3.ZERO
	explode_t = 3.0


func restart_race() -> void:
	reset_car(N - 1)
	lap = 0
	lap_time = 0.0
	half_passed = false
	finished = false
	countdown = 3.0
	fuel = 1.0
	tires = 1.0
	car_hp = 100.0
	tire_temp = 0.3
	brake_temp = 0.0
	nitro = 1.0
	p_prog = cum_len[N - 1]
	prev_sp = cum_len[N - 1]
	for i in ais.size():
		ais[i]["s"] = cum_len[N - 1] - 14.0 * (i + 1)
		ais[i]["speed"] = 0.0
		ais[i]["off"] = ais[i]["base_lane"]
	update_ai(0.0)
	reset_props()


func torque_at(rpm: float) -> float:
	if rpm > REDLINE:
		return 0.0
	if rpm <= 4500.0:
		var n := clampf((rpm - IDLE) / (4500.0 - IDLE), 0.0, 1.0)
		return MAX_TORQUE * lerpf(0.6, 1.0, n)
	return MAX_TORQUE * lerpf(1.0, 0.7, clampf((rpm - 4500.0) / 2700.0, 0.0, 1.0))


func _physics_process(delta: float) -> void:
	if shop_open:
		shop_cam(delta)
		return
	if explode_t > 0.0:
		explode_t -= delta
		ball.linear_velocity = Vector3(0, ball.linear_velocity.y, 0)
		if explode_t <= 0.0:
			car_vis.visible = true
			car_hp = 100.0
			reset_car(int(nearest_on_track(ball.global_position).x))
		return
	var h := Vector3.FORWARD.rotated(Vector3.UP, yaw)
	var right := h.cross(Vector3.UP).normalized()
	var vel := ball.linear_velocity
	var vh := Vector3(vel.x, 0, vel.z)
	var fwd_speed := vh.dot(h)
	var lat := vh.dot(right)
	var speed_ms := vh.length()
	var speed_kmh := speed_ms * 3.6
	var on_ground := ball.global_position.y < BALL_R + 0.25
	# Fuel weight: the car gets lighter as the tank empties
	car_mass = float(cs["mass"]) + (0.0 if cs["ev"] else fuel * 45.0)
	ball.mass = car_mass

	var key_up := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
	var key_dn := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	var key_l := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var key_r := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	var handbrake := Input.is_physical_key_pressed(KEY_SPACE)

	var throttle := 0.0
	var rev_throttle := 0.0
	var brake_in := 0.0
	if key_up:
		if fwd_speed < -1.5:
			brake_in = 1.0
		else:
			throttle = 1.0
	if key_dn:
		if fwd_speed > 1.5:
			brake_in = 1.0
		elif not key_up:
			rev_throttle = 1.0

	# Race start countdown: car held on the grid
	if countdown > -1.0:
		countdown -= delta
	if countdown > 0.0:
		throttle = 0.0
		rev_throttle = 0.0

	# Track position / off-road
	var near := nearest_on_track(ball.global_position)
	pad_cd = maxf(0.0, pad_cd - delta)
	pad_t = maxf(0.0, pad_t - delta)
	if pad_cd <= 0.0 and on_ground:
		for bp in boost_pads:
			if Vector2(ball.global_position.x - bp.x, ball.global_position.z - bp.z).length() < 5.0:
				nitro = 1.0
				ball.linear_velocity += h * 9.0
				pad_cd = 1.0
				pad_t = 1.2
				break
	var idx := int(near.x)
	tunnel_on = idx >= 70 and idx <= 84
	for pi in props.size():
		if not prop_hit[pi] and props[pi].global_position.distance_to(prop_home[pi]) > 1.0:
			prop_hit[pi] = true
			cones_hit += 1
			money += 25
	# Race progress (unwrapped distance along the track) and position among the AI
	var s_p := cum_len[idx] + nearest_pt.distance_to(center[idx])
	var dsp := s_p - prev_sp
	if dsp < -total_len * 0.5:
		dsp += total_len
	elif dsp > total_len * 0.5:
		dsp -= total_len
	p_prog += dsp
	prev_sp = s_p
	update_ai(0.0 if countdown > 0.0 else delta)
	var pos_n := 1
	for ai in ais:
		if float(ai["s"]) > p_prog:
			pos_n += 1
	race_pos = pos_n
	# Slipstream: tucked in behind another car cuts your drag
	draft = 0.0
	for da in ais:
		var dn: Node3D = da["node"]
		var rel := dn.global_position - ball.global_position
		if rel.dot(h) > 3.0 and rel.dot(h) < 30.0 and absf(rel.dot(right)) < 2.5:
			draft = maxf(draft, 1.0 - rel.dot(h) / 30.0)
	draft *= clampf(speed_ms / 30.0, 0.0, 1.0)
	off_road = near.y > ROAD_W * 0.5 + 1.0
	# Safety net: if the car ever gets past the walls, put it back on the track
	if near.y > ROAD_W * 0.5 + 1.6 and not flying and ball.axis_lock_linear_y:
		var outn := ball.global_position - nearest_pt
		outn.y = 0.0
		outn = outn.normalized()
		var safe := nearest_pt + outn * (ROAD_W * 0.5 - 0.6)
		safe.y = BALL_R
		PhysicsServer3D.body_set_state(ball.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), safe))
		ball.linear_velocity = (vel - outn * maxf(vel.dot(outn), 0.0)) * 0.8

	# Kerbs, brake fade, tyre wear
	var on_kerb := on_ground and speed_ms > 8.0 and near.y > ROAD_W * 0.5 - 0.9 and near.y < ROAD_W * 0.5 + 0.3
	kerb_vis = lerpf(kerb_vis, 1.0 if on_kerb else 0.0, clampf(12.0 * delta, 0.0, 1.0))
	brake_temp = clampf(brake_temp + brake_in * clampf(speed_ms / 50.0, 0.0, 1.0) * 0.12 * delta - (0.04 + speed_ms * 0.004) * brake_temp * delta, 0.0, 1.0)
	var brake_eff := 1.0 - 0.45 * smoothstep(0.7, 1.0, brake_temp)
	tires = clampf(tires - float(TYRE_WEAR[tyre_c]) * (0.0003 + 0.0006 * clampf((absf(lat) - 3.0) / 8.0, 0.0, 1.0) + brake_in * 0.0004 * clampf(speed_ms / 30.0, 0.0, 1.0) + (0.001 if spin_slip else 0.0)) * delta, 0.0, 1.0)

	# Impacts: sudden speed loss = crash (sparks, shake, thump, damage)
	var drop := prev_speed - speed_ms
	if drop > 6.0:
		impact_vis = clampf(drop / 25.0, 0.2, 1.0)
		spark_t = 0.25
		car_hp = maxf(0.0, car_hp - drop * 0.5)
	prev_speed = speed_ms
	impact_vis = lerpf(impact_vis, 0.0, clampf(6.0 * delta, 0.0, 1.0))

	# Nitro (Left Shift): 4s of boost, recharges slowly
	var want_nitro := Input.is_physical_key_pressed(KEY_SHIFT) and throttle > 0.0
	nitro_on = want_nitro and (nitro > 0.15 or (nitro_on and nitro > 0.0))
	if nitro_on:
		nitro = maxf(0.0, nitro - delta / 4.0)
	else:
		nitro = minf(1.0, nitro + delta / 14.0)

	# Tyre grip limit (downforce adds grip, grass/handbrake remove it)
	var mu := 1.6 * float(cs["grip"]) * (1.0 + speed_ms * speed_ms / float(cs["df"]))
	if off_road:
		mu *= float(cs["off"])
	mu *= (0.7 + 0.3 * tires) * (1.0 - 0.3 * wet)
	# Tyre temperature: cold or overheated rubber grips less
	var heat := 0.02 + 0.10 * clampf((absf(lat) - 1.5) / 8.0, 0.0, 1.0) + 0.08 * brake_in * clampf(speed_ms / 40.0, 0.0, 1.0) + (0.1 if spin_slip else 0.0)
	tire_temp = clampf(tire_temp + (heat * clampf(speed_ms / 15.0, 0.0, 1.0) - (0.03 + 0.05 * wet + speed_ms * 0.0008) * (tire_temp - 0.15)) * delta, 0.0, 1.0)
	mu *= 1.0 - 0.18 * absf(tire_temp - 0.6) / 0.6
	mu *= float(TYRE_GRIP[tyre_c])
	# Puddles: aquaplaning cuts grip hard
	var in_pud := false
	if wet > 0.25 and on_ground:
		for pu in puddles:
			if Vector2(ball.global_position.x - pu.x, ball.global_position.z - pu.z).length() < 3.6:
				in_pud = true
				break
	if in_pud:
		mu *= 0.55
		if not was_pud and speed_ms > 10.0:
			splash(ball.global_position)
	was_pud = in_pud
	for pn in puddle_nodes:
		pn.visible = wet > 0.25
	var max_lat := mu * 9.8
	if handbrake:
		max_lat *= 0.35
	# Without ABS, hard braking locks the wheels and you lose steering grip
	var lockup := brake_in > 0.0 and not abs_on and speed_ms > 8.0
	locked = lockup
	if lockup:
		max_lat *= 0.5

	# Steering (positive = left), bicycle model, yaw rate limited by grip
	var max_ang := 0.58 / (1.0 + speed_ms * 0.055)
	var steer_target := (float(key_l) - float(key_r)) * max_ang
	steer = move_toward(steer, steer_target, delta * 8.0)
	var yaw_rate := fwd_speed / WHEELBASE * tan(steer)
	var cap := max_lat / maxf(absf(fwd_speed), 3.0) * (1.8 if handbrake else 1.5)
	if handbrake:
		cap = maxf(cap, 1.2 * absf(steer_target) / maxf(max_ang, 0.01))
	# Weight transfer: braking loads the nose (sharper turn-in), power unloads it (understeer)
	yaw_rate *= 1.0 + 0.25 * clampf(-a_long / 12.0, 0.0, 1.0) - 0.15 * clampf(a_long / 10.0, 0.0, 1.0)
	yaw_rate = clampf(yaw_rate, -cap, cap)
	if handbrake and absf(fwd_speed) > 4.0:
		yaw_rate += (float(key_l) - float(key_r)) * 0.9
	if flying:
		yaw_rate = (float(key_l) - float(key_r)) * 1.3
	if on_ground or flying:
		yaw += yaw_rate * delta
	yaw_rate_vis = lerpf(yaw_rate_vis, yaw_rate, clampf(8.0 * delta, 0.0, 1.0))

	# Gearbox
	var in_reverse := rev_throttle > 0.0 or fwd_speed < -1.0
	var ratio: float = REV_RATIO if in_reverse else GEARS[gear - 1] * float(cs["gm"])
	var wheel_rpm := absf(fwd_speed) / (TAU * WHEEL_R) * 60.0
	var rpm_wheels := wheel_rpm * ratio * FINAL
	shift_timer -= delta
	if not in_reverse and shift_timer <= 0.0 and not manual:
		if rpm_wheels > 6300.0 and gear < 6:
			gear += 1
			shift_timer = 0.25
		elif rpm_wheels < 2300.0 and gear > 1:
			gear -= 1
			shift_timer = 0.15
		ratio = GEARS[gear - 1] * float(cs["gm"])
		rpm_wheels = wheel_rpm * ratio * FINAL
	var launch := (throttle + rev_throttle) * 2500.0 * (1.0 - clampf(speed_ms / 10.0, 0.0, 1.0))
	var rpm_target := minf(maxf(rpm_wheels, IDLE + launch), REDLINE)
	rpm_vis = lerpf(rpm_vis, rpm_target, clampf(10.0 * delta, 0.0, 1.0))

	# Engine force (Newtons along heading)
	var total := 0.0
	var eff_rpm := maxf(rpm_wheels, IDLE if manual else 2000.0)
	if rev_throttle > 0.0:
		if fwd_speed > -10.0:
			total = -torque_at(eff_rpm) * REV_RATIO * FINAL * EFF / WHEEL_R * 0.5 * float(cs["torque"])
	elif throttle > 0.0:
		if shift_timer <= 0.1:
			total = torque_at(eff_rpm) * ratio * FINAL * EFF / WHEEL_R * float(cs["torque"])
	elif speed_ms > 1.0:
		total = -signf(fwd_speed) * minf(300.0, maxf(0.0, rpm_wheels - IDLE) * 0.05)
	if throttle > 0.0 and not cs["ev"]:
		total = minf(total, float(cs["kw"]) * 1000.0 / maxf(fwd_speed, 4.0))
	if cs["ev"]:
		# Electric motor: instant torque, power-limited at speed, regen when coasting
		var ev_f := minf(16000.0, float(cs["kw"]) * 1000.0 / maxf(absf(fwd_speed), 1.0))
		ev_f *= clampf((90.0 - fwd_speed) / 10.0, 0.0, 1.0)
		if rev_throttle > 0.0:
			total = (-ev_f * 0.35) if fwd_speed > -12.0 else 0.0
		elif throttle > 0.0:
			total = ev_f
		elif speed_ms > 1.0:
			total = -signf(fwd_speed) * 2000.0
		else:
			total = 0.0
		rpm_vis = lerpf(rpm_vis, clampf(IDLE + speed_ms * 75.0, IDLE, 8000.0), clampf(10.0 * delta, 0.0, 1.0))
	if fuel <= 0.0 and total > 0.0:
		total = 0.0
	# Rev limiter (manual box): bouncing off the limiter cuts power
	if manual and not cs["ev"] and rpm_wheels >= REDLINE - 100.0 and total > 0.0:
		total *= 0.15
	if total > 0.0:
		total *= (1.0 + 0.25 * boost)
	if off_road:
		total *= 0.8
	if nitro_on and total > 0.0:
		total = total * 1.5 + car_mass * 7.0
	var tl := mu * car_mass * 9.8 * (float(cs["tf"]) + (0.25 if nitro_on else 0.0))
	# Estimate driven-wheel slip. Traction control cuts engine torque instead of
	# simply hiding wheelspin from the effects system.
	var wheelspin_demand := throttle > 0.0 and total > tl * 0.92 and speed_ms < 55.0
	spin_slip = wheelspin_demand and not tc_on
	if tc_on and wheelspin_demand:
		total *= 0.68
	if spin_slip:
		max_lat *= 0.82
	total = clampf(total, -tl, tl)

	if on_ground:
		# Lateral tyre force: a smooth slip-angle curve gives progressive
		# understeer rather than an artificial on/off grip switch.
		var pkb: float = 1.3 if handbrake else float(cs["latk"])
		var slip_r := lat / (absf(fwd_speed) + 2.5)
		var lat_acc := -max_lat * sin(1.4 * atan(pkb * slip_r))
		lat_acc = clampf(lat_acc, -absf(lat) / maxf(delta, 0.0001) * 0.8, absf(lat) / maxf(delta, 0.0001) * 0.8)

		# Braking, handbrake and engine force all consume the same tyre grip
		# budget. This friction-circle approximation prevents full braking and
		# maximum cornering from happening simultaneously.
		var brake_force := 0.0
		if speed_ms > 0.4:
			if brake_in > 0.0:
				brake_force += car_mass * float(cs["brk"]) * (0.7 if off_road else 1.0) * brake_eff
			if handbrake:
				brake_force += car_mass * 2.0
			brake_force += 190.0
			if off_road:
				brake_force += car_mass * 3.0
		var longitudinal := total - signf(fwd_speed) * brake_force
		var grip_force := mu * car_mass * 9.8
		var lateral_force := lat_acc * car_mass
		var long_ratio := absf(longitudinal) / maxf(grip_force, 1.0)
		var lat_ratio := absf(lateral_force) / maxf(grip_force, 1.0)
		var combined := sqrt(long_ratio * long_ratio + lat_ratio * lat_ratio)
		if combined > 1.0:
			longitudinal /= combined
			lateral_force /= combined

		# ABS keeps the tyres rolling under hard braking. With ABS disabled,
		# braking can exceed the available longitudinal grip and lock the wheels.
		if lockup:
			longitudinal *= 1.08
		ball.apply_central_force(h * longitudinal)
		ball.apply_central_force(right * lateral_force)
	elif brake_in > 0.0 and speed_ms < 0.4:
		ball.linear_velocity = Vector3(0, vel.y, 0)
	# Rolling resistance is nearly constant at low speed; aerodynamic drag
	# rises with speed squared (force opposite velocity).
	if on_ground and speed_ms > 0.05:
		ball.apply_central_force(-vh.normalized() * car_mass * 0.14)
	if speed_ms > 0.3:
		var aero_force := 0.5 * 1.225 * 0.62 * float(cs["drag"]) * speed_ms * speed_ms
		aero_force *= (1.0 - 0.35 * draft)
		ball.apply_central_force(-vh.normalized() * aero_force)

	# Crosswind gusts (not inside the tunnel)
	var tsec := float(Time.get_ticks_msec()) * 0.001
	var gust := sin(tsec * 0.33) * sin(tsec * 0.13 + 1.0)
	if not tunnel_on:
		ball.apply_central_force(right * gust * car_mass * 0.8 * clampf(speed_ms / 40.0, 0.0, 1.0))

	# Flight mode (Roadster EV): thrust, lateral damping, altitude control
	if flying:
		ball.apply_central_force(h * total)
		ball.apply_central_force(right * (-lat) * car_mass * 3.0)
		var cy := ball.global_position.y
		var key_up_fly := Input.is_physical_key_pressed(KEY_SPACE)
		var key_dn_fly := Input.is_physical_key_pressed(KEY_CTRL)
		var vy_target := 0.0
		if key_up_fly:
			vy_target = 14.0
			fly_hold_y = cy
		elif key_dn_fly:
			vy_target = -14.0
			fly_hold_y = maxf(cy, BALL_R)
		else:
			vy_target = clampf((fly_hold_y - cy) * 1.5, -10.0, 10.0)
		if cy > 260.0 and vy_target > 0.0:
			vy_target = 0.0
		ball.apply_central_force(Vector3.UP * (vy_target - vel.y) * car_mass * 4.0)
		if brake_in > 0.0 and speed_ms > 0.5:
			ball.apply_central_force(-vh.normalized() * car_mass * 8.0)
		if key_dn_fly and cy < BALL_R + 1.2:
			set_flying(false)
	# Landing: cap the fall speed, then lock back onto the road surface
	if not flying and not ball.axis_lock_linear_y:
		if vel.y < -12.0:
			ball.apply_central_force(Vector3.UP * car_mass * 25.0)
		if ball.global_position.y < BALL_R + 0.2:
			var gp := ball.global_position
			gp.y = BALL_R
			PhysicsServer3D.body_set_state(ball.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), gp))
			ball.axis_lock_linear_y = true
			ball.linear_velocity = Vector3(vel.x, 0.0, vel.z)

	var squeal_t := clampf((absf(lat) - 3.0) / 8.0, 0.0, 1.0) if on_ground else 0.0
	if lockup and on_ground:
		squeal_t = maxf(squeal_t, 0.8)
	squeal_vis = lerpf(squeal_vis, squeal_t, clampf(10.0 * delta, 0.0, 1.0))
	wind_vis = clampf(speed_ms / 80.0, 0.0, 1.0)
	var burn := 0.0
	if cs["ev"]:
		burn = 0.0003 + 0.0016 * throttle + (0.0022 if flying else 0.0)
		if throttle == 0.0 and speed_ms > 5.0:
			burn = -0.0002 * clampf(speed_ms / 40.0, 0.0, 1.0)
	else:
		burn = 0.0004 + 0.0022 * throttle * clampf(rpm_vis / 7000.0, 0.0, 1.0) + (0.002 if nitro_on else 0.0)
	fuel = clampf(fuel - burn * delta, 0.0, 1.0)
	if fuel <= 0.0 and flying:
		set_flying(false)
	var boost_t := 0.0
	if cs["turbo"]:
		boost_t = throttle * clampf((rpm_vis - 2500.0) / 2500.0, 0.0, 1.0)
	if boost > 0.55 and boost_t < boost - 0.3 and bov_t <= 0.0:
		bov_t = 0.35
	boost = lerpf(boost, boost_t, clampf((1.6 if boost_t > boost else 5.0) * delta, 0.0, 1.0))
	bov_t = maxf(0.0, bov_t - delta)
	eng_smoke.emitting = car_hp < 25.0
	dust_node.global_position = ball.global_position + Vector3(0, 0.2, 0)
	dust_node.emitting = off_road and on_ground and speed_ms > 8.0
	# Broken car: no performance loss, but 3 minutes later it auto-repairs for $2000, or explodes if you can't pay
	if car_hp < 25.0 and countdown <= 0.0:
		broken_t += delta
		if broken_t >= 180.0:
			broken_t = 0.0
			car_hp = 100.0
			if money >= 2000:
				money -= 2000
			else:
				impact_vis = 1.0
				spark_t = 1.0
				reset_car(idx)
	else:
		broken_t = 0.0
	# Exhaust pops on lift-off at high revs
	if not cs["ev"] and throttle <= 0.0 and rpm_vis > 5200.0 and speed_ms > 15.0 and randf() < 0.05:
		backfire_t = 0.12
	backfire_t = maxf(0.0, backfire_t - delta)
	spark_t -= delta
	sparks.position = ball.global_position + Vector3(0, 0.3, 0)
	sparks.emitting = spark_t > 0.0
	for f in flames:
		f.emitting = nitro_on or backfire_t > 0.0
	nitro_light.visible = nitro_on
	earn_acc += speed_ms * delta * 0.15
	if abs(lat) > 4.0 and speed_ms > 10.0:
		earn_acc += delta * 15.0
	var drifting := on_ground and not off_road and speed_ms > 12.0 and absf(lat) > 4.0 and countdown <= 0.0
	if drop > 6.0:
		drift_pts = 0.0
		drift_combo = 1.0
	if drifting:
		drift_pts += absf(lat) * speed_ms * 0.1 * delta * drift_combo
		drift_combo = minf(8.0, drift_combo + delta * 0.5)
		drift_gap = 0.0
	else:
		drift_gap += delta
		if drift_gap > 1.2 and drift_pts > 0.0:
			drift_bank = int(drift_pts)
			money += drift_bank
			drift_bank_t = 2.5
			drift_pts = 0.0
			drift_combo = 1.0
	drift_bank_t = maxf(0.0, drift_bank_t - delta)
	if earn_acc >= 1.0:
		money += int(earn_acc)
		earn_acc -= floorf(earn_acc)
	brake_mat.emission_energy_multiplier = 5.0 if (brake_in > 0.0 or rev_throttle > 0.0) else 0.8
	throttle_vis = lerpf(throttle_vis, maxf(throttle, rev_throttle), clampf(8.0 * delta, 0.0, 1.0))

	# Laps
	if countdown <= 0.0:
		lap_time += delta
	if idx >= N / 2 and idx < 3 * N / 4:
		half_passed = true
	if idx < N / 4 and prev_idx > 3 * N / 4 and half_passed:
		lap += 1
		money += 1500
		last_lap = lap_time
		if best_lap < 0.0 or lap_time < best_lap:
			best_lap = lap_time
		lap_time = 0.0
		half_passed = false
		if lap >= race_laps and not finished:
			finished = true
			finish_pos = race_pos
			var prizes := [5000, 3000, 1500, 500]
			var prize: int = prizes[clampi(race_pos - 1, 0, 3)]
			money += prize
			firework_t = 8.0
	prev_idx = idx

	update_visual(delta, fwd_speed, speed_ms, lat, on_ground, handbrake)
	update_camera(delta, speed_ms, speed_kmh, fwd_speed, h, vh)

	hud.speed = speed_kmh
	hud.rpm = rpm_vis
	hud.gear_txt = "R" if in_reverse else ("D" if cs["ev"] else (("M" if manual else "") + str(gear)))
	hud.lap = lap
	hud.lap_time = lap_time
	hud.best = best_lap
	hud.last = last_lap
	hud.off_road = off_road
	hud.nitro = nitro
	hud.fuel = fuel
	hud.tires = tires
	hud.brake_t = brake_temp
	hud.hp = car_hp
	hud.race_pos = race_pos
	hud.rain = rain_on
	hud.ev = cs["ev"]
	hud.broken_t = broken_t
	hud.drift_pts = drift_pts
	hud.drift_combo = drift_combo
	hud.drift_bank = drift_bank
	hud.drift_bank_t = drift_bank_t
	hud.pad_t = pad_t
	hud.cones = cones_hit
	hud.puddle = was_pud
	hud.g_lat = yaw_rate_vis * fwd_speed / 9.8
	hud.g_long = a_long / 9.8
	hud.use_mph = use_mph
	hud.tyre_c = tyre_c
	hud.draft = draft
	hud.abs_on = abs_on
	hud.tc_on = tc_on
	hud.tire_temp = tire_temp
	hud.countdown = countdown
	hud.finished = finished
	hud.finish_pos = finish_pos
	hud.race_laps = race_laps
	var ap := PackedVector2Array()
	for ai2 in ais:
		var an: Node3D = ai2["node"]
		ap.append(Vector2(an.global_position.x, an.global_position.z))
	hud.ai_pos = ap
	hud.money = money
	hud.flying = flying
	hud.alt = ball.global_position.y - BALL_R
	hud.car_name = CARS[car_type]["name"]
	hud.nitro_on = nitro_on
	hud.car_pos = Vector2(ball.global_position.x, ball.global_position.z)
	hud.queue_redraw()


func update_visual(delta: float, fwd_speed: float, speed_ms: float, lat: float, on_ground: bool, handbrake: bool) -> void:
	a_long = lerpf(a_long, (fwd_speed - prev_fwd) / maxf(delta, 0.0001), clampf(5.0 * delta, 0.0, 1.0))
	prev_fwd = fwd_speed
	var pitch_t := clampf(a_long * 0.004, -0.05, 0.05)
	if flying:
		pitch_t = clampf(ball.linear_velocity.y * 0.03, -0.35, 0.35)
	var roll_t := clampf(-yaw_rate_vis * fwd_speed * 0.005, -0.07, 0.07)
	pitch_vis = lerpf(pitch_vis, pitch_t, clampf(6.0 * delta, 0.0, 1.0))
	roll_vis = lerpf(roll_vis, roll_t, clampf(6.0 * delta, 0.0, 1.0))
	var jit := randf_range(-1.0, 1.0) * clampf(kerb_vis + (0.0 if cs["ev"] else 0.06 * (1.0 + throttle_vis)), 0.0, 1.0)
	var b := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch_vis) * Basis(Vector3.BACK, roll_vis + jit * 0.015)
	car_vis.global_transform = Transform3D(b, ball.global_position - Vector3(0, BALL_R - absf(jit) * 0.04, 0))

	wheel_spin += fwd_speed * delta / WHEEL_R
	for s in spin_nodes:
		s.rotation.x = -wheel_spin
	for p in front_pivots:
		p.rotation.y = steer
	steer_wheel.rotation.z = -steer * 4.0
	var slipping := on_ground and speed_ms > 5.0 and (absf(lat) > 3.5 or (handbrake and speed_ms > 8.0) or spin_slip or locked)
	for sm in smoke:
		sm.emitting = slipping
	for th in thrusters:
		th.emitting = flying
	if slipping:
		skid_tick += 1
		if skid_tick % 2 == 0:
			for sx in [-0.95, 0.95]:
				add_skid(car_vis.global_transform * Vector3(sx, 0.03, 1.4))


func build_roadster_body() -> void:
	var paint := make_mat(cs["color"], 0.18, 0.9)
	paint.clearcoat_enabled = true
	paint.clearcoat = 1.0
	var glass := make_mat(Color(0.05, 0.08, 0.12), 0.03, 0.4)
	var black := make_mat(Color(0.03, 0.03, 0.03), 0.7)
	var led := glow_mat(Color(0.35, 0.75, 1.0), 4.0)
	var cap := CapsuleMesh.new()
	cap.radius = 0.5
	cap.height = 4.2
	var body := MeshInstance3D.new()
	body.mesh = cap
	body.material_override = paint
	body.rotation_degrees = Vector3(90, 0, 0)
	body.scale = Vector3(1.85, 1.0, 0.42)
	body.position = Vector3(0, 0.58, 0)
	car_vis.add_child(body)
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	var wind := MeshInstance3D.new()
	wind.mesh = sph
	wind.material_override = glass
	wind.scale = Vector3(1.4, 0.3, 0.9)
	wind.position = Vector3(0, 0.86, -0.3)
	car_vis.add_child(wind)
	mesh_box(car_vis, Vector3(0.45, 0.35, 0.55), Vector3(0.4, 0.82, 0.55), black)
	mesh_box(car_vis, Vector3(0.45, 0.35, 0.55), Vector3(-0.4, 0.82, 0.55), black)
	mesh_box(car_vis, Vector3(1.5, 0.1, 0.12), Vector3(0, 1.0, 1.0), paint)
	mesh_box(car_vis, Vector3(1.5, 0.1, 0.4), Vector3(0, 0.33, 2.0), black)
	mesh_box(car_vis, Vector3(1.7, 0.06, 0.3), Vector3(0, 0.36, -2.1), black)
	mesh_box(car_vis, Vector3(1.4, 0.05, 0.05), Vector3(0, 0.72, -2.12), led)
	for sx in [-0.6, 0.6]:
		for sz in [-1.4, 1.4]:
			mesh_box(car_vis, Vector3(0.3, 0.1, 0.3), Vector3(sx, 0.32, sz), black)
			var th := make_flame(Vector3(sx, 0.28, sz))
			th.direction = Vector3.DOWN
			th.spread = 10.0
			th.initial_velocity_min = 5.0
			th.initial_velocity_max = 8.0
			car_vis.add_child(th)
			thrusters.append(th)


func make_rain() -> void:
	rain_node = CPUParticles3D.new()
	rain_node.amount = 900
	rain_node.lifetime = 1.3
	rain_node.emitting = false
	rain_node.local_coords = false
	rain_node.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain_node.emission_box_extents = Vector3(30.0, 0.5, 30.0)
	rain_node.direction = Vector3.DOWN
	rain_node.spread = 2.0
	rain_node.initial_velocity_min = 22.0
	rain_node.initial_velocity_max = 28.0
	rain_node.gravity = Vector3(0, -10.0, 0)
	var m := BoxMesh.new()
	m.size = Vector3(0.02, 0.5, 0.02)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.8, 0.9, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material = mat
	rain_node.mesh = m
	add_child(rain_node)


func build_ai_visual(parent: Node3D, color: Color) -> void:
	var paint := make_mat(color, 0.25, 0.6)
	var glass := make_mat(Color(0.03, 0.05, 0.08), 0.05, 0.4)
	var black := make_mat(Color(0.03, 0.03, 0.03), 0.8)
	var tail := glow_mat(Color(1.0, 0.05, 0.05), 3.0)
	var cap := CapsuleMesh.new()
	cap.radius = 0.5
	cap.height = 4.3
	var body := MeshInstance3D.new()
	body.mesh = cap
	body.material_override = paint
	body.rotation_degrees = Vector3(90, 0, 0)
	body.scale = Vector3(1.9, 1.0, 0.55)
	body.position = Vector3(0, 0.66, 0)
	parent.add_child(body)
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	var cabin := MeshInstance3D.new()
	cabin.mesh = sph
	cabin.material_override = glass
	cabin.scale = Vector3(1.5, 0.55, 2.3)
	cabin.position = Vector3(0, 0.98, 0.35)
	parent.add_child(cabin)
	mesh_box(parent, Vector3(1.8, 0.07, 0.45), Vector3(0, 1.28, 1.95), black)
	mesh_box(parent, Vector3(1.2, 0.1, 0.06), Vector3(0, 0.75, 2.12), tail)
	var tire_mesh := CylinderMesh.new()
	tire_mesh.top_radius = WHEEL_R
	tire_mesh.bottom_radius = WHEEL_R
	tire_mesh.height = 0.3
	for sx in [-0.95, 0.95]:
		for sz in [-1.4, 1.4]:
			var t := MeshInstance3D.new()
			t.mesh = tire_mesh
			t.material_override = black
			t.rotation_degrees.z = 90.0
			t.position = Vector3(sx, WHEEL_R, sz)
			parent.add_child(t)


func build_ai() -> void:
	var cols := [Color(0.1, 0.8, 0.3), Color(0.95, 0.5, 0.05), Color(0.6, 0.1, 0.8)]
	var skills := [0.8, 0.9, 0.97]
	p_prog = cum_len[N - 1]
	prev_sp = cum_len[N - 1]
	for i in 3:
		var body := AnimatableBody3D.new()
		body.sync_to_physics = true
		body.physics_material_override = zero_fric
		var cs2 := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.9, 1.0, 4.2)
		cs2.shape = shape
		cs2.position = Vector3(0, 0.6, 0)
		body.add_child(cs2)
		build_ai_visual(body, cols[i])
		add_child(body)
		var lane := -3.5 if i % 2 == 0 else 3.5
		ais.append({"node": body, "s": cum_len[N - 1] - 14.0 * (i + 1), "speed": 0.0, "off": lane, "base_lane": lane, "skill": skills[i]})
	update_ai(0.0)


@warning_ignore("integer_division")
func update_ai(delta: float) -> void:
	var pp := ball.global_position
	for a in ais:
		var s: float = a["s"]
		var spd: float = a["speed"]
		var skill: float = a["skill"]
		var sm := fposmod(s, total_len)
		var idx := 0
		for i in N:
			if sm >= cum_len[i] and sm < cum_len[i] + seg_len_a[i]:
				idx = i
				break
		var t := (sm - cum_len[idx]) / seg_len_a[idx]
		var nxt := (idx + 1) % N
		var p := center[idx].lerp(center[nxt], t)
		var d := dirs[idx]
		var right := d.cross(Vector3.UP).normalized()
		var target := 80.0 * skill
		var look := mini(N / 3, int(spd * spd / 324.0) + 3)
		var dist := (1.0 - t) * seg_len_a[idx]
		for k in range(0, look):
			var j := (idx + 1 + k) % N
			var vc := v_corner[j] * skill
			target = minf(target, sqrt(vc * vc + 18.0 * dist))
			dist += seg_len_a[j]
		var to_p := pp - p
		var ahead := to_p.dot(d)
		var lat_p := to_p.dot(right)
		var off: float = a["off"]
		var lane: float = a["base_lane"]
		if ahead > 0.0 and ahead < 18.0 and absf(lat_p - off) < 2.8:
			target = minf(target, maxf(ball.linear_velocity.length() * 0.95, 10.0))
			lane = clampf(off - signf(lat_p - off) * 4.0, -5.5, 5.5)
		off = move_toward(off, lane, 3.0 * delta)
		if spd < target:
			spd = minf(target, spd + 8.0 * skill * delta)
		else:
			spd = maxf(target, spd - 12.0 * delta)
		s += spd * delta
		a["s"] = s
		a["speed"] = spd
		a["off"] = off
		var n: Node3D = a["node"]
		n.global_transform = Transform3D(Basis.looking_at(d, Vector3.UP), p + right * off)


func make_sparks() -> void:
	sparks = CPUParticles3D.new()
	sparks.amount = 40
	sparks.lifetime = 0.45
	sparks.emitting = false
	sparks.local_coords = false
	sparks.direction = Vector3.UP
	sparks.spread = 70.0
	sparks.initial_velocity_min = 3.0
	sparks.initial_velocity_max = 9.0
	sparks.gravity = Vector3(0, -9.8, 0)
	var m := BoxMesh.new()
	m.size = Vector3(0.05, 0.05, 0.05)
	var mat := glow_mat(Color(1.0, 0.7, 0.2), 6.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material = mat
	sparks.mesh = m
	add_child(sparks)


func update_tod(delta: float) -> void:
	tod = fposmod(tod + delta / 480.0, 1.0)
	wet = move_toward(wet, 1.0 if rain_on else 0.0, delta * (0.12 if rain_on else 0.03))
	var elev := sin(tod * TAU)
	var k_day := smoothstep(0.1, 0.55, elev)
	var k_night := smoothstep(0.05, -0.3, elev)
	var lum := clampf(elev * 2.0 + 0.5, 0.0, 1.0)
	var top := Color(0.12, 0.22, 0.5).lerp(Color(0.25, 0.48, 0.9), k_day).lerp(Color(0.01, 0.02, 0.07), k_night)
	var hor := Color(1.0, 0.62, 0.38).lerp(Color(0.72, 0.82, 0.95), k_day).lerp(Color(0.05, 0.07, 0.16), k_night)
	var gray := Color(0.28, 0.3, 0.34)
	top = top.lerp(gray * (0.2 + 0.8 * lum), wet * 0.75)
	hor = hor.lerp(gray * (0.25 + 0.75 * lum), wet * 0.75)
	sky_ref.sky_top_color = top
	sky_ref.sky_horizon_color = hor
	sky_ref.ground_horizon_color = hor
	env_ref.fog_light_color = hor
	env_ref.fog_density = lerpf(0.0005, 0.003, wet)
	env_ref.ambient_light_energy = lerpf(0.2, 0.9, lum) * (1.0 - 0.3 * wet)
	if elev > 0.0:
		sun_ref.rotation_degrees.x = -(elev * 55.0 + 3.0)
		sun_ref.light_energy = (1.6 * clampf(elev * 4.0, 0.0, 1.0) + 0.05) * (1.0 - 0.65 * wet)
		sun_ref.light_color = Color(1.0, 0.68, 0.42).lerp(Color(1.0, 0.97, 0.9), k_day)
	else:
		sun_ref.rotation_degrees.x = -35.0
		sun_ref.light_energy = 0.25
		sun_ref.light_color = Color(0.5, 0.6, 1.0)
	asphalt_ref.roughness = lerpf(0.9, 0.3, wet)
	asphalt_ref.albedo_color = Color(1, 1, 1).lerp(Color(0.55, 0.55, 0.62), wet)
	rain_node.emitting = rain_on
	rain_node.position = ball.global_position + Vector3(0, 22, 0)


func build_muscle_body() -> void:
	var paint := make_mat(cs["color"], 0.22, 0.7)
	paint.clearcoat_enabled = true
	paint.clearcoat = 1.0
	var glass := make_mat(Color(0.03, 0.05, 0.08), 0.03, 0.4)
	var black := make_mat(Color(0.03, 0.03, 0.03), 0.8)
	var white := make_mat(Color(0.95, 0.95, 0.95), 0.3)
	var chrome := make_mat(Color(0.85, 0.85, 0.9), 0.15, 1.0)
	var cap := CapsuleMesh.new()
	cap.radius = 0.5
	cap.height = 4.5
	var body := MeshInstance3D.new()
	body.mesh = cap
	body.material_override = paint
	body.rotation_degrees = Vector3(90, 0, 0)
	body.scale = Vector3(1.95, 1.0, 0.62)
	body.position = Vector3(0, 0.68, 0)
	car_vis.add_child(body)
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	var cabin := MeshInstance3D.new()
	cabin.mesh = sph
	cabin.material_override = glass
	cabin.scale = Vector3(1.55, 0.5, 2.3)
	cabin.position = Vector3(0, 1.0, 0.65)
	car_vis.add_child(cabin)
	var roof := MeshInstance3D.new()
	roof.mesh = sph
	roof.material_override = paint
	roof.scale = Vector3(1.45, 0.16, 1.5)
	roof.position = Vector3(0, 1.26, 0.7)
	car_vis.add_child(roof)
	mesh_box(car_vis, Vector3(0.7, 0.02, 1.2), Vector3(0, 1.0, -1.15), white)
	mesh_box(car_vis, Vector3(0.7, 0.02, 0.6), Vector3(0, 0.99, 1.35), white)
	mesh_box(car_vis, Vector3(0.55, 0.14, 0.7), Vector3(0, 1.06, -1.0), black)
	mesh_box(car_vis, Vector3(1.8, 0.06, 0.3), Vector3(0, 1.05, 2.1), black)
	mesh_box(car_vis, Vector3(1.9, 0.12, 0.15), Vector3(0, 0.42, -2.28), chrome)
	mesh_box(car_vis, Vector3(1.2, 0.18, 0.05), Vector3(0, 0.62, -2.27), black)
	mesh_box(car_vis, Vector3(0.2, 0.12, 0.3), Vector3(0.5, 0.38, 2.3), chrome)
	mesh_box(car_vis, Vector3(0.2, 0.12, 0.3), Vector3(-0.5, 0.38, 2.3), chrome)
	mesh_box(car_vis, Vector3(0.1, 0.12, 2.6), Vector3(0.97, 0.4, 0), black)
	mesh_box(car_vis, Vector3(0.1, 0.12, 2.6), Vector3(-0.97, 0.4, 0), black)


func build_hyper_body() -> void:
	var paint := make_mat(cs["color"], 0.15, 0.8)
	paint.clearcoat_enabled = true
	paint.clearcoat = 1.0
	var glass := make_mat(Color(0.03, 0.05, 0.08), 0.03, 0.4)
	var black := make_mat(Color(0.03, 0.03, 0.03), 0.6)
	var led := glow_mat(Color(1.0, 0.1, 0.1), 4.0)
	var cap := CapsuleMesh.new()
	cap.radius = 0.5
	cap.height = 4.4
	var body := MeshInstance3D.new()
	body.mesh = cap
	body.material_override = paint
	body.rotation_degrees = Vector3(90, 0, 0)
	body.scale = Vector3(2.0, 1.0, 0.36)
	body.position = Vector3(0, 0.5, 0)
	car_vis.add_child(body)
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	var canopy := MeshInstance3D.new()
	canopy.mesh = sph
	canopy.material_override = glass
	canopy.scale = Vector3(1.15, 0.3, 1.9)
	canopy.position = Vector3(0, 0.78, 0.15)
	car_vis.add_child(canopy)
	mesh_box(car_vis, Vector3(2.1, 0.05, 0.5), Vector3(0, 0.32, -2.15), black)
	mesh_box(car_vis, Vector3(2.1, 0.05, 0.6), Vector3(0, 1.12, 2.0), black)
	mesh_box(car_vis, Vector3(0.05, 0.3, 0.6), Vector3(1.05, 1.0, 2.0), black)
	mesh_box(car_vis, Vector3(0.05, 0.3, 0.6), Vector3(-1.05, 1.0, 2.0), black)
	mesh_box(car_vis, Vector3(0.06, 0.45, 0.3), Vector3(0.4, 0.85, 2.0), black)
	mesh_box(car_vis, Vector3(0.06, 0.45, 0.3), Vector3(-0.4, 0.85, 2.0), black)
	mesh_box(car_vis, Vector3(0.1, 0.18, 0.9), Vector3(1.0, 0.55, 0.4), black)
	mesh_box(car_vis, Vector3(0.1, 0.18, 0.9), Vector3(-1.0, 0.55, 0.4), black)
	mesh_box(car_vis, Vector3(1.6, 0.12, 0.5), Vector3(0, 0.33, 2.1), black)
	mesh_box(car_vis, Vector3(1.4, 0.04, 0.04), Vector3(0, 0.62, 2.2), led)


func build_rally_body() -> void:
	var paint := make_mat(cs["color"], 0.3, 0.5)
	paint.clearcoat_enabled = true
	var glass := make_mat(Color(0.03, 0.05, 0.08), 0.03, 0.4)
	var black := make_mat(Color(0.03, 0.03, 0.03), 0.8)
	var white := make_mat(Color(0.95, 0.95, 0.95), 0.3)
	var lamp := glow_mat(Color(1.0, 0.95, 0.8), 5.0)
	mesh_box(car_vis, Vector3(1.85, 0.6, 3.7), Vector3(0, 0.72, 0), paint)
	mesh_box(car_vis, Vector3(1.65, 0.55, 2.0), Vector3(0, 1.28, 0.25), glass)
	mesh_box(car_vis, Vector3(1.7, 0.08, 2.0), Vector3(0, 1.58, 0.25), white)
	mesh_box(car_vis, Vector3(0.8, 0.05, 0.6), Vector3(0, 1.03, -1.2), black)
	mesh_box(car_vis, Vector3(0.4, 0.12, 0.5), Vector3(0, 1.66, -0.2), black)
	for lx in [-0.45, -0.15, 0.15, 0.45]:
		mesh_box(car_vis, Vector3(0.25, 0.12, 0.12), Vector3(lx, 1.7, -0.7), lamp)
	mesh_box(car_vis, Vector3(1.7, 0.06, 0.4), Vector3(0, 1.5, 1.95), white)
	mesh_box(car_vis, Vector3(0.06, 0.35, 0.2), Vector3(0.7, 1.3, 1.95), black)
	mesh_box(car_vis, Vector3(0.06, 0.35, 0.2), Vector3(-0.7, 1.3, 1.95), black)
	mesh_box(car_vis, Vector3(1.85, 0.2, 0.2), Vector3(0, 0.5, -1.9), black)
	for sx in [-1.0, 1.0]:
		mesh_box(car_vis, Vector3(0.02, 0.12, 3.0), Vector3(0.93 * sx, 0.75, 0), white)
		for sz in [-1.4, 1.4]:
			mesh_box(car_vis, Vector3(0.2, 0.14, 1.0), Vector3(0.98 * sx, 0.78, sz), black)


func build_hatch_body() -> void:
	var paint := make_mat(cs["color"], 0.3, 0.5)
	paint.clearcoat_enabled = true
	var glass := make_mat(Color(0.03, 0.05, 0.08), 0.03, 0.4)
	var black := make_mat(Color(0.03, 0.03, 0.03), 0.8)
	mesh_box(car_vis, Vector3(1.75, 0.55, 3.4), Vector3(0, 0.65, 0), paint)
	mesh_box(car_vis, Vector3(1.6, 0.5, 1.9), Vector3(0, 1.15, 0.2), glass)
	mesh_box(car_vis, Vector3(1.65, 0.07, 1.9), Vector3(0, 1.44, 0.2), paint)
	mesh_box(car_vis, Vector3(1.7, 0.06, 0.3), Vector3(0, 1.3, 1.65), black)
	mesh_box(car_vis, Vector3(1.75, 0.12, 0.15), Vector3(0, 0.4, -1.75), black)
	mesh_box(car_vis, Vector3(1.75, 0.12, 0.15), Vector3(0, 0.4, 1.75), black)


func build_truck_body() -> void:
	var paint := make_mat(cs["color"], 0.4, 0.4)
	var glass := make_mat(Color(0.03, 0.05, 0.08), 0.03, 0.4)
	var black := make_mat(Color(0.03, 0.03, 0.03), 0.8)
	var lamp := glow_mat(Color(1.0, 0.95, 0.8), 5.0)
	mesh_box(car_vis, Vector3(1.8, 0.35, 4.4), Vector3(0, 0.55, 0), black)
	mesh_box(car_vis, Vector3(2.0, 0.6, 1.1), Vector3(0, 1.0, -1.45), paint)
	mesh_box(car_vis, Vector3(2.0, 0.5, 1.5), Vector3(0, 1.05, -0.15), paint)
	mesh_box(car_vis, Vector3(1.9, 0.55, 1.4), Vector3(0, 1.57, -0.1), glass)
	mesh_box(car_vis, Vector3(1.95, 0.07, 1.45), Vector3(0, 1.88, -0.1), paint)
	mesh_box(car_vis, Vector3(2.0, 0.2, 1.9), Vector3(0, 0.95, 1.35), paint)
	mesh_box(car_vis, Vector3(0.1, 0.5, 1.9), Vector3(0.95, 1.2, 1.35), paint)
	mesh_box(car_vis, Vector3(0.1, 0.5, 1.9), Vector3(-0.95, 1.2, 1.35), paint)
	mesh_box(car_vis, Vector3(2.0, 0.5, 0.1), Vector3(0, 1.2, 2.3), paint)
	mesh_box(car_vis, Vector3(2.0, 0.5, 0.1), Vector3(0, 1.2, 0.4), paint)
	mesh_box(car_vis, Vector3(2.0, 0.5, 0.1), Vector3(0, 0.8, -2.05), black)
	for lx in [-0.6, -0.3, 0.0, 0.3, 0.6]:
		mesh_box(car_vis, Vector3(0.2, 0.1, 0.1), Vector3(lx, 1.98, -0.6), lamp)
	for sx in [-1.0, 1.0]:
		for sz in [-1.4, 1.4]:
			mesh_box(car_vis, Vector3(0.25, 0.16, 1.0), Vector3(1.0 * sx, 0.95, sz), black)


func build_formula_body() -> void:
	var paint := make_mat(cs["color"], 0.15, 0.7)
	paint.clearcoat_enabled = true
	var red := make_mat(Color(0.85, 0.05, 0.05), 0.2, 0.5)
	var black := make_mat(Color(0.03, 0.03, 0.03), 0.6)
	var cap := CapsuleMesh.new()
	cap.radius = 0.5
	cap.height = 3.8
	var body := MeshInstance3D.new()
	body.mesh = cap
	body.material_override = paint
	body.rotation_degrees = Vector3(90, 0, 0)
	body.scale = Vector3(0.55, 1.0, 0.32)
	body.position = Vector3(0, 0.45, 0)
	car_vis.add_child(body)
	mesh_box(car_vis, Vector3(0.5, 0.3, 1.5), Vector3(0.55, 0.5, 0.4), paint)
	mesh_box(car_vis, Vector3(0.5, 0.3, 1.5), Vector3(-0.55, 0.5, 0.4), paint)
	mesh_box(car_vis, Vector3(0.35, 0.45, 0.6), Vector3(0, 0.85, 0.8), red)
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	var helmet := MeshInstance3D.new()
	helmet.mesh = sph
	helmet.material_override = red
	helmet.scale = Vector3(0.35, 0.35, 0.4)
	helmet.position = Vector3(0, 0.72, 0.2)
	car_vis.add_child(helmet)
	mesh_box(car_vis, Vector3(2.0, 0.05, 0.55), Vector3(0, 0.28, -2.15), black)
	mesh_box(car_vis, Vector3(0.05, 0.2, 0.55), Vector3(1.0, 0.36, -2.15), black)
	mesh_box(car_vis, Vector3(0.05, 0.2, 0.55), Vector3(-1.0, 0.36, -2.15), black)
	mesh_box(car_vis, Vector3(1.3, 0.05, 0.6), Vector3(0, 1.15, 2.0), black)
	mesh_box(car_vis, Vector3(0.05, 0.4, 0.6), Vector3(0.65, 1.0, 2.0), black)
	mesh_box(car_vis, Vector3(0.05, 0.4, 0.6), Vector3(-0.65, 1.0, 2.0), black)
	mesh_box(car_vis, Vector3(0.06, 0.45, 0.2), Vector3(0, 0.85, 2.0), black)


func build_sky_body() -> void:
	var paint := make_mat(cs["color"], 0.15, 0.9)
	paint.clearcoat_enabled = true
	var glass := make_mat(Color(0.03, 0.05, 0.08), 0.03, 0.4)
	var neon := glow_mat(Color(0.3, 0.9, 1.0), 5.0)
	var cap := CapsuleMesh.new()
	cap.radius = 0.5
	cap.height = 4.4
	var body := MeshInstance3D.new()
	body.mesh = cap
	body.material_override = paint
	body.rotation_degrees = Vector3(90, 0, 0)
	body.scale = Vector3(1.8, 1.0, 0.35)
	body.position = Vector3(0, 0.55, 0)
	car_vis.add_child(body)
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	var dome := MeshInstance3D.new()
	dome.mesh = sph
	dome.material_override = glass
	dome.scale = Vector3(1.3, 0.42, 2.3)
	dome.position = Vector3(0, 0.88, 0)
	car_vis.add_child(dome)
	mesh_box(car_vis, Vector3(3.0, 0.05, 1.3), Vector3(0, 0.5, 0.9), paint)
	mesh_box(car_vis, Vector3(0.08, 0.08, 1.3), Vector3(1.5, 0.52, 0.9), neon)
	mesh_box(car_vis, Vector3(0.08, 0.08, 1.3), Vector3(-1.5, 0.52, 0.9), neon)
	mesh_box(car_vis, Vector3(0.05, 0.55, 0.8), Vector3(0.5, 1.0, 1.9), paint)
	mesh_box(car_vis, Vector3(0.05, 0.55, 0.8), Vector3(-0.5, 1.0, 1.9), paint)
	mesh_box(car_vis, Vector3(1.4, 0.03, 3.0), Vector3(0, 0.2, 0), neon)
	for sx in [-0.6, 0.6]:
		for sz in [-1.4, 1.4]:
			var th := make_flame(Vector3(sx, 0.28, sz))
			th.direction = Vector3.DOWN
			th.spread = 10.0
			th.initial_velocity_min = 5.0
			th.initial_velocity_max = 8.0
			car_vis.add_child(th)
			thrusters.append(th)


func build_drift_extras() -> void:
	var black := make_mat(Color(0.03, 0.03, 0.03), 0.6)
	var neon := glow_mat(Color(1.0, 0.2, 0.8), 4.0)
	mesh_box(car_vis, Vector3(2.1, 0.06, 0.55), Vector3(0, 1.58, 2.0), black)
	mesh_box(car_vis, Vector3(0.07, 0.5, 0.25), Vector3(0.7, 1.3, 2.0), black)
	mesh_box(car_vis, Vector3(0.07, 0.5, 0.25), Vector3(-0.7, 1.3, 2.0), black)
	mesh_box(car_vis, Vector3(0.05, 0.3, 0.55), Vector3(1.05, 1.5, 2.0), black)
	mesh_box(car_vis, Vector3(0.05, 0.3, 0.55), Vector3(-1.05, 1.5, 2.0), black)
	mesh_box(car_vis, Vector3(0.3, 0.04, 0.3), Vector3(1.0, 0.55, -1.9), black)
	mesh_box(car_vis, Vector3(0.3, 0.04, 0.3), Vector3(-1.0, 0.55, -1.9), black)
	for sx in [-1.0, 1.0]:
		for sz in [-1.4, 1.4]:
			mesh_box(car_vis, Vector3(0.15, 0.12, 1.0), Vector3(1.0 * sx, 0.62, sz), black)
	mesh_box(car_vis, Vector3(1.7, 0.02, 3.4), Vector3(0, 0.2, 0), neon)


func set_flying(on: bool) -> void:
	flying = on
	if on:
		ball.axis_lock_linear_y = false
		ball.gravity_scale = 0.0
		fly_hold_y = ball.global_position.y + 12.0
	else:
		ball.gravity_scale = 1.0


func toggle_shop() -> void:
	shop_open = not shop_open
	shop_layer.visible = shop_open
	ball.freeze = shop_open
	if shop_open:
		nitro_on = false
		refresh_shop()


func build_shop() -> void:
	shop_layer = CanvasLayer.new()
	shop_layer.layer = 10
	add_child(shop_layer)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_layer.add_child(bg)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(cc)
	var panel := PanelContainer.new()
	cc.add_child(panel)
	var margin := MarginContainer.new()
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 24)
	panel.add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	margin.add_child(vb)
	var title := Label.new()
	title.text = "GARAGE & SHOP"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	money_label = Label.new()
	money_label.add_theme_font_size_override("font_size", 20)
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(money_label)
	var hb := GridContainer.new()
	hb.columns = 4
	hb.add_theme_constant_override("h_separation", 24)
	hb.add_theme_constant_override("v_separation", 18)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1120, 360)
	vb.add_child(scroll)
	scroll.add_child(hb)
	for i in CARS.size():
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(250, 0)
		card.add_theme_constant_override("separation", 8)
		hb.add_child(card)
		var nl := Label.new()
		nl.text = CARS[i]["name"]
		nl.add_theme_font_size_override("font_size", 28)
		card.add_child(nl)
		var dl := Label.new()
		dl.text = CARS[i]["desc"]
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(dl)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.pressed.connect(_on_car_button.bind(i))
		card.add_child(btn)
		shop_buttons.append(btn)
	pit_btn = Button.new()
	pit_btn.custom_minimum_size = Vector2(0, 44)
	pit_btn.pressed.connect(_on_pit)
	vb.add_child(pit_btn)
	var close := Button.new()
	close.text = "RACE  (B)"
	close.custom_minimum_size = Vector2(0, 50)
	close.pressed.connect(toggle_shop)
	vb.add_child(close)


func refresh_shop() -> void:
	money_label.text = "Credits: $%d     (earn credits by driving, drifting and finishing laps)" % money
	var pc := pit_cost()
	pit_btn.text = "PIT STOP: refuel/charge, new tyres, repairs  ($%d)" % pc if pc > 0 else "PIT STOP: nothing needed"
	pit_btn.disabled = pc <= 0 or money < pc
	for i in CARS.size():
		var b := shop_buttons[i]
		if car_type == i:
			b.text = "EQUIPPED"
			b.disabled = true
		elif owned[i]:
			b.text = "SELECT"
			b.disabled = false
		else:
			b.text = "BUY  $%d" % CARS[i]["price"]
			b.disabled = money < CARS[i]["price"]


func _on_car_button(i: int) -> void:
	if not owned[i]:
		if money < CARS[i]["price"]:
			return
		money -= CARS[i]["price"]
		owned[i] = true
	car_type = i
	cs = CARS[i]
	car_mass = float(cs["mass"])
	ball.mass = car_mass
	set_flying(false)
	build_car_visual()
	refresh_shop()


func pit_cost() -> int:
	return int((1.0 - fuel) * 150.0 + (1.0 - tires) * 250.0 + (100.0 - car_hp) * 6.0)


func _on_pit() -> void:
	var pc := pit_cost()
	if pc <= 0 or money < pc:
		return
	money -= pc
	fuel = 1.0
	tires = 1.0
	car_hp = 100.0
	brake_temp = 0.0
	refresh_shop()


func shop_cam(delta: float) -> void:
	shop_ang += delta * 0.6
	var base := ball.global_position
	car_vis.global_transform = Transform3D(Basis(Vector3.UP, yaw), base - Vector3(0, BALL_R, 0))
	cam.global_position = base + Vector3(cos(shop_ang) * 8.0, 2.6, sin(shop_ang) * 8.0)
	cam.look_at(base + Vector3(0, 0.7, 0), Vector3.UP)
	cam.h_offset = 0.0
	cam.v_offset = 0.0
	cam.fov = 60.0


func add_skid(pos: Vector3) -> void:
	if skid_mesh == null:
		var bm := BoxMesh.new()
		bm.size = Vector3(0.3, 0.01, 0.7)
		skid_mesh = bm
		skid_mat = StandardMaterial3D.new()
		skid_mat.albedo_color = Color(0.02, 0.02, 0.02, 0.6)
		skid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		skid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var node: MeshInstance3D
	if skid_nodes.size() >= 300:
		node = skid_nodes.pop_front()
	else:
		node = MeshInstance3D.new()
		node.mesh = skid_mesh
		node.material_override = skid_mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
	node.global_transform = Transform3D(Basis(Vector3.UP, yaw), pos)
	skid_nodes.append(node)


func update_camera(delta: float, speed_ms: float, speed_kmh: float, fwd_speed: float, h: Vector3, vh: Vector3) -> void:
	if cam_mode == 2:
		cam.global_transform = car_vis.global_transform * Transform3D(Basis(), Vector3(0, 0.6, -2.4))
		cam.fov = lerpf(cam.fov, 80.0 + speed_kmh * 0.1, clampf(3.0 * delta, 0.0, 1.0))
		cam.h_offset = 0.0
		cam.v_offset = 0.0
		return
	if cam_mode == 1:
		cam.global_transform = car_vis.global_transform * Transform3D(Basis(), Vector3(-0.35, 1.2, -0.15))
		cam.fov = lerpf(cam.fov, 78.0 + speed_kmh * 0.1, clampf(3.0 * delta, 0.0, 1.0))
		return
	var target_dir := h
	if speed_ms > 6.0 and fwd_speed > 0.0:
		target_dir = h.slerp(vh.normalized(), 0.35).normalized()
	cam_dir = cam_dir.slerp(target_dir, clampf(4.0 * delta, 0.0, 1.0)).normalized()
	var base := ball.global_position
	cam.global_position = base - cam_dir * (7.0 + speed_ms * 0.02) + Vector3(0, 2.2, 0)
	cam.look_at(base + Vector3(0, 0.2, 0) + cam_dir * 3.0, Vector3.UP)
	cam.fov = lerpf(cam.fov, 68.0 + speed_kmh * 0.18 + (14.0 if nitro_on else 0.0), clampf(3.0 * delta, 0.0, 1.0))
	var shake := clampf(speed_ms / 80.0, 0.0, 1.0) * (0.06 if nitro_on else 0.03) + impact_vis * 0.25 + kerb_vis * 0.12
	cam.h_offset = randf_range(-1.0, 1.0) * shake
	cam.v_offset = randf_range(-1.0, 1.0) * shake


# ------------------------------------------------------------ engine sound
@warning_ignore("integer_division")
func fill_music() -> void:
	if m_pb == null or not music_on:
		return
	var step_len := int(MUSIC_RATE * 60.0 / BPM / 4.0)
	var avail := mini(m_pb.get_frames_available(), 1024)
	for i in avail:
		var step_i := m_pos / step_len
		var step := step_i % 16
		var bar := (step_i / 16) % 4
		var t := float(m_pos % step_len) / MUSIC_RATE
		var chord: Array = CHORDS[bar]
		var s := 0.0
		if step % 4 == 0 and t < 0.3:
			s += sin(TAU * (45.0 * t + 3.33 * (1.0 - exp(-t * 30.0)))) * exp(-t * 9.0) * 0.9
		if (step == 4 or step == 12) and t < 0.25:
			s += (randf() * 2.0 - 1.0) * exp(-t * 14.0) * 0.3 + sin(TAU * 190.0 * t) * exp(-t * 20.0) * 0.2
		if step % 4 == 2:
			s += (randf() * 2.0 - 1.0) * exp(-t * 16.0) * 0.1
		elif step % 2 == 1:
			s += (randf() * 2.0 - 1.0) * exp(-t * 60.0) * 0.07
		if BASS_STEPS.has(step):
			var bf: float = BASS_ROOTS[bar]
			m_ph_bass = fposmod(m_ph_bass + bf / MUSIC_RATE, 1.0)
			s += ((m_ph_bass * 2.0 - 1.0) * 0.5 + sin(TAU * m_ph_bass) * 0.5) * exp(-t * 5.0) * 0.32
		var af: float = float(chord[step % 3]) * 2.0 * (2.0 if (step / 4) % 2 == 1 else 1.0)
		m_ph_arp = fposmod(m_ph_arp + af / MUSIC_RATE, 1.0)
		s += (absf(m_ph_arp * 4.0 - 2.0) - 1.0) * exp(-t * 9.0) * 0.1
		for k in 3:
			m_ph_pad[k] = fposmod(m_ph_pad[k] + float(chord[k]) / MUSIC_RATE, 1.0)
			s += sin(TAU * m_ph_pad[k]) * 0.035
		s = tanh(s * 1.1)
		m_pb.push_frame(Vector2(s, s) * 0.55)
		m_pos += 1


func _process(_delta: float) -> void:
	fill_music()
	var pdt := get_process_delta_time()
	update_tod(pdt)
	# Lightning flashes during rain
	if rain_on:
		next_bolt -= pdt
		if next_bolt <= 0.0:
			lightning_t = 0.3
			next_bolt = randf_range(6.0, 20.0)
	lightning_t = maxf(0.0, lightning_t - pdt)
	if lightning_t > 0.0:
		env_ref.ambient_light_energy += lightning_t * randf_range(3.0, 8.0)
	if firework_t > 0.0:
		firework_t -= pdt
		next_fw -= pdt
		if next_fw <= 0.0:
			next_fw = 0.3
			firework(ball.global_position + Vector3(randf_range(-50.0, 50.0), randf_range(25.0, 50.0), randf_range(-50.0, 50.0)))
	if pb == null:
		return
	var freq := rpm_vis / float(cs["snd"])
	var vol := (0.10 + 0.16 * throttle_vis + (0.08 if nitro_on else 0.0)) * float(cs["vol"]) * (1.4 if tunnel_on else 1.0)
	var avail := mini(pb.get_frames_available(), 2048)
	for i in avail:
		phase = fposmod(phase + freq / 22050.0, 1.0)
		var saw := phase * 2.0 - 1.0
		var s := 0.55 * sin(TAU * phase) + 0.25 * sin(TAU * 2.0 * phase) + float(cs["saw"]) * saw
		if cs["ev"]:
			s = 0.5 * sin(TAU * phase) + 0.15 * sin(TAU * 3.0 * phase)
		s += (randf() * 2.0 - 1.0) * 0.04
		s *= vol
		s += (randf() * 2.0 - 1.0) * (wind_vis * 0.05 + squeal_vis * 0.12 + (0.06 if nitro_on else 0.0) + impact_vis * 0.5 + wet * 0.03 + kerb_vis * 0.06 + bov_t * 0.6 + backfire_t * 2.0 + lightning_t * 0.5)
		turbo_ph = fposmod(turbo_ph + (1200.0 + boost * 2600.0) / 22050.0, 1.0)
		s += sin(TAU * turbo_ph) * boost * 0.03
		pb.push_frame(Vector2(s, s))


# ------------------------------------------------------------ HUD
class Hud extends Control:
	var speed := 0.0
	var rpm := 0.0
	var gear_txt := "1"
	var lap := 0
	var lap_time := 0.0
	var best := -1.0
	var last := -1.0
	var off_road := false
	var nitro := 1.0
	var nitro_on := false
	var track := PackedVector2Array()
	var money := 0
	var flying := false
	var alt := 0.0
	var car_name := ""
	var fuel := 1.0
	var tires := 1.0
	var brake_t := 0.0
	var hp := 100.0
	var race_pos := 1
	var rain := false
	var ev := false
	var ai_pos := PackedVector2Array()
	var car_pos := Vector2.ZERO
	var draft := 0.0
	var abs_on := true
	var tc_on := false
	var tire_temp := 0.3
	var countdown := 0.0
	var finished := false
	var finish_pos := 0
	var race_laps := 3
	var broken_t := 0.0
	var drift_pts := 0.0
	var drift_combo := 1.0
	var drift_bank := 0
	var drift_bank_t := 0.0
	var pad_t := 0.0
	var g_lat := 0.0
	var g_long := 0.0
	var use_mph := false
	var tyre_c := 1
	var drops: Array[Vector3] = []
	var cones := 0
	var puddle := false
	const TYRE_NAMES_H := ["SOFT", "MEDIUM", "HARD"]

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func fmt(t: float) -> String:
		if t < 0.0:
			return "--:--.---"
		var m := int(t / 60.0)
		return "%d:%06.3f" % [m, t - m * 60.0]

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		# speed lines
		var si := clampf((speed - 170.0) / 150.0, 0.0, 1.0) + (0.4 if nitro_on else 0.0)
		si = clampf(si, 0.0, 1.0)
		if si > 0.05:
			var cc := size * 0.5
			for k in int(30.0 * si):
				var ang := randf() * TAU
				var r0 := size.length() * randf_range(0.30, 0.42)
				var dd := Vector2(cos(ang), sin(ang))
				draw_line(cc + dd * r0, cc + dd * (r0 + randf_range(40.0, 120.0)), Color(1, 1, 1, 0.05 + 0.15 * si), 2.0)
		# ---- analog speedometer (0-360 km/h) ----
		var c := Vector2(size.x - 190.0, size.y - 190.0)
		draw_circle(c, 150.0, Color(0, 0, 0, 0.6))
		draw_arc(c, 148.0, 0.0, TAU, 64, Color(1, 1, 1, 0.3), 3.0)
		for k in range(0, 19):
			var tv := k * 20.0
			var ta := deg_to_rad(135.0 + 270.0 * tv / 360.0)
			var td := Vector2(cos(ta), sin(ta))
			var major := k % 2 == 0
			draw_line(c + td * (116.0 if major else 126.0), c + td * 136.0, Color.WHITE if major else Color(1, 1, 1, 0.5), 3.0 if major else 1.5)
			if major:
				draw_string(font, c + td * 97.0 + Vector2(-20, 6), "%d" % int(tv), HORIZONTAL_ALIGNMENT_CENTER, 40, 15, Color(0.9, 0.9, 0.9))
		var sp_f := clampf(speed / 360.0, 0.0, 1.0)
		var sp_col := Color(0.2, 0.8, 1.0) if sp_f < 0.75 else Color(1.0, 0.3, 0.15)
		draw_arc(c, 144.0, deg_to_rad(135.0), deg_to_rad(135.0 + 270.0 * sp_f), 64, sp_col, 6.0)
		# inner rev arc
		var rpm_f := clampf(rpm / 8000.0, 0.0, 1.0)
		var rpm_col := Color(1.0, 0.85, 0.2) if rpm < 6500.0 else Color(1.0, 0.2, 0.1)
		draw_arc(c, 66.0, deg_to_rad(135.0), deg_to_rad(405.0), 48, Color(1, 1, 1, 0.12), 8.0)
		draw_arc(c, 66.0, deg_to_rad(135.0), deg_to_rad(135.0 + 270.0 * rpm_f), 48, rpm_col, 8.0)
		# needle
		var na := deg_to_rad(135.0 + 270.0 * sp_f)
		var nd := Vector2(cos(na), sin(na))
		draw_line(c - nd * 14.0, c + nd * 122.0, Color(1.0, 0.2, 0.1), 4.0)
		draw_circle(c, 9.0, Color(0.15, 0.15, 0.17))
		# digital readout + gear
		draw_string(font, c + Vector2(-80, 68), "%d" % int(speed * (0.621371 if use_mph else 1.0)), HORIZONTAL_ALIGNMENT_CENTER, 160, 40, Color.WHITE)
		draw_string(font, c + Vector2(-80, 88), "mph" if use_mph else "km/h", HORIZONTAL_ALIGNMENT_CENTER, 160, 14, Color(0.8, 0.8, 0.8))
		draw_string(font, c + Vector2(-80, 125), "GEAR " + gear_txt, HORIZONTAL_ALIGNMENT_CENTER, 160, 24, Color(1, 0.85, 0.2))
		# ---- nitro gauge ----
		var nc := c + Vector2(-290.0, 55.0)
		draw_circle(nc, 95.0, Color(0, 0, 0, 0.6))
		draw_arc(nc, 80.0, deg_to_rad(135.0), deg_to_rad(405.0), 48, Color(1, 1, 1, 0.15), 14.0)
		var ncol := Color(0.4, 0.9, 1.0) if nitro_on else (Color(0.1, 0.45, 0.9) if nitro >= 0.15 else Color(1.0, 0.5, 0.1))
		if nitro > 0.01:
			draw_arc(nc, 80.0, deg_to_rad(135.0), deg_to_rad(135.0 + 270.0 * nitro), 48, ncol, 14.0)
		draw_string(font, nc + Vector2(-60, -2), "%d%%" % int(nitro * 100.0), HORIZONTAL_ALIGNMENT_CENTER, 120, 34, Color.WHITE)
		var nstat := "BOOSTING" if nitro_on else ("READY" if nitro >= 0.999 else "RECHARGING")
		draw_string(font, nc + Vector2(-60, 24), nstat, HORIZONTAL_ALIGNMENT_CENTER, 120, 15, ncol)
		draw_string(font, nc + Vector2(-60, 60), "NITRO [Shift]", HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color(0.8, 0.8, 0.8))
		draw_string(font, Vector2(24, 42), "LAP %d/%d    %s" % [mini(lap + 1, race_laps), race_laps, fmt(lap_time)], HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
		draw_string(font, Vector2(24, 76), "Last %s    Best %s" % [fmt(last), fmt(best)], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.85, 0.85, 0.85))
		draw_string(font, Vector2(24, size.y - 42), "W/S gas-brake  A/D steer  Space handbrake  Shift nitro  C camera  B shop  F fly  M music  T time  X rain", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.7))
		draw_string(font, Vector2(24, size.y - 20), "G manual (Q/E)  H explode  Z ABS  V traction control  L lights  R respawn  N restart race", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.7))
		draw_string(font, Vector2(24, 106), "$ %d    %s" % [money, car_name], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.5, 1.0, 0.5))
		if flying:
			draw_string(font, Vector2(0, 170), "FLIGHT MODE    ALT %d m" % int(alt), HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Color(0.5, 0.9, 1.0))
			draw_string(font, Vector2(0, 198), "Space up   Ctrl down   F stop flying", HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color(0.8, 0.9, 1.0))
		draw_string(font, Vector2(24, 140), "POS %d / %d" % [race_pos, ai_pos.size() + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 0.85, 0.2))
		if rain:
			draw_string(font, Vector2(24, 166), "RAIN - wet track", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.8, 1.0))
		if fuel < 0.12:
			draw_string(font, Vector2(0, 230), "OUT OF POWER - PIT (B)" if fuel <= 0.0 else "LOW FUEL / BATTERY", HORIZONTAL_ALIGNMENT_CENTER, size.x, 26, Color(1, 0.3, 0.2))
		var bars := [
			["BATTERY" if ev else "FUEL", fuel, Color(1, 0.3, 0.2) if fuel < 0.15 else Color(0.3, 0.7, 1.0)],
			["TYRES", tires, Color(0.4, 0.9, 0.4)],
			["BRAKES", brake_t, Color(1.0, 0.5, 0.2)],
			["DAMAGE", 1.0 - hp / 100.0, Color(1.0, 0.3, 0.3)],
			["TYRE TEMP", tire_temp, Color(0.3, 0.6, 1.0).lerp(Color(1.0, 0.3, 0.2), tire_temp)],
		]
		for bi in bars.size():
			var by := size.y - 188.0 + bi * 26.0
			draw_string(font, Vector2(24, by + 13), bars[bi][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.85, 0.85))
			draw_rect(Rect2(100, by, 140, 14), Color(0, 0, 0, 0.5))
			draw_rect(Rect2(100, by, 140.0 * clampf(float(bars[bi][1]), 0.0, 1.0), 14), bars[bi][2])
		# shift lights
		for li in 10:
			var on_l := rpm / 8000.0 > 0.62 + li * 0.035
			var lc: Color
			if li < 4:
				lc = Color(0.2, 1.0, 0.3)
			elif li < 7:
				lc = Color(1.0, 0.85, 0.1)
			else:
				lc = Color(1.0, 0.15, 0.1)
			draw_circle(Vector2(size.x * 0.5 - 112.0 + li * 25.0, 22.0), 9.0, lc if on_l else Color(0.15, 0.15, 0.15, 0.7))
		# driver aids
		draw_string(font, Vector2(24, 192), "ABS " + ("ON" if abs_on else "OFF") + "    TC " + ("ON" if tc_on else "OFF"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.9, 1.0))
		if draft > 0.15:
			draw_string(font, Vector2(0, 150), "SLIPSTREAM", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color(0.5, 1.0, 0.7))
		# start lights / finish
		if countdown > 0.0:
			draw_string(font, Vector2(0, size.y * 0.38), str(ceili(countdown)), HORIZONTAL_ALIGNMENT_CENTER, size.x, 140, Color(1.0, 0.85, 0.2))
		elif countdown > -1.0:
			draw_string(font, Vector2(0, size.y * 0.38), "GO!", HORIZONTAL_ALIGNMENT_CENTER, size.x, 140, Color(0.3, 1.0, 0.4))
		if finished:
			var prizes := [5000, 3000, 1500, 500]
			var prize: int = prizes[clampi(finish_pos - 1, 0, 3)]
			draw_string(font, Vector2(0, size.y * 0.3), "RACE FINISHED - P%d   +$%d" % [finish_pos, prize], HORIZONTAL_ALIGNMENT_CENTER, size.x, 44, Color(1.0, 0.85, 0.2))
			draw_string(font, Vector2(0, size.y * 0.3 + 34.0), "Press N to race again", HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color(0.9, 0.9, 0.9))
		if broken_t > 0.0:
			draw_string(font, Vector2(0, 262), "CAR DAMAGED - auto-repair $2000 in %d s (or explodes if broke). Pit (B) repairs for less" % int(180.0 - broken_t), HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color(1.0, 0.6, 0.2))
		if drift_pts > 1.0:
			draw_string(font, Vector2(0, 310), "DRIFT  %d   x%.1f" % [int(drift_pts), drift_combo], HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, Color(1.0, 0.85, 0.2))
		elif drift_bank_t > 0.0:
			draw_string(font, Vector2(0, 310), "+$%d DRIFT BANKED" % drift_bank, HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, Color(0.4, 1.0, 0.5))
		if pad_t > 0.0:
			draw_string(font, Vector2(0, 350), "BOOST PAD! NITRO REFILLED", HORIZONTAL_ALIGNMENT_CENTER, size.x, 26, Color(0.4, 0.9, 1.0))
		draw_string(font, Vector2(24, 238), "PROPS SMASHED: %d" % cones, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.7, 0.3))
		if puddle:
			draw_string(font, Vector2(0, 390), "AQUAPLANING!", HORIZONTAL_ALIGNMENT_CENTER, size.x, 36, Color(0.5, 0.8, 1.0))
		# tyre compound
		var tcol := Color(1.0, 0.3, 0.3) if tyre_c == 0 else (Color(1.0, 0.9, 0.3) if tyre_c == 1 else Color(0.9, 0.9, 0.9))
		draw_string(font, Vector2(24, 214), "COMPOUND: %s  (Y change at standstill, $200)   U mph/kmh" % TYRE_NAMES_H[tyre_c], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, tcol)
		# g-force meter
		var gc := Vector2(size.x * 0.5, size.y - 120.0)
		draw_circle(gc, 52.0, Color(0, 0, 0, 0.45))
		draw_arc(gc, 52.0, 0.0, TAU, 40, Color(1, 1, 1, 0.35), 2.0)
		draw_arc(gc, 26.0, 0.0, TAU, 32, Color(1, 1, 1, 0.15), 1.0)
		draw_line(gc - Vector2(52, 0), gc + Vector2(52, 0), Color(1, 1, 1, 0.15), 1.0)
		draw_line(gc - Vector2(0, 52), gc + Vector2(0, 52), Color(1, 1, 1, 0.15), 1.0)
		var gp := Vector2(clampf(g_lat, -2.0, 2.0), clampf(g_long, -2.0, 2.0)) * 26.0
		draw_circle(gc + gp, 6.0, Color(1.0, 0.4, 0.2))
		draw_string(font, gc + Vector2(-52, 70), "%.1f G" % Vector2(g_lat, g_long).length(), HORIZONTAL_ALIGNMENT_CENTER, 104, 14, Color(0.9, 0.9, 0.9))
		# rain on the lens
		if rain and drops.size() < 90 and randf() < 0.6:
			drops.append(Vector3(randf() * size.x, randf() * size.y, 1.0))
		var di := drops.size() - 1
		while di >= 0:
			var dr := drops[di]
			dr.z -= (0.004 if rain else 0.03)
			dr.y += speed * 0.004
			drops[di] = dr
			if dr.z <= 0.0 or dr.y > size.y:
				drops.remove_at(di)
			else:
				var rr := 3.0 + float(int(dr.x) % 5)
				draw_circle(Vector2(dr.x, dr.y), rr, Color(0.75, 0.85, 1.0, 0.12 * minf(dr.z * 2.0, 1.0)))
				draw_circle(Vector2(dr.x - rr * 0.3, dr.y - rr * 0.3), rr * 0.35, Color(1, 1, 1, 0.3 * minf(dr.z * 2.0, 1.0)))
			di -= 1
		# minimap
		var mo := Vector2(size.x - 120.0, 90.0)
		draw_rect(Rect2(mo - Vector2(100, 70), Vector2(200, 140)), Color(0, 0, 0, 0.35))
		var mp := PackedVector2Array()
		for tp in track:
			mp.append(mo + tp * 0.18)
		if track.size() > 0:
			mp.append(mo + track[0] * 0.18)
			draw_polyline(mp, Color(1, 1, 1, 0.6), 5.0)
		for aip in ai_pos:
			draw_circle(mo + aip * 0.18, 4.0, Color(0.3, 0.6, 1.0))
		draw_circle(mo + car_pos * 0.18, 6.0, Color(1, 0.2, 0.2))
		if off_road:
			draw_string(font, Vector2(0, 120), "OFF TRACK", HORIZONTAL_ALIGNMENT_CENTER, size.x, 36, Color(1, 0.3, 0.2))
