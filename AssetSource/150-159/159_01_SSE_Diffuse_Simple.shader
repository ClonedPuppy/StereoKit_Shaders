﻿Shader "Custom/150-159/159_01_SSE_Diffuse_Simple"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        
        CGPROGRAM
        #pragma surface surf Lambert
        
        struct Input
        {
            float4 color : COLOR;
        };
        
        void surf(Input IN, inout SurfaceOutput o) 
        {
            o.Albedo = 1;
        }
        ENDCG
    }
    Fallback "Diffuse"
}