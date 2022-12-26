#include "shaderFunctions.hlsli"

//--name = sk/debugShader
//--color:color           = 1,1,1,1
//--tex_scale             = 1
float4 color;
float  roughness;
float  tex_scale;

//--diffuse   = white
//--normal    = flat
Texture2D    diffuse     : register(t0);
SamplerState diffuse_s   : register(s0);
Texture2D    normal      : register(t3);
SamplerState normal_s    : register(s3);


struct vsIn {
	float4 pos			: SV_Position;
	float3 norm			: NORMAL0;
	float2 uv			: TEXCOORD0;
	float4 color		: COLOR0;
};
struct psIn {
	float4 pos			: SV_POSITION;
	float3 normal		: NORMAL0;
	float3 normalFixed	: NORMAL1;
	float2 uv			: TEXCOORD0;
	float4 color		: COLOR0;
	float3 world		: TEXCOORD1;
	float3 view_dir		: TEXCOORD2;
	float4 camera		: TEXCOORD3;
	uint   view_id		: SV_RenderTargetArrayIndex;
};



psIn vs(vsIn input, uint id : SV_InstanceID) {
	psIn o;
	o.view_id = id % sk_view_count;
	id = id / sk_view_count;

	// Calculate the camera position in world space
	o.camera = sk_camera_pos[o.view_id];
	
	// Calculate vertex position in world space
	o.world = mul(float4(input.pos.xyz, 1), sk_inst[id].world).xyz;
	
	// Calculate the normals to world space 
	o.normal = normalize(mul(float4(input.norm, 0), sk_inst[id].world).xyz);
	
	o.world = extrudeVertex(o.normal, o.world, o.camera.xyz, 0.2);
	
	// (Clip space), Calculate the model space coordinates of the mesh, and projection space for the fragment shader 
	o.pos = mul(float4(o.world, 1), sk_viewproj[o.view_id]);
	
	// "Sticky normals"
	o.normalFixed = input.norm;
	
	// Calculate the camera's viewing direction vector
	o.view_dir = sk_camera_pos[o.view_id].xyz - o.world;
	
	o.uv = input.uv * tex_scale;
	
	o.color = input.color * sk_inst[id].color * color;
	
	
	
	return o;
}

float4 ps(psIn input) : SV_TARGET{
	
	//float4 result = phong(input.normal, input.view_dir, float3(5, 5, 5), float3(0.5, 0.5, 0.5), 1, float3(0.0, 0.075, 0.15), float3(1, 0, 0));
	
	return float4(1, 1, 1, 1);
}