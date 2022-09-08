Shader "HMK/Scene/river"
{
	Properties
	{
		_Distortion ("Distortion", Range(0, 5)) = 2
		_FlowSpeed ("FlowSpeed", vector) = (0, 0, 0, 0)
		_FlowSpeedY ("FlowSpeedY", Range(-10, 10)) = 0

		[SingleLine]_FlowMask ("FlowMask", 2D) = "White" { }
		_FlowMaskTilingX ("FlowMaskTilingX", Range(0, 200)) = 1
		_FlowMaskTilingY ("FlowMaskTilingY", Range(0, 200)) = 1
		_NormalTilingX ("NormalTilingX", Range(0, 200)) = 0.5
		_NormalTilingY ("NormalTilingY", Range(0, 200)) = 0.5
		[SingleLine]_NormalMap ("NormalMap", 2D) = "bump" { }
		_FlowMaskOpacity ("FlowMaskOpacity", range(0, 1)) = 1
		// _WaveSpeed ("FoamSpeed", Range(-5, 5)) = 1

		_BlendDepth ("BlendDepth", Range(0.1, 100)) = 1
		[HDR]_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
		_BaseColorFar ("BaseColorFar", Color) = (1, 1, 1, 1)
		// [HDR]_CausticsColor ("CausticsColor", Color) = (1, 1, 1, 1)
		// _CausticsTiling ("CausticsTiling", Range(0, 100)) = 10
		// _CausticsSpeed ("CausticsSpeed", Float) = 1
		_Opacity ("Opacity", range(0, 1)) = 1

		_SpecularExponent ("SpecularExp", vector) = (0, 0, 0, 0)
		// _DepthOffset ("DepthOffset", vector) = (0, 0, 0, 1)
		// [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4

		[SingleLine]_CubeMap ("CubeMap", cube) = "White" { }


		_fresnelPow ("fresnelPow", float) = 1
		_fresnelBias ("fresnelBias", float) = 0
		_fresnelScale ("fresnelScale", float) = 1
	}

	SubShader
	{
		Tags { "RenderType" = "Geometry" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }
		LOD 300


		Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
		ZWrite Off
		ZTest LEqual
		Offset 0, 0
		ColorMask RGBA
		Cull back

		Pass
		{
			HLSLPROGRAM

			// -------------------------------------
			// Material Keywords
			// #pragma shader_feature UseHighlight
			// #pragma shader_feature UseRainnyNormal

			// Unity defined keywords
			// #pragma multi_compile_fog
			#pragma shader_feature _FOG_ON
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#include "./../HLSLIncludes/Common/Fog.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			struct appdata
			{
				float4 positionOS: POSITION;
				float4 normal: NORMAL;
				float2 uv: TEXCOORD;
				float4 tangent: TANGENT;
			};

			struct v2f
			{
				float4 positionCS: SV_POSITION;
				float4 screenPos: TEXCOORD1;
				float3 positionWS: TEXCOORD2;
				float2 uv: TEXCOORD3;
				float3 normalWS: TEXCOORD4;
				half fogFactor: TEXCOORD5;
				float3 tangent: TEXCOORD6;
				float3 bitangent: TEXCOORD7;
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _FlowSpeed;
			float _FlowSpeedX;
			float _FlowSpeedY;

			TEXTURE2D(_FoamMap);
			SAMPLER(sampler_FoamMap);
			TEXTURECUBE(_CubeMap);
			SAMPLER(sampler_CubeMap);

			float4 _FoamMap_ST;

			float _Distortion;
			float _WaveSpeed;

			float _BlendDepth;
			half4 _BaseColor;
			half4 _FoamColor;
			half _NormalTilingX, _NormalTilingY;

			half _FoamColorFrequence;
			half4 _CausticsColor;
			half _CausticsSpeed;
			half _CausticsTiling;
			half _FoamFrequence;
			half _FoamDepth;
			half _FoamIntensity;
			half _FoamBlendDepth;
			half _FoamMapTiling;
			half4 _DepthOffset;
			half4 _SphereMaskPosition;
			half _RefAlpha;
			half4 _SpecularExponent;
			half _FlowMaskOpacity;
			half4 _FlowMapTiling;
			half _fresnelBias, _fresnelPow, _fresnelScale;
			half4 _BaseColorFar;
			half _UseRainnyNormal;
			half _Opacity;

			half _FlowMaskTilingX, _FlowMaskTilingY;
			CBUFFER_END
			SAMPLER(_CameraOpaqueTexture);
			SAMPLER(_CameraColorTexture);

			TEXTURE2D(_NormalMap);
			SAMPLER(sampler_NormalMap);
			TEXTURE2D(_ReflectionTex);
			SAMPLER(sampler_ReflectionTex);
			TEXTURE2D(_FlowMask);
			SAMPLER(sampler_FlowMask);
			// TEXTURE2D(_RippleNormal);
			// SAMPLER(sampler_RippleNormal);


			v2f vert(appdata v)
			{
				v2f output;
				output.positionCS = TransformObjectToHClip(v.positionOS.xyz);
				output.positionWS = TransformObjectToWorld(v.positionOS);//   mul(unity_ObjectToWorld, v.vertex).xyz;
				output.screenPos = ComputeScreenPos(output.positionCS);
				output.uv = v.uv;
				output.normalWS = TransformObjectToWorldNormal(v.normal);
				half fogFactor = ComputeFogFactor(output.positionCS.z);

				output.fogFactor = fogFactor;
				float3 normalVS = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal) * output.positionCS.w;
				float3 positionVS = mul(UNITY_MATRIX_MV, v.positionOS.xyz).xyz;
				float dis = max(0.0, -positionVS.z);
				float distanceCorrection = 1.0 - smoothstep(1, 3, dis);

				float Noise = SAMPLE_TEXTURE2D_LOD(_FlowMask, sampler_FlowMask, output.uv * 1 + float2(0, frac(_Time.x * 10)), 1).b;
				float2 ProjNormal = (mul((float2x2)UNITY_MATRIX_P, normalVS));
				// output.positionCS.xy += ProjNormal * distanceCorrection * Noise ;
				output.tangent = TransformObjectToWorldDir(v.tangent.xyz);
				float vertexTangentSign = v.tangent.w * unity_WorldTransformParams.w;
				output.bitangent = cross(output.normalWS, output.tangent) * vertexTangentSign;

				return output;
			}
			// float3 NormalFromHeight_World(float In, float Strength, float3 Position, float3x3 TangentMatrix)
			// {
			// 	float3 worldDerivativeX = ddx(Position);
			// 	float3 worldDerivativeY = ddy(Position);

			// 	float3 crossX = cross(TangentMatrix[2].xyz, worldDerivativeX);
			// 	float3 crossY = cross(worldDerivativeY, TangentMatrix[2].xyz);
			// 	float d = dot(worldDerivativeX, crossY);
			// 	float sgn = d < 0.0 ?(-1.f): 1.f;
			// 	float surface = sgn / max(0.00000000000001192093f, abs(d));

			// 	float dHdx = ddx(In);
			// 	float dHdy = ddy(In);
			// 	float3 surfGrad = surface * (dHdx * crossY + dHdy * crossX);
			// 	float3 Out = normalize(TangentMatrix[2].xyz - (Strength * surfGrad));
			// 	return Out;
			// }
			half3 Desaturation(float3 In, float Saturation)
			{
				float luma = dot(In, float3(0.2126729, 0.7151522, 0.0721750));
				return luma.xxx + Saturation.xxx * (In - luma.xxx);
			}

			//噪声图生成
			// float2 rand(float2 st, int seed)
			// {
			// 	float2 s = float2(dot(st, float2(127.1, 311.7)) + seed, dot(st, float2(269.5, 183.3)) + seed);
			// 	return -1 + 2 * frac(sin(s) * 43758.5453123);
			// }

			// float noise(float2 st, int seed)
			// {


			// 	st.y += frac(_Time.y * _FlowSpeedX);
			// 	st.x += frac(_Time.y * _FlowSpeedY);


			// 	float2 p = floor(st);
			// 	float2 f = frac(st);

			// 	float w00 = dot(rand(p, seed), f);
			// 	float w10 = dot(rand(p + float2(1, 0), seed), f - float2(1, 0));
			// 	float w01 = dot(rand(p + float2(0, 1), seed), f - float2(0, 1));
			// 	float w11 = dot(rand(p + float2(1, 1), seed), f - float2(1, 1));

			// 	float2 u = f * f * (3 - 2 * f);

			// 	return lerp(lerp(w00, w10, u.x), lerp(w01, w11, u.x), u.y);
			// }
			//海浪的涌起法线计算
			// float3 swell(float3 pos, float anisotropy)
			// {
			//     float3 normal;

			//     float height = noise(pos.xz * _NormalTiling, 0.1);

			//     height = height + noise(pos.xz * _NormalTiling * 0.5, 0.1);
			//     height = height + noise(pos.xz * _NormalTiling * 0.25, 0.1);
			//     height *= anisotropy / 0.5;//使距离地平线近的区域的海浪高度降低
			//     normal = normalize
			//     (cross(
			//         float3(0, ddy(height), 1),
			//         float3(1, ddx(height), 0)
			//     )//两片元间高度差值得到梯度
			//     );
			//     return normal;
			// // }
			// half3 BlendNormals(half3 n1, half3 n2)
			// {
			// 	return normalize(half3(n1.xy * n2.z + n2.xy * n1.z, n1.z * n2.z));
			// }



			// float2 hash2(float2 p)//焦散

			// {
			// 	return frac(sin(float2(dot(p, float2(123.4, 748.6)), dot(p, float2(547.3, 659.3)))) * 5232.85324);
			// }
			// float hash(float2 p)//焦散

			// {
			// 	return frac(sin(dot(p, float2(43.232, 75.876))) * 4526.3257);
			// }

			// float voronoi_function(float2 p)//焦散

			// {
			// 	float2 n = floor(p);
			// 	float2 f = frac(p);
			// 	float md = 5.0;
			// 	float2 m = 0;
			// 	for (int i = -1; i <= 1; i++)
			// 	{
			// 		for (int j = -1; j <= 1; j++)
			// 		{
			// 			float2 g = float2(i, j);
			// 			float2 o = hash2(n + g);
			// 			o = 0.5 + 0.5 * sin(_Time.y * _CausticsSpeed + 5.038 * o);
			// 			float2 r = g + o - f;
			// 			float d = dot(r, r);
			// 			if (d < md)
			// 			{
			// 				md = d;
			// 				m = n + g + o;
			// 			}
			// 		}
			// 	}
			// 	return md;
			// }

			// float ov(float2 p)//焦散

			// {
			// 	float v = 0.0;
			// 	float a = 0.4;
			// 	for (int i = 0; i < 2; i++)
			// 	{
			// 		v += voronoi_function(p) * a;
			// 		p *= 1.8;
			// 		a *= 0.5;
			// 	}
			// 	return v;
			// }
			// float3 NormalReconstructZ(float2 In)
			// {
			// 	float reconstructZ = sqrt(1.0 - saturate(dot(In.xy, In.xy)));
			// 	float3 normalVector = float3(In.x, In.y, reconstructZ);
			// 	return normalize(normalVector);
			// }
			float RandomRange_float(float2 Seed, float Min, float Max)
			{
				float randomno = frac(sin(dot(Seed, float2(12.9898, 78.233))) * 43758.5453);
				float Out = lerp(Min, Max, randomno);

				return Out;
			}
			float4 Unity_SampleGradient_float(Gradient Gradient, float Time)
			{
				float3 color = Gradient.colors[0].rgb;
				[unroll]
				for (int c = 1; c < 8; c++)
				{
					float colorPos = saturate((Time - Gradient.colors[c - 1].w) / (Gradient.colors[c].w - Gradient.colors[c - 1].w)) * step(c, Gradient.colorsLength - 1);
					color = lerp(color, Gradient.colors[c].rgb, lerp(colorPos, step(0.01, colorPos), Gradient.type));
				}
				#ifndef UNITY_COLORSPACE_GAMMA
					color = SRGBToLinear(color);
				#endif
				float alpha = Gradient.alphas[0].x;
				[unroll]
				for (int a = 1; a < 8; a++)
				{
					float alphaPos = saturate((Time - Gradient.alphas[a - 1].y) / (Gradient.alphas[a].y - Gradient.alphas[a - 1].y)) * step(a, Gradient.alphasLength - 1);
					alpha = lerp(alpha, Gradient.alphas[a].x, lerp(alphaPos, step(0.01, alphaPos), Gradient.type));
				}
				float4 Out = float4(color, alpha);

				return Out;
			}
			real4 frag(v2f i): SV_Target
			{
				real4 col = 0;
				Light mainLight = GetMainLight();
				mainLight.color = clamp(Desaturate(mainLight.color, 0.7), 0.5, 1) ;
				mainLight.direction.xyz = normalize(_LightDir);
				half3 worldViewDir = _WorldSpaceCameraPos - i.positionWS;

				half normalizeFresnel = _fresnelScale + (1 - _fresnelScale) * pow(1 - dot(normalize(worldViewDir), normalize(i.normalWS)), _fresnelPow);
				normalizeFresnel = saturate(normalizeFresnel);

				half normalizeFresnelReflect = 0.02 + (1 - 0.02) * pow(1 - dot(normalize(worldViewDir), normalize(i.normalWS)), 10);
				normalizeFresnelReflect = saturate(normalizeFresnelReflect);
				float refractDis = -100;
				half normalizeFresnelRefrac = refractDis + (1 - refractDis) * pow(1 - dot(normalize(worldViewDir), normalize(i.normalWS)), 0.5);
				normalizeFresnelRefrac = saturate(normalizeFresnelRefrac);

				half fresnel = 0.2 + saturate((1 - 0.2)) * pow(1 - dot(worldViewDir, i.normalWS), 1);
				fresnel = saturate(fresnel);
				half reflectFact = reflect(worldViewDir, i.normalWS);
				// half refractRatio = refract(worldViewDir, i.normalWS, _refractRatio);




				// return float4(fresnel.xxx, 1);

				float3 worldTangent = i.tangent;
				float3 NormalWS = i.normalWS;
				float3 worldBitangent = i.bitangent;
				float3 tanToWorld0 = float3(worldTangent.x, worldBitangent.x, NormalWS.x);
				float3 tanToWorld1 = float3(worldTangent.y, worldBitangent.y, NormalWS.y);
				float3 tanToWorld2 = float3(worldTangent.z, worldBitangent.z, NormalWS.z);

				float distanceFadeFactor = saturate(i.positionCS.z * _ZBufferParams.z * 5) ;




				float2 uvPanner1 = (frac(_Time.x * _FlowSpeed.xy) + i.uv * float2(_NormalTilingX, _NormalTilingY));
				// half2 uvPanner2 = (frac(_Time.x * _FlowSpeed.zw) + i.uv * float2(_NormalTilingX, _NormalTilingY) * 0.5);

				float3 normalMap1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uvPanner1));


				// float3 normalMap2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uvPanner2));

				half3 RainnyNormal = 0;
				float rippleShape = 0;
				_UseRainnyNormal = 0;
				if (_UseRainnyNormal != 0)
				{
					Gradient _GradientColor = NewGradient(0, 3, 2, float4(1, 1, 1, 0.1906157), float4(0, 0, 0, 0.205803), float4(1, 1, 1, 0.2156542), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float2(1, 0), float2(1, 1), float2(0, 0), float2(0, 0), float2(0, 0), float2(0, 0), float2(0, 0), float2(0, 0));
					float rippleTiling = _DepthOffset.w;
					float2 randomMosaic = floor(i.positionWS.xz / rippleTiling);
					float randomMosaic1 = RandomRange_float(randomMosaic, 0.3, 0.7);

					float randomMosaic2 = RandomRange_float(randomMosaic + 1, 0.3, 0.7);

					float2 randomMosaicCombine = float2(randomMosaic1, randomMosaic2);



					float2 rippleMask = frac(i.positionWS.xz / rippleTiling);


					rippleShape = distance(randomMosaicCombine, rippleMask);


					float randomFlowMask = frac(_Time.y) * _SpecularExponent.w;
					float randomRippleMask2 = RandomRange_float(randomMosaic + 2, 0, 1);
					float randomRippleMask = 1 - frac(RandomRange_float(randomMosaic + 2, 0, 1) + randomFlowMask);
					// return float4(randomRippleMask2.xxx, 1);
					rippleShape += randomRippleMask;

					float4 rippleShapeColor = 0;
					rippleShape = 1 - Unity_SampleGradient_float(_GradientColor, rippleShape);
					rippleShape = min(rippleShape, pow(randomMosaic2, 4)) * 2;
				}
				// half3 worldNormal = BlendNormals(normalMap1, normalMap2);

				half3 worldNormal = normalMap1;

				half3 specularNormal = worldNormal;
				// _normalScale = lerp(_normalScale, 0, normalizeFresnel);
				// worldNormal = lerp(normalize(half3(0, 0, 1)), worldNormal, _normalScale);




				float3 swelledNormal = float3(dot(tanToWorld0, worldNormal), dot(tanToWorld1, worldNormal), dot(tanToWorld2, worldNormal));
				float3 specularNormalDis = float3(dot(tanToWorld0, specularNormal), dot(tanToWorld1, specularNormal), dot(tanToWorld2, specularNormal));


				float2 screenUV = i.screenPos.xy / i.screenPos.w;



				float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);





				float3 reflDir = reflect(-worldViewDir, swelledNormal);
				float4 reflectionColor = SAMPLE_TEXTURECUBE(_CubeMap, sampler_CubeMap, reflDir) ;


				reflectionColor = lerp(reflectionColor / 2 * _BaseColor, reflectionColor / 2 * _BaseColorFar, normalizeFresnelReflect);






				//.........
				float4 ndcPos = (i.screenPos / i.screenPos.w) * 2 - 1;
				float3 clipVec = float3(ndcPos.x, ndcPos.y, 1.0) * _ProjectionParams.z;
				float3 viewVec = mul(unity_CameraInvProjection, clipVec.xyzz).xyz;
				float sceneZ1 = Linear01Depth(sceneZ, _ZBufferParams);
				float3 viewPos = sceneZ1 * viewVec;
				float3 worldPos = mul(UNITY_MATRIX_I_V, float4(viewPos, 1.0)).xyz;//深度重构世界坐标

				sceneZ = LinearEyeDepth(sceneZ, _ZBufferParams);

				half DepthMask = (sceneZ - ComputeScreenPos(TransformWorldToHClip(i.positionWS)).w);

				DepthMask = saturate(smoothstep(0.5, _BlendDepth, DepthMask));//



				float4 reflection = SAMPLE_TEXTURECUBE(_ReflectionTex, sampler_ReflectionTex, reflDir);



				reflection.rgb = Desaturation(reflection.rgb, 0.5);

				reflection.rgb = lerp(reflection.rgb, reflectionColor.rgb, 0.7) / 2;

				float4 reflectionMix = lerp(reflectionColor, reflection, saturate(_RefAlpha));
				reflectionMix = reflectionMix;


				float3 flowMask = SAMPLE_TEXTURE2D(_FlowMask, sampler_FlowMask, float2(i.uv.x + swelledNormal.r * _Distortion * 5, i.uv.y + frac(_Time.x * _FlowSpeedY)) * float2(_FlowMaskTilingX, _FlowMaskTilingY));

				float AlphaMask = SAMPLE_TEXTURE2D(_FlowMask, sampler_FlowMask, float2(i.uv.x, i.uv.y + frac(_Time.x * _FlowSpeedY))).b;
				screenUV = float2(i.screenPos.x, i.screenPos.y + (swelledNormal.r * _Distortion * 100) * pow(DepthMask, 0.5) * flowMask.b) / i.screenPos.w;



				float2 screenUVRefrac = screenUV;// float2((i.screenPos.x + swelledNormal.r * _Distortion * 100), i.screenPos.y) / i.screenPos.w;


				float4 colrefrac = tex2D(_CameraOpaqueTexture, screenUVRefrac);
				float3 color = (reflectionMix.rgb) + rippleShape ;




				// return float4(color.rgb, 1);

				half3 specularLighting = 0;

				if (_UseRainnyNormal == 0)
				{


					half3 halfDir = normalize(mainLight.direction + normalize(worldViewDir)) ;
					specularLighting = _SpecularExponent.x * pow(max(0, dot(halfDir, specularNormalDis)), _SpecularExponent.y);


					float perceptualRoughness = 1 - _SpecularExponent.y;

					float roughness = perceptualRoughness * perceptualRoughness;
					float squareRoughness = roughness * roughness;

					float nh = max(saturate(dot(swelledNormal, halfDir)), 0.000001);
					float nl = max(saturate(dot(swelledNormal, mainLight.direction.xyz)), 0.000001);
					float nv = max(saturate(dot(swelledNormal, normalize(worldViewDir))), 0.000001);
					float lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);
					float D = lerpSquareRoughness / (pow((pow(nh, 2) * (lerpSquareRoughness - 1) + 1), 2) * 3.1416);

					float kInDirectLight = pow(squareRoughness + 1, 2) / 8;
					float kInIBL = pow(squareRoughness, 2) / 8;
					float GLeft = nl / lerp(nl, 1, kInDirectLight);
					float GRight = nv / lerp(nv, 1, kInDirectLight);
					float G = GLeft * GRight;
					float vh = max(saturate(dot(halfDir, worldViewDir)), 0.000001);
					float3 F0 = reflectionColor.rgb;
					float3 F = F0 + (1 - F0) * exp2((-5.55473 * vh - 6.98316) * vh);

					float spec = D * G * F / (nv * nl * 4);


					// half specDisappear = lerp(spec, 0, saturate(abs(mainLight.direction.x * 90)));
					// spec = (mainLight.direction <= 0)?(specDisappear): spec;


					specularLighting = spec * _SpecularExponent.x * mainLight.color.rgb;
					specularLighting = half4(specularLighting * _SpecularExponent.z, 1);

					// #endif

				}

				specularLighting = specularLighting * 1;


				color.rgb += specularLighting.xxx;



				color.rgb += lerp(color.rgb, flowMask.g, _FlowMaskOpacity);


				color.rgb *= mainLight.color;


				// return float4(flowMask.bbb, 1);

				color = lerp(colrefrac.rgb, color, DepthMask * _Opacity) ;


				#if _FOG_ON
					color.rgb = ApplyFog(color.rgb, i.positionWS);
					// col.rgb = MixFog(col.rgb, i.fogFactor);
					// return half4(i.positionWS, 1);
				#endif







				return float4(color.rgb, AlphaMask);
			}

			ENDHLSL

		}
	}
}