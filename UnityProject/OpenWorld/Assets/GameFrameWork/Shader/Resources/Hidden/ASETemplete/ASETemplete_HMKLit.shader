Shader /*ase_name*/ "ASETemplateShaders/HMKLit" /*end*/
{
    Properties
    {
        /*ase_props*/
    }
    
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        LOD 100
        Cull Off
        /*ase_pass*/

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend One Zero
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//必须加上 影响主光源的shadowCoord
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_ON
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing


            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Himiko/Shader/URP/HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            /*ase_pragma*/

            struct Attributes
            {
                float4 positionOS: POSITION;
                float4 texcoord: TEXCOORD0;
                float4 texcoord1: TEXCOORD1;
                half3 normalOS: NORMAL;
                /*ase_vdata:p=p;uv0=tc0.xy;uv1=tc1.xy*/
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD1;
                float4 texcoord: TEXCOORD0;
                half3 normalWS: NORMAL;
                
                /*ase_interp(1,7):sp=sp.xyzw;uv0=tc0.xy;uv1=tc0.zw*/
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            /*ase_globals*/
            
            Varyings vert(Attributes i /*ase_vert_input*/)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(i);
                output.texcoord.xy = i.texcoord.xy;
                output.texcoord.zw = i.texcoord1.xy;
                
                // ase common template code
                /*ase_vert_code:v=appdata;o=v2f*/
                
                output.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                output.normalWS = normalize(TransformObjectToWorldNormal(i.normalOS));
                return output;
            }
            
            half4 frag(Varyings i/*ase_frag_input*/): SV_Target
            {
                // ase common template code
                /*ase_frag_code:i=v2f*/
                
                half3 Albedo = /*ase_frag_out:Albedo;Float3*/half3(1, 0, 0)/*end*/;
                float Alpha = /*ase_frag_out:Alpha;Float*/1/*end*/;
                float Metallic = /*ase_frag_out:Metallic;Float*/1/*end*/;
                float Roughness = /*ase_frag_out:Roughness;Float*/1/*end*/;
                float Occlusion = /*ase_frag_out:Occlusion;Float*/1/*end*/;
                half3 Emission = /*ase_frag_out:Emission;Float3*/half3(0, 0, 0)/*end*/;
                float3 PositionWS = /*ase_frag_out:PositionWS;Float3*/float3(0, 0, 0)/*end*/;
                float3 NormalTS = /*ase_frag_out:NormalTS;Float3*/float3(0, 0, 0)/*end*/;

                float3 normalWS = 0;

                HMKSurfaceData surfaceData = InitSurfaceData(Albedo, Alpha, Metallic, Roughness, Occlusion, Emission);
                HMKLightingData lightingData = InitLightingData(PositionWS, normalWS);

                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
                return half4(finalRGB, surfaceData.alpha);
            }
            ENDHLSL

        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            Cull[_Cull] // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            /*ase_pragma*/

            struct Attributes
            {
                float4 positionOS: POSITION;
                float4 texcoord: TEXCOORD0;
                float4 texcoord1: TEXCOORD1;
                /*ase_vdata:p=p;uv0=tc0.xy;uv1=tc1.xy*/
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                /*ase_interp(1,7):sp=sp.xyzw;uv0=tc0.xy;uv1=tc0.zw*/
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            /*ase_globals*/
            
            Varyings ShadowPassVertex(Attributes i /*ase_vert_input*/)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(i);
                
                // ase common template code
                /*ase_vert_code:v=appdata;o=v2f*/
                
                output.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return output;
            }

            half4 ShadowPassFragment(Varyings i/*ase_frag_input*/): SV_Target
            {
                return 0;
            }

            ENDHLSL

        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            /*ase_pragma*/

            struct Attributes
            {
                float4 positionOS: POSITION;
                float4 texcoord: TEXCOORD0;
                float4 texcoord1: TEXCOORD1;
                /*ase_vdata:p=p;uv0=tc0.xy;uv1=tc1.xy*/
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                /*ase_interp(1,7):sp=sp.xyzw;uv0=tc0.xy;uv1=tc0.zw*/
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            /*ase_globals*/
            
            Varyings DepthOnlyVertex(Attributes i /*ase_vert_input*/)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(i);
                
                // ase common template code
                /*ase_vert_code:v=appdata;o=v2f*/
                
                output.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return output;
            }

            half4 DepthOnlyFragment(Varyings i/*ase_frag_input*/): SV_Target
            {
                return 0;
            }

            ENDHLSL

        }
    }
}