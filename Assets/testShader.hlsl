#include "shaderFunctions.hlsli"

//--name = sk/holoshader
//--color:color           = 1,1,1,1
//--emission_factor:color = 0,0,0,0
//--metallic              = 0
//--roughness             = 1
//--tex_scale             = 1
//--Extrusion             = 0.01
float4 color;
float4 emission_factor;
float  metallic;
float  roughness;
float  tex_scale;
float  Extrusion;

//--diffuse   = white
//--emission  = white
//--metal     = white
//--normal    = flat
//--occlusion = white
Texture2D    diffuse     : register(t0);
SamplerState diffuse_s   : register(s0);
Texture2D    emission    : register(t1);
SamplerState emission_s  : register(s1);
Texture2D    metal       : register(t2);
SamplerState metal_s     : register(s2);
Texture2D    normal      : register(t3);
SamplerState normal_s    : register(s3);
Texture2D    occlusion   : register(t4);
SamplerState occlusion_s : register(s4);


struct vsIn {
	float4 pos     : SV_Position;
	float3 norm    : NORMAL0;
	float2 uv      : TEXCOORD0;
	float4 color   : COLOR0;
};
struct psIn {
	float4 pos     : SV_POSITION;
	float3 normal  : NORMAL0;
	float2 uv      : TEXCOORD0;
	float4 color   : COLOR0;
	float3 irradiance: COLOR1;
	float3 diffuseColor : COLOR2;
	float3 world   : TEXCOORD1;
	float3 view_dir: TEXCOORD2;
	float4 camera  : TEXCOORD3;
	uint   view_id : SV_RenderTargetArrayIndex;
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
	
	// Calculate the camera's viewing direction vector
	o.view_dir = sk_camera_pos[o.view_id].xyz - o.world;
	
	// Extrude the vertices 
	//o.world.xyz += o.normal * Extrusion * abs(_SinTime().w);
	//o.world += sin(o.normal + (_Time().y * 0.01) * 0.01) * (0.1 * o.normal);

	// (Clip space), Calculate the model space coordinates of the mesh, and projection space for the fragment shader 
	o.pos = mul(float4(o.world, 1), sk_viewproj[o.view_id]);
	
	o.uv = input.uv * tex_scale;
	o.color = input.color * sk_inst[id].color * color;
	o.irradiance = Lighting(o.normal);
	
	o.diffuseColor = lambert(input.norm, float3(1, 1, 0), 0.5, float3(0.25, 0.43, 0.66), 1);
	
	return o;
}

float MipLevel(float ndotv) {
	float2 dx = ddx(ndotv * sk_cubemap_i.x);
	float2 dy = ddy(ndotv * sk_cubemap_i.y);
	float  delta = max(dot(dx, dx), dot(dy, dy));
	return 0.5 * log2(delta);
}

float3 FresnelSchlickRoughness(float cosTheta, float3 F0, float roughness) {
	return F0 + (max(1 - roughness, F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

// See: https://www.unrealengine.com/en-US/blog/physically-based-shading-on-mobile
float2 brdf_appx(half Roughness, half NoV) {
	const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
	half4 r = Roughness * c0 + c1;
	half a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
	half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
	return AB;
}



float4 ps(psIn input) : SV_TARGET{
	float4 albedo = diffuse.Sample(diffuse_s,  input.uv) * input.color;
	float3 emissive = emission.Sample(emission_s, input.uv).rgb * emission_factor.rgb;
	float2 metal_rough = metal.Sample(metal_s,    input.uv).gb; // rough is g, b is metallic
	float  ao = occlusion.Sample(occlusion_s,input.uv).r;  // occlusion is sometimes part of the metal tex, uses r channel

	float3 view = normalize(input.view_dir);
	float3 reflection = reflect(-view, input.normal);
	float  ndotv = max(0,dot(input.normal, view));

	float metallic_final = metal_rough.y * metallic;
	float rough_final = metal_rough.x * roughness;

	float3 F0 = 0.04;
	F0 = lerp(F0, albedo.rgb, metallic_final);
	float3 F = FresnelSchlickRoughness(ndotv, F0, rough_final);
	float3 kS = F;

	float mip = (1 - pow(1 - rough_final, 2)) * sk_cubemap_i.z;
	mip = max(mip, MipLevel(ndotv));
	float3 prefilteredColor = sk_cubemap.SampleLevel(sk_cubemap_s, reflection, mip).rgb;
	float2 envBRDF = brdf_appx(rough_final, ndotv);
	float3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y);

	float3 kD = 1 - kS;
	kD *= 1.0 - metallic_final;

	float3 diffuse = albedo.rgb * input.irradiance * ao;
	float3 color = (kD * diffuse + specular * ao);

	//float result = fog(input.world, input.camera, float2(5, 55));

	float4 result = rimShade(float3(0, 0.3, 0.3), 10, input.view_dir, input.normal);

	//float4 result = dotProduct(input.view_dir, input.normal);
	
	//float4 result = gradientPosterized(input.uv, float3(0.15, 0.43, 0.66), float3(0.83, 0.25, 0.66), 0.75, 0.25, 5);

	//float3 holoColor = { 0.25, 0.43, 0.66 };
	
	//float4 result = holographic(holoColor, 0.5, input.view_dir, input.normal);
	
	return result;
}