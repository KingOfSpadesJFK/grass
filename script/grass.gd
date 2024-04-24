extends MultiMeshInstance3D

const FILL_LENGTH = 1
const GROUP_SIZE = 1

## Path to the compute shader that calculates the blade positions
@export var shader_path = "res://shader/grass_position.glsl"

## The mesh for the blades of grass
@export var mesh: Mesh

## How big the grass field is in the X and Z direction
@export var size: Vector2 = Vector2(1, 1)

## How many blades of grass fill the X and Z directions
@export var density: Vector2i = Vector2(32, 32)

var render_device
var shader
var blade_positions: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	render_device = RenderingServer.create_local_rendering_device()
	var sf = load(shader_path)
	var spirv: RDShaderSPIRV = sf.get_spirv()
	shader = render_device.shader_create_from_spirv(spirv)

	# Create the multimesh.
	multimesh = MultiMesh.new()
	multimesh.mesh = mesh;
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = density.x * density.y
	multimesh.visible_instance_count = -1
	# multimesh.set_instance_transform(0, Transform3D(Basis(), Vector3(0, 0, 0)))

	# Fill the blade_positions array with 0
	blade_positions.resize(density.x * density.y * 4)
	blade_positions.fill(0)
	blade_positions = compute_blade_positions()

	# Set the transform of the instances.
	for i in range(density.x):
		for j in range(density.y):
			var index = i * density.y + j
			var pos = Vector2(blade_positions[index*4], blade_positions[index*4+2])
			multimesh.set_instance_transform(index, 
					Transform3D(Basis(), 
					Vector3(pos.x, 0, pos.y)))


func _process(_delta: float) -> void:
	pass

# Create a uniform to assign the buffer to the rendering device
func create_uniform(data, type, binding: int) -> RDUniform:
	var uniform = RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = binding
	uniform.add_id(data)
	return uniform

# Called every frame. 'delta' is the elapsed time since the previous frame.
func compute_blade_positions() -> Array:
	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var arr = [size.x, size.y]
	var input = PackedFloat32Array(arr)
	var input_bytes = input.to_byte_array()

	# Create a storage buffer that can hold our float values.
	# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
	arr.resize(density.x * density.y * 4)
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
	render_device.compute_list_dispatch(compute_list, density.x/GROUP_SIZE, density.y/GROUP_SIZE, 1)
	render_device.compute_list_end()

	# Submit to GPU and wait for sync
	render_device.submit()
	render_device.sync()

	# Read back the data from the buffer
	var output_bytes = render_device.buffer_get_data(outBuffer)
	return output_bytes.to_float32_array()
