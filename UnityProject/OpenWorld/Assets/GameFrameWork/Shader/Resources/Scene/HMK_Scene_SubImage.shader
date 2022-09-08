Shader "HMK/Scene/SubImage"
{
	Properties
	{
		_SubeImageTex ("SubeImage", 2D) = "white" { }
		_MainLightSaturation ("LightSaturation", range(0, 1)) = 0.1
		_DarkShadowMultColor ("DarkShadowMultColor", color) = (0.79, 0.79, 0.79, 1)
		_ShadowMultColor ("ShadowMultColor", color) = (0.79, 0.79, 0.79, 1)
		[IntRange]_Index ("Index", range(0, 3)) = 0
	}
	SubShader
	{
		Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

		Pass
		{
			Tags { "LightMode" = "UniversalForward" }

			Cull Back

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag


			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

			#include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
			#include "./../Character/HMK_StylizedPBR_Input.hlsl"

			// CBUFFER_START(UnityPerMaterial)

			// half _Index;
			// CBUFFER_END

			TEXTURE2D(_SubeImageTex);SAMPLER(sampler_SubeImageTex);

			struct Attributes
			{
				float4 positionOS: POSITION;
				float2 uv: TEXCOORD0;
				float3 normalOS: NORMAL;
			};


			struct Varyings
			{
				float4 positionCS: SV_POSITION;
				float2 uv: TEXCOORD0;
				float3 normalWS: NORMAL;
			};



			Varyings vert(Attributes input)
			{
				Varyings output;
				output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
				output.normalWS = TransformObjectToWorldNormal(input.normalOS);
				output.uv = input.uv;
				return output;
			}


			float4 frag(Varyings input): SV_Target
			{
				Light mainLight = GetMainLight();
				half3 lightInt = saturate(Saturation_float(mainLight.color.rgb, _MainLightSaturation));

				//subUv计算
				half _Rows = 2;
				half _Columns = 2;
				half width = 1 / floor(_Rows);
				half height = 1 / floor(_Columns);
				half2 subUv = input.uv;
				subUv.x *= 1 / _Rows;
				subUv.y *= 1 / _Columns;
				int xIndex = fmod(_Index, _Rows);
				int yIndex = _Index / _Rows;
				subUv.x += xIndex * width;
				subUv.y += yIndex * height;

				//npr光照计算

				half4 var_MainTex = SAMPLE_TEXTURE2D(_SubeImageTex, sampler_SubeImageTex, subUv);

				half3 albedo = var_MainTex.rgb;

				HMKLightDataNPR lightingDataNPR = InitLightDataNPR(_DarkShadowMultColor, _ShadowMultColor, input.normalWS, 0, _IsInShadow);

				half3 NPRFinalColor = ShaderNRP(albedo, lightingDataNPR) * lightInt;



				//alphaClip
				half Alpha = var_MainTex.a;
				half AlphaTherad = 0.2;


				clip(Alpha - AlphaTherad);

				return float4(NPRFinalColor, 1);
			}

			ENDHLSL

		}
	}
	FallBack "Diffuse"
}