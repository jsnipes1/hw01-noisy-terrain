#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Sine;

float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

float hash3D(vec3 x)
{
	float i = dot(x, vec3(123.4031, 46.5244876, 91.106168));
	return fract(sin(i * 7.13) * 268573.103291);
}

// 3D noise
float noise(vec3 p) {
  vec3 bCorner = floor(p);
  vec3 inCell = fract(p);

  float bLL = hash3D(bCorner);
  float bUL = hash3D(bCorner + vec3(0.0, 0.0, 1.0));
  float bLR = hash3D(bCorner + vec3(0.0, 1.0, 0.0));
  float bUR = hash3D(bCorner + vec3(0.0, 1.0, 1.0));
  float b0 = mix(bLL, bUL, inCell.z);
  float b1 = mix(bLR, bUR, inCell.z);
  float b = mix(b0, b1, inCell.y);

  vec3 fCorner = bCorner + vec3(1.0, 0.0, 0.0);
  float fLL = hash3D(fCorner);
  float fUL = hash3D(fCorner + vec3(0.0, 0.0, 1.0));
  float fLR = hash3D(fCorner + vec3(0.0, 1.0, 0.0));
  float fUR = hash3D(fCorner + vec3(0.0, 1.0, 1.0));
  float f0 = mix(fLL, fUL, inCell.z);
  float f1 = mix(fLR, fUR, inCell.z);
  float f = mix(f0, f1, inCell.y);

  return mix(b, f, inCell.x);
}

float fbm(vec3 q) {
  float acc = 0.0;
  float freqScale = 2.0;
  float invScale = 1.0 / freqScale;
  float freq = 1.0;
  float amp = 1.0;

  for (int i = 0; i < 5; ++i) {
    freq *= freqScale;
    amp *= invScale;
    acc += noise(q * freq) * amp;
  }
  return acc;
}

void main()
{
  fs_Pos = vs_Pos.xyz + vs_Nor.xyz * fbm(vs_Pos.xyz);
  fs_Col = vec4(fs_Pos, sqrt(fbm(vs_Nor.xyz) * fbm(fs_Pos.xyz)));

  fs_Sine = (sin((vs_Pos.x + u_PlanePos.x) * 0.1) + cos((vs_Pos.z + u_PlanePos.y) * 3.14159 * 0.1) + noise(vs_Pos.xyz)) * sqrt(noise(vec3(15.0, 10.0, 10.0) * noise(vs_Pos.xyz)));

  vec3 sineVec = vec3(sin(u_PlanePos.x), sin(u_PlanePos.y), cos(u_PlanePos.x + u_PlanePos.y));
  vec4 modelposition = vec4(vs_Pos.x, 
                            (fs_Sine + sqrt(fbm(vs_Pos.xyz))) * min(abs(u_PlanePos.x), 5.0) * 0.5, 
                            vs_Pos.z,
                            1.0);

  if (modelposition.y < 1.5) {
    modelposition.y = 0.0;
    //fs_Col = vec4(0.0, 1.0, 0.0, 1.0);
  }

  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;
}
