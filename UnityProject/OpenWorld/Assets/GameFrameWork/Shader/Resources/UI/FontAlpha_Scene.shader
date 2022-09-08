// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
//场景使用的头顶飘字 只限场景浮字使用
//带深度
Shader "GUI/Text Alpha Scene"
{
	Properties
	{
		_MainTex ("Font Texture", 2D) = "white" { }
		_Color ("Text Color", Color) = (1, 1, 1, 1)

		[Enum(UnityEngine.Rendering.CompareFunction)]
		_ZTest ("ZTest", Float) = 8 		// Always
		[Enum(On, 1, Off, 0)]
		_ZWrite ("ZWrite", Float) = 0 	// Off

	}

	SubShader
	{

		Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" }
		Lighting Off
		Cull Off
		ZTest [_ZTest]
		ZWrite [_ZWrite]
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ UNITY_SINGLE_PASS_STEREO STEREO_INSTANCING_ON STEREO_MULTIVIEW_ON
			#pragma multi_compile _ FONT_TEX_ENCODE
			// #include "UnityCG.cginc"
			// #include "../CGIncludes/LingrenCG.cginc"
			// #include "../CGIncludes/LingrenUI.cginc"
			#include "./../HLSLIncludes/UI/HMKUI.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			uniform float4 _MainTex_ST;
			uniform half4 _Color;
			CBUFFER_END

			sampler2D _MainTex;
			

			struct appdata_t
			{
				float4 vertex: POSITION;
				half4 color: COLOR;
				float2 texcoord: TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex: SV_POSITION;
				half4 color: COLOR;
				float4 texcoord: TEXCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			

			v2f vert(appdata_t v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.color = v.color * _Color;
				o.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				#if FONT_TEX_ENCODE
					o.texcoord.zw = GetFontEncodeUV(v.texcoord);
				#endif
				return o;
			}

			half4 frag(v2f i): SV_Target
			{
				half4 col = i.color;
				#if FONT_TEX_ENCODE
					col.a *= GetFontA(_MainTex, i.texcoord);
				#else
					col.a *= tex2D(_MainTex, i.texcoord).a;
				#endif
				clip(col.a - 0.001);
				return col;
			}
			ENDHLSL

		}
	}
}
