#include "stereokit.hlsli"

// Useful functions borrowed from Unity
float4 _Time() {
	// Time since level load (t/20, t, t*2, t*3), use to animate things inside the shaders.
	float _time = sk_time;
	return float4(_time / 20, _time, _time * 2, _time * 3);
}

float4 _SinTime() {
	// Sine of time: (t/8, t/4, t/2, t).
	float _time = sk_time;
	return float4(sin(_time / 8), sin(_time / 4), sin(_time / 2), sin(_time));
}

float4 _CosTime() {
	// Cosine of time: (t/8, t/4, t/2, t).
	float _time = sk_time;
	return float4(cos(_time / 8), cos(_time / 4), cos(_time / 2), cos(_time));
}

// Debug shaders

// Vertex shaders

// Fragment shaders

float fog(float3 worldPos, float3 camPos, float2 radius) {

	// Compute the distance from the viewer
	float dist = length(worldPos - camPos);
	// Compute the fog amount based on the distance from the camera
	float fogAmount = saturate((dist - radius.x) / radius.y);

	return 1 - fogAmount;
}

float3 rimShade(float3 color, float rimPower, float3 viewDir, float3 normal)
{
	// Compute the dot product between the view direction and the surface normal
	float rim = 1.0 - saturate(dot(viewDir, normal));

	// Compute the rim lighting effect using the "pow" function
	float3 rimEmission = color * pow(rim, rimPower);

	// Return the emission
	return rimEmission;
}

float3 dotProduct(float3 viewDir, float3 normal)
{
	float VdotN = saturate(dot(viewDir, normal));
	VdotN = 1.0 - VdotN;
	return abs(VdotN);
}

float4 holographic(float3 _color, float _RimPow, float3 viewDir, float3 normal)
{
	float rim = 1.0 - saturate(dot(viewDir, normal));
	rim = pow(rim, _RimPow * sin(_Time().w) * 0.5 + 0.5);

	return float4(_color * rim, rim);
}

