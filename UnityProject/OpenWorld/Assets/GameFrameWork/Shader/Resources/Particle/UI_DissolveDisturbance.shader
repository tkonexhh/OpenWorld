// Shader created with Shader Forge v1.38
// Shader Forge (c) Freya Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.38;sub:START;pass:START;ps:flbk:,iptp:0,cusa:False,bamd:0,cgin:,lico:0,lgpr:1,limd:1,spmd:1,trmd:0,grmd:0,uamb:True,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,imps:True,rpth:0,vtps:0,hqsc:True,nrmq:1,nrsp:0,vomd:0,spxs:False,tesm:0,olmd:1,culm:2,bsrc:3,bdst:7,dpts:2,wrdp:False,dith:0,atcv:False,rfrpo:True,rfrpn:Refraction,coma:15,ufog:True,aust:True,igpj:True,qofs:0,qpre:3,rntp:2,fgom:False,fgoc:False,fgod:False,fgor:False,fgmd:0,fgcr:0.5,fgcg:0.5,fgcb:0.5,fgca:1,fgde:0.01,fgrn:0,fgrf:300,stcl:False,atwp:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:False,fnsp:False,fnfb:True,fsmp:False;n:type:ShaderForge.SFN_Final,id:6870,x:32719,y:32712,varname:node_6870,prsc:2|emission-3876-OUT,alpha-42-OUT;n:type:ShaderForge.SFN_Tex2d,id:5118,x:31717,y:32392,ptovrint:False,ptlb:Tertur,ptin:_Tertur,varname:node_5118,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,tex:73e456edcc804ce4b8452cebf08e4086,ntxv:0,isnm:False|UVIN-3847-OUT;n:type:ShaderForge.SFN_Multiply,id:3876,x:32358,y:32621,varname:node_3876,prsc:2|A-5118-RGB,B-6064-RGB,C-7815-RGB;n:type:ShaderForge.SFN_VertexColor,id:6064,x:31681,y:32588,varname:node_6064,prsc:2;n:type:ShaderForge.SFN_Color,id:7815,x:31618,y:32830,ptovrint:False,ptlb:color,ptin:_color,varname:node_7815,prsc:2,glob:False,taghide:False,taghdr:True,tagprd:False,tagnsco:False,tagnrm:False,c1:0.5,c2:0.5,c3:0.5,c4:1;n:type:ShaderForge.SFN_Multiply,id:42,x:32249,y:33044,varname:node_42,prsc:2|A-6064-A,B-5118-A,C-7900-OUT,D-4852-OUT;n:type:ShaderForge.SFN_Step,id:7900,x:31953,y:33368,varname:node_7900,prsc:2|A-9254-U,B-5734-R;n:type:ShaderForge.SFN_TexCoord,id:9254,x:30812,y:32645,varname:node_9254,prsc:2,uv:1,uaff:True;n:type:ShaderForge.SFN_Tex2d,id:5734,x:31453,y:33377,ptovrint:False,ptlb:Dissolution,ptin:_Dissolution,varname:node_5734,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False|UVIN-7568-OUT;n:type:ShaderForge.SFN_TexCoord,id:1109,x:30531,y:33644,varname:node_1109,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_Time,id:6887,x:30070,y:33644,varname:node_6887,prsc:2;n:type:ShaderForge.SFN_Multiply,id:3051,x:30380,y:33576,varname:node_3051,prsc:2|A-1499-OUT,B-6887-T;n:type:ShaderForge.SFN_Multiply,id:729,x:30380,y:33821,varname:node_729,prsc:2|A-6887-T,B-2125-OUT;n:type:ShaderForge.SFN_Add,id:2872,x:30740,y:33585,varname:node_2872,prsc:2|A-3051-OUT,B-1109-U;n:type:ShaderForge.SFN_Add,id:6743,x:30765,y:33833,varname:node_6743,prsc:2|A-1109-V,B-729-OUT;n:type:ShaderForge.SFN_Append,id:2417,x:30963,y:33682,varname:node_2417,prsc:2|A-2872-OUT,B-6743-OUT;n:type:ShaderForge.SFN_SwitchProperty,id:7568,x:31188,y:33460,ptovrint:False,ptlb:Dissolving switch,ptin:_Dissolvingswitch,varname:node_7568,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,on:False|A-9327-OUT,B-2417-OUT;n:type:ShaderForge.SFN_Vector1,id:9327,x:30970,y:33381,varname:node_9327,prsc:2,v1:1;n:type:ShaderForge.SFN_Tex2d,id:9659,x:30183,y:32271,ptovrint:False,ptlb:Disturbance,ptin:_Disturbance,varname:node_9659,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False|UVIN-5823-OUT;n:type:ShaderForge.SFN_Time,id:2703,x:29121,y:32350,varname:node_2703,prsc:2;n:type:ShaderForge.SFN_Multiply,id:4623,x:29411,y:32240,varname:node_4623,prsc:2|A-2534-OUT,B-2703-T;n:type:ShaderForge.SFN_ValueProperty,id:2534,x:29138,y:32227,ptovrint:False,ptlb:NoiseU,ptin:_NoiseU,varname:_U_copy,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,v1:0;n:type:ShaderForge.SFN_Multiply,id:2254,x:29411,y:32482,varname:node_2254,prsc:2|A-2703-T,B-9376-OUT;n:type:ShaderForge.SFN_ValueProperty,id:9376,x:29107,y:32556,ptovrint:False,ptlb:NoiseV,ptin:_NoiseV,varname:_V_copy_copy,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,v1:0;n:type:ShaderForge.SFN_Append,id:8153,x:29768,y:32403,varname:node_8153,prsc:2|A-4623-OUT,B-2254-OUT;n:type:ShaderForge.SFN_Add,id:5823,x:29972,y:32267,varname:node_5823,prsc:2|A-3725-UVOUT,B-8153-OUT;n:type:ShaderForge.SFN_TexCoord,id:3725,x:29668,y:32093,varname:node_3725,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_Multiply,id:1519,x:30396,y:32271,varname:node_1519,prsc:2|A-7013-OUT,B-9659-R;n:type:ShaderForge.SFN_ValueProperty,id:7013,x:30183,y:32127,ptovrint:False,ptlb:Noiseqiangdu,ptin:_Noiseqiangdu,varname:node_7013,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,v1:0;n:type:ShaderForge.SFN_Add,id:4704,x:30825,y:32373,varname:node_4704,prsc:2|A-1519-OUT,B-458-U;n:type:ShaderForge.SFN_TexCoord,id:458,x:30520,y:32510,varname:node_458,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_Append,id:6275,x:31112,y:32421,varname:node_6275,prsc:2|A-4704-OUT,B-458-V;n:type:ShaderForge.SFN_Add,id:3847,x:31395,y:32459,varname:node_3847,prsc:2|A-6275-OUT,B-1470-OUT;n:type:ShaderForge.SFN_Append,id:1470,x:31091,y:32785,varname:node_1470,prsc:2|A-9254-V,B-9254-Z;n:type:ShaderForge.SFN_Tex2d,id:4873,x:31606,y:33200,ptovrint:False,ptlb:mask,ptin:_mask,varname:node_4873,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False;n:type:ShaderForge.SFN_Multiply,id:3369,x:31783,y:33128,varname:node_3369,prsc:2|A-5118-A,B-4873-R;n:type:ShaderForge.SFN_SwitchProperty,id:4852,x:31989,y:33079,ptovrint:False,ptlb:maskon,ptin:_maskon,varname:node_4852,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,on:False|A-1794-OUT,B-3369-OUT;n:type:ShaderForge.SFN_Vector1,id:1794,x:31783,y:33016,varname:node_1794,prsc:2,v1:1;n:type:ShaderForge.SFN_ValueProperty,id:1499,x:30113,y:33456,ptovrint:False,ptlb:D_U,ptin:_D_U,varname:node_1499,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,v1:0;n:type:ShaderForge.SFN_ValueProperty,id:2125,x:30070,y:33878,ptovrint:False,ptlb:V_v,ptin:_V_v,varname:node_2125,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,v1:0;proporder:5118-7815-5734-7568-9659-2534-9376-7013-4873-4852-1499-2125;pass:END;sub:END;*/

Shader "VFX/UIDissolveDisturbance"
{


    Properties
    {
        _Tertur ("Tertur", 2D) = "white" { }
        [HDR]_color ("color", Color) = (0.5, 0.5, 0.5, 1)
        _Dissolution ("Dissolution", 2D) = "white" { }
        [MaterialToggle] _Dissolvingswitch ("Dissolving switch", Float) = 1
        _Disturbance ("Disturbance", 2D) = "white" { }
        _NoiseU ("NoiseU", Float) = 0
        _NoiseV ("NoiseV", Float) = 0
        _Noiseqiangdu ("Noiseqiangdu", Float) = 0
        _mask ("mask", 2D) = "white" { }
        [MaterialToggle] _maskon ("maskon", Float) = 1
        _D_U ("D_U", Float) = 0
        _V_v ("V_v", Float) = 0
        _alpha ("alpha", Float) = 1
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0, 1)) = 0.5
        // [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
        // _ZWrite ("ZWrite", float) = 1

        //-------------------add----------------------
        _MinX("Min X", Float) = -10000
        _MaxX("Max X", Float) = 10000
        _MinY("Min Y", Float) = -10000
        _MaxY("Max Y", Float) = 10000
        //-------------------add----------------------
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite off


            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // #pragma multi_compile_fwdbase
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog

            #pragma target 3.0

            CBUFFER_START(UnityPerMaterial)
            float _NoiseU;
            float _NoiseV;
            float _Noiseqiangdu;
            half _maskon;
            float _D_U;
            float _V_v;
            float _alpha;
            float4 _color;
            half _Dissolvingswitch;


            float4 _Tertur_ST;
            float4 _Dissolution_ST;
            float4 _Disturbance_ST;
            float4 _mask_ST;

            //-------------------add----------------------
            float _MinX;
            float _MaxX;
            float _MinY;
            float _MaxY;
            //-------------------add----------------------
            CBUFFER_END

            TEXTURE2D(_Tertur);SAMPLER(sampler_Tertur);
            TEXTURE2D(_Dissolution); SAMPLER(sampler_Dissolution);
            TEXTURE2D(_Disturbance); SAMPLER(sampler_Disturbance);
            TEXTURE2D(_mask); SAMPLER(sampler_mask);

            struct VertexInput
            {
                float4 vertex: POSITION;
                float2 texcoord0: TEXCOORD0;
                float4 texcoord1: TEXCOORD1;
                float4 vertexColor: COLOR;
            };

            struct VertexOutput
            {
                float4 pos: SV_POSITION;
                float2 uv0: TEXCOORD0;
                float4 uv1: TEXCOORD1;
                float4 vertexColor: COLOR;

                //-------------------add----------------------
                float3 positionWS : TEXCOORD2;
                //-------------------add----------------------
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                o.vertexColor = v.vertexColor;
                o.pos = TransformObjectToHClip(v.vertex.xyz);

                //-------------------add----------------------
                float3 ws = TransformObjectToWorld(v.vertex.xyz);
                o.positionWS = ws;
                //-------------------add----------------------

                return o;
            }

            float4 frag(VertexOutput i): SV_Target
            {
                // float isFrontFace = (facing >= 0 ? 1: 0);
                // float faceSign = (facing >= 0 ? 1: - 1);
                ////// Lighting:
                ////// Emissive:
                float4 node_2703 = _Time;
                float2 node_5823 = (i.uv0 + float2((_NoiseU * node_2703.g), (node_2703.g * _NoiseV)));
                float4 _Disturbance_var = SAMPLE_TEXTURE2D(_Disturbance, sampler_Disturbance, TRANSFORM_TEX(node_5823, _Disturbance));

                float2 node_3847 = (float2(((_Noiseqiangdu * i.uv0.y * _Disturbance_var.r) + i.uv0.r), i.uv0.g) + float2(i.uv1.g, i.uv1.b));
                float4 _Tertur_var = SAMPLE_TEXTURE2D(_Tertur, sampler_Tertur, TRANSFORM_TEX(node_3847, _Tertur));
                float4 _Tertur_var2 = SAMPLE_TEXTURE2D(_Tertur, sampler_Tertur, TRANSFORM_TEX(i.uv0, _Tertur));
                float3 emissive = (_Tertur_var.rgb * i.vertexColor.rgb * _color.rgb);
                float3 finalColor = emissive;
                float4 node_6887 = _Time;
                float2 _Dissolvingswitch_var = lerp(1.0, float2(((_D_U * node_6887.g) + i.uv0.r), (i.uv0.g + (node_6887.g * _V_v))), _Dissolvingswitch);
                float4 _Dissolution_var = SAMPLE_TEXTURE2D(_Dissolution, sampler_Dissolution, TRANSFORM_TEX(_Dissolvingswitch_var, _Dissolution));
                float4 _mask_var = SAMPLE_TEXTURE2D(_mask, sampler_mask, TRANSFORM_TEX(i.uv0, _mask));
                half4 finalRGBA = half4(finalColor, (i.vertexColor.a * _Tertur_var.a * step(i.uv1.r, _Dissolution_var.r) * lerp(1.0, (_Tertur_var.a * _mask_var.r), _maskon)));

                finalRGBA.a = _alpha * _Tertur_var2.a * finalRGBA.a;

                //-------------------add----------------------
                finalRGBA.a *= (i.positionWS.x >= _MinX);
                finalRGBA.a *= (i.positionWS.x <= _MaxX);
                finalRGBA.a *= (i.positionWS.y >= _MinY);
                finalRGBA.a *= (i.positionWS.y <= _MaxY);
                //-------------------add----------------------


                return finalRGBA;
            }
            ENDHLSL

        }
        /*  Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            Offset 1, 1
            Cull Off

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_fog
            #pragma only_renderers d3d9 d3d11 glcore gles3 metal
            #pragma target 3.0
            struct VertexInput
            {
                float4 vertex: POSITION;
            };
            struct VertexOutput
            {
                V2F_SHADOW_CASTER;
            };
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_SHADOW_CASTER(o)
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR
            {
                float isFrontFace = (facing >= 0 ? 1 : 0);
                float faceSign = (facing >= 0 ? 1 : -1);
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG

            }*/
            // Pass
            // {
            //     Name "DepthOnly"
            //     Tags { "LightMode" = "DepthOnly" }

            //     ZWrite On
            //     ColorMask 0
            //     Cull off

            //     HLSLPROGRAM

            //     #pragma multi_compile_fwdbase
            //     #pragma multi_compile_fog
            //     #pragma only_renderers d3d9 d3d11 glcore gles3 metal
            //     #pragma target 3.0
            //     uniform sampler2D _Tertur; uniform float4 _Tertur_ST;
            //     uniform float4 _color;
            //     uniform sampler2D _Dissolution; uniform float4 _Dissolution_ST;
            //     uniform half _Dissolvingswitch;
            //     uniform sampler2D _Disturbance; uniform float4 _Disturbance_ST;
            //     uniform float _NoiseU;
            //     uniform float _NoiseV;
            //     uniform float _Noiseqiangdu;
            //     uniform sampler2D _mask; uniform float4 _mask_ST;
            //     uniform half _maskon;
            //     uniform float _D_U;
            //     uniform float _V_v;
            //     uniform float _alpha;
            //     #pragma target 4.5
            //     #pragma shader_feature UseBlend
            //     #pragma vertex vert
            //     #pragma fragment DepthOnlyFragment
            //     #pragma enable_cbuffer
            //     #define UNITY_ENABLE_CBUFFER

            //     //--------------------------------------
            //     // GPU Instancing
            //     #pragma multi_compile_instancing

            //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //     // #ifndef UNIVERSAL_DEPTH_ONLY_PASS_INCLUDED
            //     //     #define UNIVERSAL_DEPTH_ONLY_PASS_INCLUDED

            //     struct VertexInput
            //     {
            //         float4 vertex: POSITION;
            //         float2 texcoord0: TEXCOORD0;
            //         float4 texcoord1: TEXCOORD1;
            //         float4 vertexColor: COLOR;
            //     };
            //     struct VertexOutput
            //     {
            //         float4 pos: SV_POSITION;
            //         float2 uv0: TEXCOORD0;
            //         float4 uv1: TEXCOORD1;
            //         float4 vertexColor: COLOR;
            //     };


            //     VertexOutput vert(VertexInput v)
            //     {
            //         VertexOutput o = (VertexOutput)0;
            //         o.uv0 = v.texcoord0;
            //         o.uv1 = v.texcoord1;
            //         o.vertexColor = v.vertexColor;
            //         o.pos = TransformObjectToHClip(v.vertex.xyz);
            //         return o;
            //     }
            //     half4 DepthOnlyFragment(VertexOutput i): SV_TARGET
            //     {


            //         float4 node_2703 = _Time;
            //         float2 node_5823 = (i.uv0 + float2((_NoiseU * node_2703.g), (node_2703.g * _NoiseV)));
            //         float4 _Disturbance_var = tex2D(_Disturbance, TRANSFORM_TEX(node_5823, _Disturbance));
            //         float2 node_3847 = (float2(((_Noiseqiangdu * i.uv0.y * _Disturbance_var.r) + i.uv0.r), i.uv0.g) + float2(i.uv1.g, i.uv1.b));
            //         float4 _Tertur_var = tex2D(_Tertur, TRANSFORM_TEX(node_3847, _Tertur));
            //         float4 _Tertur_var2 = tex2D(_Tertur, TRANSFORM_TEX(i.uv0, _Tertur));
            //         float3 emissive = (_Tertur_var.rgb * i.vertexColor.rgb * _color.rgb);
            //         float3 finalColor = emissive;
            //         float4 node_6887 = _Time;
            //         float2 _Dissolvingswitch_var = lerp(1.0, float2(((_D_U * node_6887.g) + i.uv0.r), (i.uv0.g + (node_6887.g * _V_v))), _Dissolvingswitch);
            //         float4 _Dissolution_var = tex2D(_Dissolution, TRANSFORM_TEX(_Dissolvingswitch_var, _Dissolution));
            //         float4 _mask_var = tex2D(_mask, TRANSFORM_TEX(i.uv0, _mask));
            //         half4 finalRGBA = half4(finalColor, (i.vertexColor.a * _Tertur_var.a * step(i.uv1.r, _Dissolution_var.r) * lerp(1.0, (_Tertur_var.a * _mask_var.r), _maskon)));

            //         finalRGBA.a = _alpha * _Tertur_var2.a * finalRGBA.a;
            //         clip(finalRGBA.a - 0.2);
            //         UNITY_SETUP_INSTANCE_ID(input);
            //         UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            //         return 0;
            //     }

            //     ENDHLSL

            // }

        }
    }
