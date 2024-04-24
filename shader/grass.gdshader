shader_type spatial;
render_mode cull_disabled;

instance uniform vec3 grass_color : source_color = vec3(.45, 0.752, 0.24);
instance uniform vec3 grass_highlight : source_color = vec3(.836, 0.753, 0.157);

void vertex() {
	// Called for every vertex the material is visible on.
	mat4 modelView = MODELVIEW_MATRIX;
	
  	// X
	modelView[0][0] = -1.0; 
	modelView[0][1] = 0.0; 
	modelView[0][2] = 0.0;
	// Clamp the Y Collumn, so that looking directly up will still have some thickness
	modelView[1][0] = 0.0; 
	modelView[1][1] = clamp(modelView[1][1], 0.125, 1.0); 
	modelView[1][2] = 0.0;
	// Z
	modelView[2][0] = 0.0; 
	modelView[2][1] = 0.0; 
	modelView[2][2] = -1.0; 
	  
	vec4 P = modelView * vec4(VERTEX, 1);
	P.z = P.z + sin(TIME)/10.f*VERTEX.y;
	POSITION = PROJECTION_MATRIX * P;
	UV.x *= UV.y;
	UV.y = mix(1.f, 0.0f, 1.f-VERTEX.y);
		
}

void fragment() {
	// Called for every pixel the material is visible on.
	float f = UV.x * UV.y;
	ALBEDO = mix(grass_color, grass_highlight, f*f);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}