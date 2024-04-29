# GdUnit generated TestSuite
class_name GrassTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://script/grass.gd'


func test_compute_blade_positions() -> void:
	# remove this line and complete your test
	var test_grass = preload(__source).new()
	var packed_arr = test_grass.compute_blade_positions()
	assert_array(packed_arr)
	var arr = []
	arr.resize(packed_arr.size() / 4)
	
	var k = 0
	var size = test_grass.size
	var density = test_grass.density
	for i in range(density * size):
		for j in range(density * size):
			var index = i * density * size + j
			if (packed_arr[index*4+3] < 1.0):
				k += 1
			var pos = Vector3(packed_arr[index*4], packed_arr[index*4+1], packed_arr[index*4+2])
			
	assert_int(k).is_greater(0)
