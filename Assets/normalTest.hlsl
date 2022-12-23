#include "stereokit.hlsli"

//--name = sk/normalTest
//--color:color = 0.1,0.1,0.1,1
//--metallic    = 0
//--roughness   = 1
//--tex_scale   = 1
float4 color;
float metallic;
float roughness;
float tex_scale;

//--diffuse   = white
//--emission  = black
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
	float3 color : COLOR0;
	float3 world : TEXCOORD1;
	float3 view_dir : TEXCOORD2;
	uint view_id : SV_RenderTargetArrayIndex;
};

float3 sRGBToLinear(float3 sRGB);
float3 LinearTosRGB(float3 lin);

float3x3 CotangentFrame(float3 N, float3 p, float2 uv);

float DistributionGGX(float3 normal, float3 half_vec, float roughness);
float GeometrySchlickGGX(float NdotV, float roughness);
float GeometrySmith(float NdotL, float NdotV, float roughness);
float3 FresnelSchlick(float NdotV, float3 surfaceColor, float metalness);

psIn vs(vsIn input, uint id : SV_InstanceID)
{
	psIn output;
	output.view_id = id % sk_view_count;
	id = id / sk_view_count;
	output.world = mul(float4(input.pos.xyz, 1), sk_inst[id].world).xyz;
	output.pos = mul(float4(output.world, 1), sk_viewproj[output.view_id]);

	output.normal = normalize(mul(float4(input.norm, 0), sk_inst[id].world).xyz);
	output.uv = input.uv * tex_scale;
	output.color = input.color.rgb * sk_inst[id].color.rgb * color.rgb;
	output.view_dir = sk_camera_pos[output.view_id].xyz - output.world;
	return output;
}

float4 ps(psIn input) : SV_TARGET
{
	float3 albedo = diffuse.Sample(diffuse_s, input.uv).rgb * input.color.rgb;
	float3 emissive = emission.Sample(emission_s, input.uv).rgb;
	float3 metal_rough = metal.Sample(metal_s, input.uv).rgb; // b is metallic, rough is g
	
	// this is the normal texture sampling, the 2 - 1 brings it into the proper range for lighting calculations
	float3 tex_norm = normal.Sample(normal_s, input.uv).xyz * 2 - 1;

	float metal = metal_rough.b * metallic;
	float rough = max(1 - (metal_rough.g * roughness), 0.001);

	float3 p_norm = normalize(input.normal);
	//float3 view = normalize(input.view_dir);
	
	// transform surface normals from tangent space to world space
	tex_norm = mul(tex_norm, CotangentFrame(p_norm, input.view_dir, input.uv));
	
	p_norm = normalize(tex_norm);
	float3 light = float3(1, 1, 1);
	float3 half_vec = normalize(light + p_norm);
	float NdotL = (dot(p_norm, light));
	float NdotV = (dot(p_norm, input.view_dir));

	float w, h;
	uint mip_levels;
	//sk_cubemap.GetDimensions(0, w, h, mip_levels);

	float3 reflection = reflect(input.view_dir, p_norm);
	float3 irradiance = Lighting(p_norm);

	float D = DistributionGGX(p_norm, half_vec, rough);
	float3 F = FresnelSchlick(max(NdotV, 0), albedo, metal);
	float G = GeometrySmith(max(NdotL, 0), max(NdotV, 0), rough);
	float3 specular =
		(D * G * F)
			/
		(4 * NdotL * NdotV);

	// Find the diffuse contribution to the reflectance, this is based on the Fresnel
	float3 specular_contribution = F;
	float3 diffuse_contribution = 1 - specular_contribution;
	diffuse_contribution *= 1 - metal;

	// Combine it all together
	float3 diffuse = (albedo * irradiance);
	float3 ambient = diffuse_contribution * diffuse * F;
	float3 reflectance = ambient + (diffuse_contribution * albedo / 3.14159) * input.color.rgb * saturate(NdotL);
	return float4(reflectance + emissive, color.a);
}

float3 sRGBToLinear(float3 sRGB)
{
	return sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
}
float3 LinearTosRGB(float3 lin)
{
	float3 S1 = sqrt(lin);
	float3 S2 = sqrt(S1);
	float3 S3 = sqrt(S2);
	return 0.585122381 * S1 + 0.783140355 * S2 - 0.368262736 * S3;
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


// This is a normal distribution function called, Trowbridge-Reitz GGX
float DistributionGGX(float3 normal, float3 half_vec, float roughness)
{
	float roughness2 = roughness * roughness;
	float NdotH = max(dot(normal, half_vec), 0.0);
	float NdotH2 = NdotH * NdotH;

	float nom = roughness2;
	float denom = (NdotH2 * (roughness2 - 1.0) + 1.0);
	denom = 3.14159 * denom * denom;

	return nom / denom;
}

// These are Geometry functions
float GeometrySchlickGGX(float NdotV, float roughness)
{
	float nom = NdotV;
	float denom = NdotV * (1.0 - roughness) + roughness;

	return nom / denom;
}
float GeometrySmith(float NdotL, float NdotV, float roughness)
{
	float ggx1 = GeometrySchlickGGX(NdotV, roughness);
	float ggx2 = GeometrySchlickGGX(NdotL, roughness);

	return ggx1 * ggx2;
}

// and Fresnel
float3 FresnelSchlick(float NdotV, float3 surfaceColor, float metalness)
{
	float3 F0 = 0.04;
	F0 = lerp(F0, surfaceColor, metalness);
	return F0 + (1.0 - F0) * pow(1.0 - NdotV, 5.0);
}