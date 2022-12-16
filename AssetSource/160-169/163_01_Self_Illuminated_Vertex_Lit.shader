// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Custom/160-169/163_01_Self_Illuminated_Vertex_Lit" 
{
    Properties 
    {
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        _SpecColor ("Spec Color", Color) = (1, 1, 1, 1)
        [PowerSlider(5.0)] _Shininess ("Shininess", Range (0.1, 1)) = 0.7
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Illum ("Illumin (A)", 2D) = "white" {}
        _Emission ("Emission (Lightmapper)", Float) = 1.0
    }
    
    SubShader 
    {
        Tags { "RenderType" = "Opaque" }
        
        LOD 100
    
        Pass 
        {
            Name "BASE"
            Tags { "LightMode" = "Vertex" }
            
            Material 
            {
                Diffuse [_Color]
                Shininess [_Shininess]
                Specular [_SpecColor]
            }
            
            SeparateSpecular On
            Lighting On
            
            SetTexture [_Illum] 
            {
                constantColor [_Color]
                combine constant lerp(texture) previous
            }
            
            SetTexture [_MainTex] 
            {
                constantColor (1,1,1,1)
                Combine texture * previous, constant // UNITY_OPAQUE_ALPHA_FFP
            }
        }
    
        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        Pass
        {
            Name "META"
            Tags { "LightMode" = "Meta" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            
            #include "UnityCG.cginc"
            #include "UnityMetaPass.cginc"
            
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Illum;
            float4 _Illum_ST;
            fixed _Emission;
    
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uvMain : TEXCOORD0;
                float2 uvIllum : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };
    
            v2f vert(appdata_full v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);
                o.uvMain = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uvIllum = TRANSFORM_TEX(v.texcoord, _Illum);
                return o;
            }
    
            
    
            half4 frag(v2f i) : SV_Target
            {
                UnityMetaInput metaIN;
                UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);
    
                fixed4 tex = tex2D(_MainTex, i.uvMain);
                fixed4 c = tex * _Color;
                metaIN.Albedo = c.rgb;
                metaIN.Emission = c.rgb * tex2D(_Illum, i.uvIllum).a;
    
                return UnityMetaFragment(metaIN);
            }
            ENDCG
        }
    }
    Fallback "Legacy Shaders/VertexLit"
    CustomEditor "LegacyIlluminShaderGUI"
}