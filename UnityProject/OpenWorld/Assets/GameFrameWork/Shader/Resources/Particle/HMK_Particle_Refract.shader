Shader "HMK/Particle/Refract"
{
	Properties
	{
		[Enum(UnityEngine.Rendering.CullMode)]  _Cull ("__Cull", float) = 2.0
		[SingleLine]_Noise ("Noise", 2D) = "white" { }
		[SingleLine]_NoiseRefracMask ("RefracMask", 2D) = "white" { }
		_Noisetiling ("Tiling", range(0, 100)) = 1
		_Distortion ("Distortion", range(0, 1)) = 0
		_SelectChannel ("Channle", Vector) = (1, 0, 0, 0)
		_RefractSelectChannel ("RefractMaskChannel", Vector) = (1, 0, 0, 0)
		_RefractMaskInt ("RefractMaskInt", range(0, 4)) = 0
		_SpeedX ("SpeedX", range(-10, 10)) = 0
		_SpeedY ("SpeedY", range(-10, 10)) = 0
	}
	SubShader
	{
		Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent+100" }
		// Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			Tags { "LightMode" = "Refract" }

			Cull [_Cull]

			ZWrite off
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag


			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"


			CBUFFER_START(UnityPerMaterial)
			half _Distortion, _RefractMaskInt;
			half _Noisetiling;
			half4 _SelectChannel, _RefractSelectChannel;
			half _SpeedX;
			half _SpeedY;


			CBUFFER_END

			TEXTURE2D(_Noise);SAMPLER(sampler_Noise);
			TEXTURE2D(_NoiseRefracMask);SAMPLER(sampler_NoiseRefracMask);
			SAMPLER(_CameraOpaqueTexture);
			SAMPLER(_CameraTransparentTexture);

			struct Attributes
			{
				float4 positionOS: POSITION;
				float2 uv: TEXCOORD0;
				half4 color: COLOR;
				float3 normalOS: NORMAL;
			};


			struct Varyings
			{
				float4 positionCS: SV_POSITION;
				float2 uv: TEXCOORD0;
				half4 color: COLOR;
				float3 normalWS: NORMAL;
			};



			Varyings vert(Attributes input)
			{
				Varyings output;
				output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
				output.normalWS = TransformObjectToWorldNormal(input.normalOS);
				output.color = input.color;
				output.uv = input.uv;

				return output;
			}


			float4 frag(Varyings input): SV_Target
			{
				half var_NoiseTex = dot(_SelectChannel, SAMPLE_TEXTURE2D(_Noise, sampler_Noise, input.uv * _Noisetiling + float2(_Time.y * _SpeedX, _Time.y * _SpeedY)));

				half refracMask = dot(_RefractSelectChannel, SAMPLE_TEXTURE2D(_NoiseRefracMask, sampler_NoiseRefracMask, input.uv));
				// return float4(var_NoiseTex.rrr, 1);
				float circle = saturate(1 - pow(distance(input.uv, 0.5) * 1.2, 0.5));

				// return circle;
				var_NoiseTex *= saturate(refracMask * _RefractMaskInt * input.color.a);
				float2 screenUV = GetNormalizedScreenSpaceUV(input.positionCS);
				screenUV = float2((screenUV.x + var_NoiseTex * _Distortion), screenUV.y);


				half4 colrefrac = tex2D(_CameraTransparentTexture, screenUV);


				return float4(colrefrac.rgb, 1);
			}

			ENDHLSL

		}
	}
	FallBack "Diffuse"
}