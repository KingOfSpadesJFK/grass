shader_type spatial;
render_mode cull_disabled;

instance uniform vec3 grass_color : source_color = vec3(.45, 0.752, 0.24);
instance uniform vec3 grass_highlight : source_color = vec3(.836, 0.753, 0.157);

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	// Called for every vertex the material is visible on.
	mat4 modelView = MODELVIEW_MATRIX;
	vec3 modelPosition = vec3(MODEL_MATRIX[3][0], MODEL_MATRIX[3][1], MODEL_MATRIX[3][2]);
	vec2 seed = vec2(rand(modelPosition.xz + NODE_POSITION_WORLD.xz), rand(modelPosition.zx + NODE_POSITION_WORLD.zx));
	
  	// X
	modelView[0][0] = -1.0; 
	modelView[0][1] = 0.0; 
	modelView[0][2] = 0.0;
	// Clamp the Y Collumn, so that looking directly up will still have some thickness
	modelView[1][0] = 0.0; 
	modelView[1][1] = clamp(modelView[1][1], 0.125, 1.0) + seed.x * .25; // Add a perlin noise function
	modelView[1][2] = 0.0;
	// Z
	modelView[2][0] = 0.0; 
	modelView[2][1] = 0.0; 
	modelView[2][2] = -1.0; 
	  
	vec4 P = modelView * vec4(VERTEX, 1);
	P.xz += 0.5f - seed;
	P.z = P.z + sin(TIME+seed.y*PI)/10.f*VERTEX.y;
	POSITION = PROJECTION_MATRIX * P;
	
	// Set the UV for the color
	UV.x *= UV.y;
	UV.y = mix(1.f, 0.0f, 1.f-VERTEX.y);
		
}

void fragment() {
	// Called for every pixel the material is visible on.
	float f = UV.x * UV.y;
	ALBEDO = mix(grass_color, grass_highlight, f*f);
	//ALBEDO = vec3(1,1,1) * f*f;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
