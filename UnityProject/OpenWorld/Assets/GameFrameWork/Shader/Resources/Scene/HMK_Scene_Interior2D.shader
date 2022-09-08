Shader "HMK/Scene/InteriorCube2D"
{
	Properties
	{
		_MainTex ("MainTex", 2D) = "white" { }
		_RoomDepth ("RoomDepth", float) = 1
	}
	SubShader
	{
		Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

		Pass
		{
			Tags { "LightMode" = "UniversalForward" }
			ZWrite on
			Cull Back

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag


			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

			CBUFFER_START(UnityPerMaterial)
			half _RoomDepth;

			CBUFFER_END

			TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

			struct Attributes
			{
				float4 positionOS: POSITION;
				float2 uv: TEXCOORD0;
				float3 normalOS: NORMAL;
				float4 tangent: TANGENT;
			};


			struct Varyings
			{
				float4 positionCS: SV_POSITION;
				float2 uv: TEXCOORD0;
				float3 normalWS: NORMAL;

				float3 cameraVectorTS: TEXCOORD1;


				float4 screenPos: TEXCOORD2;
			};



			Varyings vert(Attributes input)
			{
				Varyings output;
				output.positionCS = TransformObjectToHClip(input.positionOS.xyz);


				output.normalWS = TransformObjectToWorldNormal(input.normalOS);


				float3 objectCameraVector = TransformWorldToObject(float4(_WorldSpaceCameraPos, 1));
				float3 viewDir = input.positionOS.xyz - objectCameraVector;
				float tangentSign = input.tangent.w * unity_WorldTransformParams.w;
				float3 bitangent = cross(input.normalOS.xyz, input.tangent.xyz) * tangentSign;

				output.cameraVectorTS = float3(
					dot(viewDir, input.tangent.xyz),
					dot(viewDir, bitangent),
					dot(viewDir, input.normalOS)
				);
				output.uv = input.uv;

				output.screenPos = ComputeScreenPos(output.positionCS);
				return output;
			}


			float4 frag(Varyings input): SV_Target
			{
				// float4 screenPos = input.screenPos ;

				// float2 screenUV = screenPos.xy / screenPos.w;
				// float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);

				float farFrac = _RoomDepth;
				float depthScale = 1.0 / (1.0 - farFrac) - 1.0;
				float3 pos = float3(input.uv * 2 - 1, -1);

				// transform input ray dir from tangent space to normalized box space
				input.cameraVectorTS.z *= -depthScale;
				float3 id = 1.0 / input.cameraVectorTS.xyz;
				float3 k = abs(id) - pos * id;
				float kMin = min(min(k.x, k.y), k.z);
				pos += kMin * input.cameraVectorTS.xyz;
				float interp = pos.z * 0.5 + 0.5;
				float2 interiorUV = pos.xy * lerp(1.0, farFrac, interp);
				interiorUV = interiorUV * 0.5 + 0.5;

				half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, interiorUV);

				return var_MainTex;
			}

			ENDHLSL

		}
		Pass
		{
			Name "DepthOnly"
			Tags { "LightMode" = "DepthOnly" "Queue" = "1990" }

			ZWrite On
			ColorMask 0
			Cull Off
			HLSLPROGRAM

			#pragma target 4.5
			#pragma shader_feature UseBlend
			#pragma vertex DepthOnlyVertex
			#pragma fragment DepthOnlyFragment

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


			struct Attributes
			{
				float4 position: POSITION;
				float2 uv: TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float2 uv: TEXCOORD0;
				float4 positionCS: SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};


			Varyings DepthOnlyVertex(Attributes input)
			{
				Varyings output = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);


				output.positionCS = TransformObjectToHClip(input.position.xyz) ;
				output.uv = input.uv;//TRANSFORM_TEX(input.texcoord, _BaseMap);

				return output;
			}

			half4 DepthOnlyFragment(Varyings input): SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
				return 0;
			}

			ENDHLSL

		}
	}
	FallBack "Diffuse"
}