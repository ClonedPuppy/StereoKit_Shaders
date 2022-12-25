#include "shaderFunctions.hlsli"

//--name = anisotropy
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
	//float4 tangent		: TANGENT;
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
	float3 worldNormal  : TEXCOORD4;
	float3 worldTangent : TEXCOORD5;
	float3 worldBinormal: TEXCOORD6;
	uint   view_id		: SV_RenderTargetArrayIndex;
};


psIn vs(vsIn input, uint id : SV_InstanceID) 
	{
	psIn o;
	
	o.view_id = id % sk_view_count;
	id = id / sk_view_count;

	// Calculate the camera position in world space
	o.camera = sk_camera_pos[o.view_id];
	
	// Calculate vertex position in world space
	o.world = mul(float4(input.pos.xyz, 1), sk_inst[id].world).xyz;
	
	// Calculate the normals to world space 
	o.normal = normalize(mul(float4(input.norm, 0), sk_inst[id].world).xyz);
	
	// (Clip space), Calculate the model space coordinates of the mesh, and projection space for the fragment shader 
	o.pos = mul(float4(o.world, 1), sk_viewproj[o.view_id]);
	
	// Calculate the camera's viewing direction vector
	o.view_dir = sk_camera_pos[o.view_id].xyz - o.world;
	
	o.uv = input.uv * tex_scale;
	
	o.color = input.color * sk_inst[id].color * color;
	
	float3 tex_norm = normal.Sample(normal_s, input.uv).xyz * 2 - 1;
	float3 p_norm = normalize(input.norm);
	
	//float3 tang = CotangentFrame(p_norm, o.view_dir, input.uv, tex_norm, 0);

	// hmm, calculate this from frag shader instead!
	//o.worldTangent = normalize(mul(input.tangent, sk_inst[id].world)).xyz;
	
	//o.worldBinormal = cross(o.worldNormal, o.worldTangent) * -1;
	
	return o;
}




//float3 WorldNormalFromNormalMap(sampler2D normalMap, float2 uv, float3 worldTangent, float3 worldBinormal, float3 worldNormal)
//{
//	float3 normal = UnpackNormal(tex2D(normalMap, uv));
//	float3x3 TBN = float3x3(worldTangent, worldBinormal, worldNormal);
//	return normalize(mul(normal, TBN));
//}
            
//float3 DiffuseLambert(float3 normal, float3 lightDir, half atten, fixed3 lightColor, float diffuseFactor)
//{
//	float diff = saturate(dot(normal, lightDir));
//	return lightColor * (diff * atten) * diffuseFactor;
//}
            
//float3 IBLRefl(samplerCUBE cubeMap, float3 worldReflection, half detail, float exposure, float reflectionFactor)
//{
//	float4 cubeMapColor = texCUBE(cubeMap, float4(worldReflection, detail)).rgba;
//	return cubeMapColor.rgb * (cubeMapColor.a * exposure) * reflectionFactor;
//}
            
//float AshikhminShirleyPremoze_BRDF(float nU, float nV, float3 tangent, float3 normal, float3 lightDir, float3 viewDir, float reflectionFactor)
//{
//	const float pi = UNITY_PI;
//	float3 halfwayVector = normalize(lightDir + viewDir);
//	float3 NdotH = dot(normal, halfwayVector);
//	float3 NdotL = dot(normal, lightDir);
//	float3 NdotV = dot(normal, viewDir);
//	float3 HdotT = dot(halfwayVector, tangent);
//	float3 HdotB = dot(halfwayVector, cross(tangent, normal));
//	float3 VdotH = dot(viewDir, halfwayVector);
                 
//	float power = nU * pow(HdotT, 2) + nV * pow(HdotB, 2);
//	power /= 1.0 - pow(NdotH, 2);
                
//	float spec = sqrt((nU + 1) * (nV + 1)) * pow(NdotH, power);
//	spec /= 8.0 * pi * VdotH * max(NdotL, NdotV);
                
//	float Fresnel = reflectionFactor + (1.0 - reflectionFactor) * pow((1.0 - VdotH), 5);
                
//	spec *= Fresnel;
                
//	return spec;
//}







float4 ps(psIn input) : SV_TARGET
	{
	//// Normal texture sampling, the 2 - 1 brings it into the proper range for lighting calculations
	//float3 tex_norm = normal.Sample(normal_s, input.uv).xyz * 2 - 1;
	//// Normalize model normals
	//float3 p_norm = normalize(input.normal);
	//// Transform surface normals from tangent space to world space, and normalize
	//p_norm = normalize(tex_norm);
	
	
	//float3 worldNormalAtPixel = normalize(mul(tex_norm, CotangentFrame(p_norm, input.view_dir, input.uv, tex_norm, 0)));
                
	//half attenuation = 1;
                
	
//	// Inputs
//	float3 worldNormal; // World space normal
//	float3 worldPos; // World space position
//	float3 viewDir; // View direction vector
//	float3 lightDir; // Light direction vector
//	float roughness; // Material roughness
//	float anisotropy; // Material anisotropy
//	float specular; // Material specular reflectance

//// Outputs
//	float3 color;

//// Calculate the halfway vector
//	float3 halfwayVec = normalize(lightDir + viewDir);

//// Calculate the anisotropic tangent and bitangent
//	float3 anisoTangent = anisotropy * cross(worldNormal, halfwayVec);
//	float3 anisoBitangent = cross(anisoTangent, worldNormal);

//// Calculate the anisotropic normal
//	float3 anisoNormal = normalize(worldNormal + anisoTangent + anisoBitangent);

//// Calculate the diffuse term
//	float NdotL = max(dot(worldNormal, lightDir), 0.0);
//	float3 diffuse = specular * NdotL;

//// Calculate the specular term
//	float3 specularTerm = specular * DistributionGGX(anisoNormal, halfwayVec, roughness) * GeometrySchlickGGX(dot(anisoNormal, viewDir), roughness);

//// Calculate the final color
//	color = diffuse + specularTerm;

	
	
	//float3 lightDir = _WorldSpaceLightPos0.xyz;
	//float3 lightColor = _LightColor0.rgb;
	//float3 diffuseColor = DiffuseLambert(worldNormalAtPixel, lightDir, attenuation, lightColor, _DiffuseFactor);
                
	//float3 worldSpaceViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                
	//float4 tangentMap = tex2D(_TangentMap, i.uv * _TangentMap_ST.xy + _TangentMap_ST.zw);
	//float3 specularColor = AshikhminShirleyPremoze_BRDF(_AnisoU, _AnisoV, tangentMap.xyz, worldNormalAtPixel, lightDir, worldSpaceViewDir, _ReflectionFactor);
                
	//float3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.rgb * _AmbientFactor;
                
	//float3 mainTexCol = tex2D(_MainTex, i.uv).rgb;
                
	//float3 worldReflection = reflect(-worldSpaceViewDir, worldNormalAtPixel);
	//float3 reflectionColor = IBLRefl(_Cube, worldReflection, _Detail, _ReflectionExposure, _ReflectionFactor);
                
	//float3 surfaceColor = mainTexCol * diffuseColor + specularColor + ambientColor;
	//surfaceColor *= reflectionColor;
                
	//return float4(surfaceColor, 1);
	return float4(float3(1, 1, 1), 1);

}