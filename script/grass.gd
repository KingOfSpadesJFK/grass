extends Node3D

const FILL_LENGTH = 1
const GROUP_SIZE = 1

## Path to the compute shader that calculates the blade positions
@export var shader_path = "res://shader/grass_position.glsl"

## The mesh for the blades of grass
@export var mesh: Mesh

## How big the grass field is in the X and Z direction
@export var size: float = 30

## How many blades of grass fill the X and Z directions
@export var density: int = 1

## How far the camera has to move before the grass updates
@export var update_distance: float = 2.0

## The camera path to get the camera position
@export var camera_path: NodePath

@export var floor_mesh: Mesh

@export var show_floor_mesh: bool

## The angle (in degrees) the wind is facing
@export var wind_direction: float = 0.0

## How strong the wind should be
@export var wind_strength: float = 1.0

var render_device
var shader
var multimesh: MultiMesh
var camera: Camera3D
var grass_center = Vector2(0, 0)
var wave_time: float = 0.0;
var shader_wave_time: float = 0.0;
var shader_wind_strength: float = 1.0;
var shader_wind_direction: float = 0.0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get the camera
	camera = get_node(camera_path)
	# if camera:
	var step = 1.0 / (float(density));
	grass_center.x = floor((camera.global_position.x - size / 2.0) / step) * step
	grass_center.y = floor((camera.global_position.z - size / 2.0) / step) * step

	# Set up the rendering device
	render_device = RenderingServer.create_local_rendering_device()
	var sf = load(shader_path)
	var spirv: RDShaderSPIRV = sf.get_spirv()
	shader = render_device.shader_create_from_spirv(spirv)

	# Create the multimesh.
	multimesh = MultiMesh.new()
	multimesh.mesh = mesh;
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = density * density * floor(size * size)
	multimesh.visible_instance_count = set_blade_positions(compute_blade_positions())
	$MultiMeshInstance0.multimesh = multimesh
	$MultiMeshInstance0.set_instance_shader_parameter("grass_size", size)
	$MultiMeshInstance0.set_instance_shader_parameter("grass_density", float(density))


func _process(_delta: float) -> void:
	# Update the blade positions
	var step = 1.0 / (float(density));
	if position.distance_to(camera.global_position) > update_distance:
		position.x = floor(camera.global_position.x / step) * step
		position.z = floor(camera.global_position.z / step) * step

	wind_strength = sin(wave_time) * 0.5 + 0.5
	wind_strength *= 20.0
	wind_direction += _delta * 10.0
	wave_time += _delta

	# Update the shader uniforms
	shader_wave_time += _delta * shader_wind_strength
	shader_wind_strength = lerpf(shader_wind_strength, wind_strength, _delta * 2.0)
	shader_wind_direction = lerpf(shader_wind_direction, wind_direction, _delta * 2.0)
	$MultiMeshInstance0.set_instance_shader_parameter("wave_time", shader_wave_time)
	$MultiMeshInstance0.set_instance_shader_parameter("wind_direction", shader_wind_direction)
	$MultiMeshInstance0.set_instance_shader_parameter("wind_strength", shader_wind_strength)

# Create a uniform to assign the buffer to the rendering device
func create_uniform(data, type, binding: int) -> RDUniform:
	var uniform = RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = binding
	uniform.add_id(data)
	return uniform


func set_blade_positions(blade_positions) -> int:
	# Set the transform of the instances.
	var k = 0
	for i in range(density * size):
		for j in range(density * size):
			var index = i * density * size + j
			# Skip this blade if it's not visible
			if (blade_positions[index*4+3] < 1.0):
				continue
			var pos = Vector3(blade_positions[index*4], blade_positions[index*4+1], blade_positions[index*4+2])
			multimesh.set_instance_transform(k, 
					Transform3D(Basis(), 
					Vector3(pos.x, pos.y, pos.z)))
			k += 1
	return k


func compute_blade_positions() -> Array:
	# Prepare our data. We use floats in the shader, so we need 32 bit.
	#          vec2 size;  vec2 offset;
	var arr = [size, size, grass_center.x, grass_center.y]
	var input = PackedFloat32Array(arr)
	var input_bytes = input.to_byte_array()

	# Create a storage buffer that can hold our float values.
	# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
	arr.resize(density * density * floor(size * size) * 4)
	arr.fill(0)
	var inBuffer = render_device.storage_buffer_create(input_bytes.size(), input_bytes)
	var outBuffer = render_device.storage_buffer_create(arr.size() * 4, PackedFloat32Array(arr).to_byte_array())

	# Create the uniform sets
	var in_uniform_set = render_device.uniform_set_create([
		create_uniform(inBuffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0),
	], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file
	var out_uniform_set = render_device.uniform_set_create([
		create_uniform(outBuffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0),
	], shader, 1)

	# Create a compute pipeline
	var pipeline = render_device.compute_pipeline_create(shader)
	var compute_list = render_device.compute_list_begin()
	render_device.compute_list_bind_compute_pipeline(compute_list, pipeline)
	render_device.compute_list_bind_uniform_set(compute_list, in_uniform_set, 0)
	render_device.compute_list_bind_uniform_set(compute_list, out_uniform_set, 1)
	render_device.compute_list_dispatch(compute_list, density*size/GROUP_SIZE, density*size/GROUP_SIZE, 1)
	render_device.compute_list_end()

	# Submit to GPU and wait for sync
	render_device.submit()
	render_device.sync()

	# Read back the data from the buffer
	var output_bytes = render_device.buffer_get_data(outBuffer)
	return output_bytes.to_float32_array()
