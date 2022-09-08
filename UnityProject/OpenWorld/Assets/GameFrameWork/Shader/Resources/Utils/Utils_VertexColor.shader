
Shader "HMK/Utils/Vertexcolor"
{
	Properties { }
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
			
			

			
			struct Attributes
			{
				float4 positionOS: POSITION;
				half4 color: COLOR;
			};


			struct Varyings
			{
				float4 positionCS: SV_POSITION;
				half4 color: COLOR;
			};


			
			Varyings vert(Attributes input)
			{
				Varyings output;
				output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
				output.color = input.color;
				return output;
			}


			half4 frag(Varyings input): SV_Target
			{
				return input.color;
			}
			
			ENDHLSL

		}
	}
	FallBack "Diffuse"
}
