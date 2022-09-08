Shader "HMK/Scene/VertexLit"
{
    Properties
    {
        _TextureAtlas ("Texture Atlas", 2D) = "white" { }
        [RangeInt]  _IntRow ("Row", Range(1, 5)) = 2
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {

            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            
            HLSLPROGRAM

            #pragma shader_feature _TextureView _VertexView _UVView

            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            int _IntRow;float4 _TextureAtlas_ST;
            CBUFFER_END
            TEXTURE2D(_TextureAtlas);SAMPLER(sampler_TextureAtlas);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
                half4 color: COLOR;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                half4 color: COLOR;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;
                output.color = input.color;

                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                float2 uv = input.uv;
                uv = frac(uv * _TextureAtlas_ST.xy);
                
                int totalCount = _IntRow * _IntRow;
                
                float colorStep = (1.0) / ceil(totalCount / 4);
                
                half4 vertexColor = input.color;
                #ifdef _VertexView
                    return vertexColor;
                #endif

                //TODO 这里有问题
                int indexR = vertexColor.r / colorStep;
                int indexG = vertexColor.g / colorStep;
                int indexB = vertexColor.b / colorStep;
                int indexA = vertexColor.a / colorStep;

                indexG = step(indexG, 0.5) * _IntRow + indexG ;
                indexB = step(indexB, 0.5) * _IntRow * 2 + indexB;
                indexA = step(indexA, 0.5) * _IntRow * 3 + indexA;

                int index = indexR + indexG + indexB + indexA;
                

                //1D 坐标在转化为2D坐标
                int indexX = index % _IntRow + 0.001;
                int indexY = index / _IntRow + 0.001;

                // indexX = 2;
                // indexY = 2;

                indexY = _IntRow - 1 - indexY;
                float uvStep = 1.0 / _IntRow;
                
                float2 cellSize = uv / _IntRow;
                uv.x = cellSize.x + indexX * uvStep;
                uv.y = cellSize.y + indexY * uvStep;
                
                #ifdef _UVView
                    return half4(uv, 0, 1);
                #endif

                
                return SAMPLE_TEXTURE2D(_TextureAtlas, sampler_TextureAtlas, uv);
                half indexColor = index * 1.0 / (_IntRow * _IntRow) ;
                return indexColor;
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
