#include <stereokit.hlsli>


// Useful functions borrowed from Unity and others

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

float Posterize(float numberOfBands, float target)
{
	return round(target * numberOfBands) / numberOfBands;
}

// This function calculates the world space tangent vector for a given vertex in object space
float3 CalculateWorldTangent(float2 uv, float3 vertexPos, float3 vertexNormal)
{
	// Calculate the partial derivative of the texture coordinates with respect to the screen coordinates
	float2 duv = ddx(uv);
	float2 dvv = ddy(uv);

	// Calculate the tangent vector using the partial derivatives, vertex position, and normal vector
	float3 T = (duv.x * vertexPos - duv.y * normalize(vertexNormal)) / (duv.x * dvv.y - duv.y * dvv.x);

	return normalize(T);
}



// Vertex shaders

float3 extrudeVertex(float3 _normal, float3 _worldPos, float3 _campPos, float _width)
{
	// Remember to FaceCull = Cull.Front
	
	float dist = length(_worldPos - _campPos);
	_worldPos += normalize(_normal) * _width * 0.020 * dist;
	
	return _worldPos;
}



// Debug shaders

float4 debugUV(float2 _uv)
{
	return float4(_uv.r, _uv.g, 0, 1); // Quad has no z uv's
}

float4 debugNormal(float3 _normal)
{
	return float4(_normal * 0.5 + 0.5, 1);
}

float4 debugWorldSpace(float3 _worldSpace)
{
	return float4(_worldSpace, 1);
}


// Fragment shaders

float fog(float3 worldPos, float3 camPos, float2 radius)
{
	// Compute the distance from the viewer
	float dist = length(worldPos - camPos);
	// Compute the fog amount based on the distance from the camera
	float fogAmount = saturate((dist - radius.x) / radius.y);

	return 1 - fogAmount;
}

float4 rimShade(float3 color, float rimPower, float3 viewDir, float3 normal)
{
	// Compute the dot product between the view direction and the surface normal
	float rim = 1.0 - saturate(dot(viewDir, normal));

	// Compute the rim lighting effect using the "pow" function
	float3 rimEmission = color * pow(rim, rimPower);

	// Return the emission
	return float4(rimEmission, 1);
}

float4 dotProduct(float3 viewDir, float3 normal)
{
	float VdotN = saturate(dot(viewDir, normal));
	VdotN = 1.0 - VdotN;
	return float4(abs(VdotN), abs(VdotN), abs(VdotN), 1);
}

float4 holographic(float3 _color, float _RimPow, float3 viewDir, float3 normal)
{
	float rim = 1.0 - saturate(dot(viewDir, normal));
	rim = pow(rim, _RimPow * sin(_Time().w) * 0.5 + 0.5);

	return float4(_color * rim, rim);
}

float4 gradient(float2 _uv, float3 _topColor, float3 _bottomColor)
{
	float3 blend = lerp(_bottomColor, _topColor, _uv.y);
	return float4(blend, 1);
}

float4 gradientCustom(float2 _uv, float _minValue, float _maxValue, float4 _bottomColor, float4 _topColor)
{
	float t = smoothstep(_minValue, _maxValue, _uv.y);
	float3 blend = lerp(_bottomColor, _topColor, t);
	return float4(blend, 1);
}

float4 gradientPosterize(float2 _uv, float3 _topColor, float3 _bottomColor, float _minValue, float _maxValue, float _bands)
{
	float t = smoothstep(_minValue, _maxValue, _uv.y);
	t = Posterize(_bands + 1, t);
	float3 blend = lerp(_bottomColor, _topColor, t);
	return float4(blend, 1);
}

float4 lambert(float3 normal, float3 lightDir, half atten, float3 lightColor, float diffuseFactor)
{
	float diff = saturate(dot(normal, lightDir));
	return float4(lightColor * (diff * atten) * diffuseFactor, 1);
}

float4 phong(float3 _normal, float3 _viewDirection, float3 _lightPosition, float3 _lightColor, float _gloss, float3 _ambientLight, float3 _mainColor)
{
    // General
	float3 normal = normalize(_normal);
                
    // Direct light
	float3 lightSource = _lightPosition;
	float lightFalloff = max(0, dot(lightSource, normal)); // 0f to 1f                 
	float3 directDiffuseLight = _lightColor * lightFalloff;
               
	// Phong
	float3 viewReflect = reflect(-_viewDirection, normal);
	float specularFalloff = max(0, dot(viewReflect, lightSource));
	specularFalloff = pow(specularFalloff, _gloss); // Add gloss
	float3 directSpecularLight = specularFalloff * _lightColor;
                
    // Composite
	float3 diffuseLight = _ambientLight + directDiffuseLight;
	float3 result = diffuseLight * _mainColor + directSpecularLight;
                               
	return float4(result, 1);
}

