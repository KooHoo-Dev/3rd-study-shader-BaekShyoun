Shader "MyShaders/Hologram"
{
    Properties
    {
        [HDR] _HoloColor ("Hologram Color", Color) = (0.05, 0.8, 1, 1)
        _LineDensity ("Line Density", Range(1, 80)) = 25
        _LineSpeed ("Line Speed", Range(-3, 3)) = 0.5
        _LineWidth ("Line Width", Range(0.05, 0.9)) = 0.3
        _Opacity ("Opacity", Range(0, 1)) = 0.55
        _Brightness ("Brightness", Range(0, 5)) = 1.5
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }
        Pass
        {
            Name "Hologram"
            Tags { "LightMode" = "SRPDefaultUnlit" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _HoloColor;
                float _LineDensity;
                float _LineSpeed;
                float _LineWidth;
                float _Opacity;
                float _Brightness;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float height : TEXCOORD0;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(positionWS);
                // World height aligns stripes across all parts of the shader ball.
                output.height = positionWS.y;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // Repeating bands move upward for a positive speed.
                float phase = input.height * _LineDensity - _Time.y * _LineSpeed;
                float distanceToCenter = abs(frac(phase) - 0.5);
                float halfWidth = _LineWidth * 0.5;
                float smoothing = max(fwidth(phase), 0.001);
                float scanLine = 1.0 - smoothstep(halfWidth - smoothing, halfWidth + smoothing, distanceToCenter);
                float3 color = _HoloColor.rgb * _Brightness * lerp(0.25, 1.0, scanLine);
                float alpha = _Opacity * lerp(0.15, 1.0, scanLine);
                return half4(color, alpha);
            }
            ENDHLSL
        }
    }
}
