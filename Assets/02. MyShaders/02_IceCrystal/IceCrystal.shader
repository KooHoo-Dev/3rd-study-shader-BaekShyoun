Shader "MyShaders/IceCrystal"
{
    Properties
    {
        _IceColor ("Ice Color", Color) = (0.08, 0.32, 0.55, 1)
        [HDR] _CrackColor ("Crack Color", Color) = (0.4, 0.9, 1, 1)
        _CrackScale ("Crack Scale", Range(1, 20)) = 7
        _CrackWidth ("Crack Width", Range(0.005, 0.15)) = 0.035
        _CrackIntensity ("Crack Intensity", Range(0, 8)) = 2
        _GlossPower ("Gloss Power", Range(8, 128)) = 64
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }
        Pass
        {
            Name "IceCrystal"
            Tags { "LightMode" = "UniversalForward" }
            Cull Back
            ZWrite On
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _IceColor;
                float4 _CrackColor;
                float _CrackScale;
                float _CrackWidth;
                float _CrackIntensity;
                float _GlossPower;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionOS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };

            float3 CellPoint(float3 cell)
            {
                float3 seed = float3(dot(cell, float3(127.1, 311.7, 74.7)),
                                    dot(cell, float3(269.5, 183.3, 246.1)),
                                    dot(cell, float3(113.5, 271.9, 124.6)));
                return frac(sin(seed) * 43758.5453);
            }

            // Two similarly distant cell seeds indicate a cell boundary.
            // Use object-space 3D coordinates to avoid UV seams.
            float CrackPattern(float3 position)
            {
                float3 cell = floor(position);
                float3 local = frac(position);
                float nearest = 100.0;
                float second = 100.0;
                for (int z = -1; z <= 1; z++)
                for (int y = -1; y <= 1; y++)
                for (int x = -1; x <= 1; x++)
                {
                    float3 offset = float3(x, y, z);
                    float3 delta = offset + CellPoint(cell + offset) - local;
                    float distanceSquared = dot(delta, delta);
                    second = min(second, max(nearest, distanceSquared));
                    nearest = min(nearest, distanceSquared);
                }
                float gap = sqrt(second) - sqrt(nearest);
                float smoothing = max(fwidth(gap), 0.002);
                return 1.0 - smoothstep(_CrackWidth, _CrackWidth + smoothing, gap);
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionOS = input.positionOS.xyz;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 normal = normalize(input.normalWS);
                float3 view = GetWorldSpaceNormalizeViewDir(input.positionWS);
                Light light = GetMainLight();
                float diffuse = saturate(dot(normal, light.direction));
                float3 halfVector = SafeNormalize(light.direction + view);
                float gloss = pow(saturate(dot(normal, halfVector)), _GlossPower) * diffuse;
                float cracks = CrackPattern(input.positionOS * _CrackScale);
                float3 surface = _IceColor.rgb * (0.25 + diffuse * light.color);
                float3 color = surface + gloss * light.color * 0.7;
                color += cracks * _CrackColor.rgb * _CrackIntensity;
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
