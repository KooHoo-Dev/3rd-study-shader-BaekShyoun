Shader "MyShaders/RimGlow"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.015, 0.025, 0.06, 1)
        [HDR] _RimColor ("Rim Color", Color) = (0.1, 0.7, 1, 1)
        _RimPower ("Rim Power (Higher = Narrower)", Range(0.5, 8)) = 3
        _RimIntensity ("Rim Intensity", Range(0, 10)) = 2
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

        Pass
        {
            Name "RimGlow"
            Tags { "LightMode" = "SRPDefaultUnlit" }
            Cull Back
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _RimColor;
                float _RimPower;
                float _RimIntensity;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 normal = normalize(input.normalWS);
                float3 viewDirection = GetWorldSpaceNormalizeViewDir(input.positionWS);
                // Facing the camera: dot is near 1. At the silhouette: near 0.
                float rim = pow(1.0 - saturate(dot(normal, viewDirection)), _RimPower);
                float3 color = _BaseColor.rgb + _RimColor.rgb * rim * _RimIntensity;
                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }
}
