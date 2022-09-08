Shader  "HMK/Scene/Sky"
{
	Properties
	{
		_StaticCloudTexture ("CloudTexture", 2D) = "white" { }
		_SunTexture ("SunTexture", 2D) = "white" { }
		_SunTheta ("SunTheta", vector) = (0, 0, 0, 0)
		_SunDirection ("SunDir", Vector) = (0, 1, 0)
		_Size ("Size", Float) = 1
		_Scatter ("Scatter", Range(1, 10)) = 1
		_Exposure ("Exposure", float) = 1.5
		_StaticCloudRotationSpeed ("CloudRotationSpeed", Range(-1, 1)) = 0.01
		_GamaRange ("Gamma", float) = 2.2
		[Toggle(UseFog)] UseFog ("UseFog", Float) = 0
		_FogHeight ("_FogHeight", range(0, 1)) = 0.1
		_FogOffset ("Fog offset", Range(0, 1)) = 0
		_RayleighColor ("RayleighColor", color) = (1, 1, 1, 1)
		_MieColor ("MieColor", color) = (1, 1, 1, 1)
	}
	SubShader
	{
		Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" "IgnoreProjector" = "True" }
		Cull [_CullMode] // Render side
		// Cull Front
		Fog
		{
			Mode Off
		}// Don't use fog
		ZWrite on
		ZTest LEqual       // Don't draw to bepth buffer

		Pass
		{
			CGPROGRAM

			#pragma shader_feature UseFog

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0


			sampler2D _StaticCloudTexture;
			sampler2D _SunTexture;
			float3 _SunTheta;

			float3 _SunDirection;
			float _Size;
			float _Scatter;
			float4x4 _NoiseMatrix = 0;
			float _StaticCloudRotationSpeed;
			float _FogHeight;
			float _FogOffset;
			float _GamaRange;
			float _Exposure;
			half4 _RayleighColor;
			half4 _MieColor;
			half4 _BmColor;


			// uniform float4x4     _NoiseMatrix;

			struct appdata
			{
				float4 vertex: POSITION;
				float2 uv: TEXCOORD0;
			};

			struct v2f
			{
				float4 Position: SV_POSITION;
				float3 WorldPos: TEXCOORD2;
				float3 SunPos: TEXCOORD1;
				float2 uv: TEXCOORD0;
				float3 NoiseRot: TEXCOORD4;
			};

			v2f vert(appdata v)
			{
				v2f Output;
				UNITY_INITIALIZE_OUTPUT(v2f, Output);

				float4x4 _UpMatrix = float4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1);


				Output.Position = UnityObjectToClipPos(v.vertex);
				Output.WorldPos = normalize(mul((float3x3)unity_WorldToObject, v.vertex.xyz));
				Output.WorldPos = normalize(mul((float3x3)_UpMatrix, Output.WorldPos));

				float3x3 SunRotaX = float3x3(1, 0, 0, 0, cos(_SunTheta.x), -sin(_SunTheta.x), 0, sin(_SunTheta.x), cos(_SunTheta.x));
				float3x3 SunRotaY = float3x3(cos(_SunTheta.y), 0, sin(_SunTheta.y), 0, 1, 0, -sin(_SunTheta.y), 0, cos(_SunTheta.y));
				float3x3 SunRotaZ = float3x3(cos(_SunTheta.z), -sin(_SunTheta.z), 0, sin(_SunTheta.z), cos(_SunTheta.z), 0, 0, 0, 1);
				//Matrix.
				//--------------------------------
				Output.SunPos = mul(SunRotaX, v.vertex.xyz) ;
				Output.SunPos = mul(SunRotaY, Output.SunPos);
				Output.SunPos = mul(SunRotaZ, Output.SunPos) * _Size;
				Output.uv = v.uv;


				return Output;
			}


			bool iSphere(in float3 origin, in float3 direction, in float3 position, in float radius, out float3 normalDirection)
			{
				float3 rc = origin - position;
				float c = dot(rc, rc) - (radius * radius);
				float b = dot(direction, rc);
				float d = b * b - c;
				float t = -b - sqrt(abs(d));
				float st = step(0.0, min(t, d));
				normalDirection = normalize(-position + (origin + direction * t));

				if (st > 0.0)
				{
					return true;
				}
				return false;
			}


			float4 frag(v2f IN): SV_Target
			{
				//Initializations.
				//--------------------------------
				//_Scattering = 30;

				float4x4 _UpMatrix = float4x4(1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0);
				float4 _StaticCloudColor = 1;
				float4 _SunDiskColor = 1;
				// float4 _MieColor = 1;
				// float4 _RayleighColor = 1;
				// float _StaticCloudRotationSpeed = 0.05;
				float _StaticCloudIntensity = 1;
				float _StaticCloudPower = 4.2;
				float _StaticCloudExtinction = 0.25;
				float _StaticCloudScattering = 1;
				float _Km = 1.25;
				float _Kr = 8.4;
				// float _Exposure = 1.5;
				float _Pi = 3.141593;
				float _SunDiskIntensity = 3;
				float _Scattering = 25;
				float _Pi14 = 0.000096831;
				float _Pi316 = 0.0596831;
				float3 _MieG = float3(0.4, 1.6, 1.5);

				float3 _Br = float3(0.001, 0.1, 0.1);

				float3 _Bm = float3(0, 0.2, 0);



				float3 inScatter = float3(0.0, 0.0, 0.0);
				float3 fex = float3(0.0, 0.0, 0.0);
				float r = length(float3(0.0, 1, 0.0));

				//Directions.z
				//--------------------------------
				float3 viewDir = normalize(IN.WorldPos);
				float sunCosTheta = dot(viewDir, normalize(_SunDirection));

				float sunRise = saturate(dot(float3(0.0, 500.0, 0.0), normalize(_SunDirection)) / r);


				//Optical Depth.
				//--------------------------------
				float zenith = acos(saturate(dot(float3(0.0, 1.0, 0.0), viewDir)));
				float z = cos(zenith) + 0.15 * pow(93.885 - ((zenith * 180.0) / _Pi), -1.253);
				float SR = _Kr / z;
				float SM = _Km / z;

				//Total Extinction.
				//--------------------------------
				fex = exp( - (_Br * SR + _Bm * SM));
				float sunset = clamp(dot(float3(0.0, 1.0, 0.0), normalize(_SunDirection)), 0.0, 0.5);
				float3 extinction = lerp(fex, (1.0 - fex), sunset);

				//Scattering.
				//--------------------------------
				//float  rayPhase = 1.0 + pow(sunCosTheta, 2.0);										 //Preetham rayleigh phase function.
				float rayPhase = 2.0 + 0.5 * pow(sunCosTheta, 2.0);									 //Rayleigh phase function based on the Nielsen's paper.
				float miePhase = _MieG.x / pow(_MieG.y - _MieG.z * sunCosTheta, 1.5); //The Henyey-Greenstein phase function.

				float3 BrTheta = _Pi316 * _Br * rayPhase * _RayleighColor.rgb * extinction;
				float3 BmTheta = _Pi14 * 100 * _Bm * miePhase * _MieColor.rgb * extinction * sunRise;
				float3 BrmTheta = (BrTheta + BmTheta) / (_Br + _Bm);

				inScatter = BrmTheta * _Scattering * (1.0 - fex);
				inScatter *= sunRise;
				//--------------------------------
				BrTheta = _Pi316 * _Br * rayPhase * _RayleighColor.rgb;
				BrmTheta = (BrTheta) / (_Br + _Bm);

				float horizonExtinction = saturate((viewDir.y) * 1000.0) * fex.g;

				//Sun Disk.
				//--------------------------------
				float3 sunTex = tex2D(_SunTexture, IN.SunPos + 0.5).rgb * _SunDiskColor * _SunDiskIntensity;
				sunTex = pow(sunTex, 2.0);
				sunTex *= fex.b * saturate(sunCosTheta);






				//Clouds.
				//--------------------------------
				float2 cloud_uv = float2(-atan2(viewDir.z, viewDir.x), -acos(viewDir.y)) / float2(2.0 * _Pi, _Pi) + float2(-_StaticCloudRotationSpeed * _Time.x, 0.0);

				float4 cloudTex1 = tex2D(_StaticCloudTexture, cloud_uv);

				float4 cloudColor = cloudTex1;
				float cloudAlpha = 1.0 - cloudColor.b;
				// inScatter = inScatter ;
				float3 cloud = lerp(inScatter * _StaticCloudScattering * 0.4, _StaticCloudColor, cloudColor.r * pow(fex.r, _StaticCloudExtinction)) * _StaticCloudIntensity;
				cloud = pow(cloud, _StaticCloudPower);

				//Output.
				//--------------------------------
				float3 OutputColor = inScatter / _Scatter + cloud + (sunTex) * lerp(1.0, cloudAlpha, saturate(_StaticCloudIntensity));

				//Tonemapping.
				OutputColor = 1.0 - exp(-_Exposure * OutputColor);
				inScatter = 1.0 - exp(-_Exposure * inScatter);

				// Calculate Cloud Extinction.
				float cloudExtinction = saturate(IN.WorldPos.y / 0.25);
				cloudExtinction = 1.0 - cloudExtinction;
				OutputColor = lerp(OutputColor, inScatter, cloudExtinction);

				//Color Correction.
				OutputColor = pow(OutputColor, _GamaRange);

				#if UseFog
					float height = IN.uv.y + _FogOffset; //top = 1, middle = 0, bottom = -1
					height = saturate(height); //top = 1, middle = 0, bottom = 0
					OutputColor = lerp(unity_FogColor.rgb, OutputColor, smoothstep(0, _FogHeight, height));
				#endif
				//return 1;
				return float4(OutputColor, 1);
			}
			ENDCG

		}
	}
}