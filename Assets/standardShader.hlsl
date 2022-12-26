#include <stereokit.hlsli>
#include "shaderFunctions.hlsli"

//--name = sk/default

//--color:color = 1,1,1,1
//--tex_scale   = 1
//--diffuse     = white
//--normal    = flat

float4 color;
float tex_scale;
Texture2D diffuse : register(t0);
SamplerState diffuse_s : register(s0);
Texture2D normal : register(t1);
SamplerState normal_s : register(s1);

struct vsIn
{
	float4 pos : SV_Position;
	float3 norm : NORMAL0;
	float2 uv : TEXCOORD0;
	float4 color : COLOR0;
};
struct psIn
{
	float4 pos : SV_Position;
	float3 normal : NORMAL0;
	float2 uv : TEXCOORD0;
	float4 color : COLOR0;
	//float3 irradiance : COLOR1;
	float3 world : TEXCOORD1;
	float3 view_dir : TEXCOORD2;
	uint view_id : SV_RenderTargetArrayIndex;
};

psIn vs(vsIn input, uint id : SV_InstanceID)
{
	psIn o;
	o.view_id = id % sk_view_count;
	id = id / sk_view_count;

	o.world = mul(float4(input.pos.xyz, 1), sk_inst[id].world).xyz;
	o.pos = mul(float4(o.world, 1), sk_viewproj[o.view_id]);

	o.normal = normalize(mul(float4(input.norm, 0), sk_inst[id].world).xyz);
	o.uv = input.uv * tex_scale;
	o.color = input.color * sk_inst[id].color * color;
	//o.irradiance = Lighting(o.normal);
	o.view_dir = sk_camera_pos[o.view_id].xyz - o.world;
	return o;
}

float4 ps(psIn input) : SV_TARGET
{
	// Normal texture sampling, the 2 - 1 brings it into the proper range for lighting calculations
	float3 tex_norm = normal.Sample(normal_s, input.uv).xyz * 2 - 1;
	// Normalize model normals
	float3 p_norm = normalize(input.normal);
	// Transform surface normals from tangent space to world space, and normalize
	tex_norm = mul(p_norm, CotangentFrame(p_norm, input.view_dir, tex_norm));
	p_norm = normalize(tex_norm);
	
	//input.irradiance *= Lighting(p_norm);
	
	float4 col = diffuse.Sample(diffuse_s, input.uv) * float4(Lighting(p_norm), 1);
	return float4(float3(col.rgb * input.color.rgb), 1);
}