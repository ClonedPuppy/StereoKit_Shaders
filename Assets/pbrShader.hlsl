#include <stereokit.hlsli>
#include <stereokit_pbr.hlsli>

//--name = pbrShader
//--color:color           = 0,0,0,1
//--emission_factor:color = 0,0,0,0
//--metallic              = 0
//--roughness             = 0
//--tex_scale             = 1
float4 color;
float4 emission_factor;
float metallic;
float roughness;
float tex_scale;

//--diffuse   = white
//--emission  = white
//--metal     = white
//--normal    = flat
//--occlusion = white
Texture2D diffuse : register(t0);
SamplerState diffuse_s : register(s0);
Texture2D emission : register(t1);
SamplerState emission_s : register(s1);
Texture2D metal : register(t2);
SamplerState metal_s : register(s2);
Texture2D normal : register(t3);
SamplerState normal_s : register(s3);
Texture2D occlusion : register(t4);
SamplerState occlusion_s : register(s4);

struct vsIn
{
	float4 pos : SV_Position;
	float3 norm : NORMAL0;
	float2 uv : TEXCOORD0;
	float4 color : COLOR0;
};
struct psIn
{
	float4 pos : SV_POSITION;
	float3 normal : NORMAL0;
	float2 uv : TEXCOORD0;
	float4 color : COLOR0;
	float3 irradiance : COLOR1;
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
	o.irradiance = Lighting(o.normal);
	o.view_dir = sk_camera_pos[o.view_id].xyz - o.world;
	return o;
}

// For creating normals without a precalculated tangent
float3x3 CotangentFrame(float3 N, float3 p, float2 uv)
{
	// get edge vectors of the pixel triangle
	float3 dp1 = ddx(p);
	float3 dp2 = ddy(p);
	float2 duv1 = ddx(uv);
	float2 duv2 = ddy(uv);

	// solve the linear system
	float3 dp2perp = cross(dp2, N);
	float3 dp1perp = cross(N, dp1);
	float3 T = dp2perp * duv1.x + dp1perp * duv2.x;
	float3 B = dp2perp * duv1.y + dp1perp * duv2.y;

	// construct a scale-invariant frame 
	float invmax = rsqrt(max(dot(T, T), dot(B, B)));
	return float3x3(T * invmax, B * invmax, N);
}

float4 ps(psIn input) : SV_TARGET
{
	float4 albedo = diffuse.Sample(diffuse_s, input.uv) * input.color;
	float3 emissive = emission.Sample(emission_s, input.uv).rgb * emission_factor.rgb;
	float2 metal_rough = metal.Sample(metal_s, input.uv).gb; // rough is g, b is metallic
	
	// Normal texture sampling, the 2 - 1 brings it into the proper range for lighting calculations
	float3 tex_norm = normal.Sample(normal_s, input.uv).xyz * 2 - 1;
	// Normalize model normals
	float3 p_norm = normalize(input.normal);
	// Transform surface normals from tangent space to world space, and normalize
	tex_norm = mul(tex_norm, CotangentFrame(p_norm, input.view_dir, input.uv));
	p_norm = normalize(tex_norm);
	
	float ao = occlusion.Sample(occlusion_s, input.uv).r; // occlusion is sometimes part of the metal tex, uses r channel

	float metallic_final = metal_rough.y * metallic;
	float rough_final = metal_rough.x * roughness;

	float4 color = skpbr_shade(albedo, input.irradiance, ao, metallic_final, rough_final, input.view_dir, tex_norm);
	color.rgb += emissive;
	return color;
}