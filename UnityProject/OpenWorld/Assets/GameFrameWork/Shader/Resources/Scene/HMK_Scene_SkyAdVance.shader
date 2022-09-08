Shader "HMK/Scene/StylizedSky"
{
    Properties
    {

        [Header(Cloud)]
        [NoScaleOffset] _CloudDetailTex ("CloudDetailTex", 2D) = "white" { }
        //_CloudShapeTex ("CloudShapeTex", 2D) = "white" { }
        [NoScaleOffset] _CloudContrastTex ("CloudContrastTex", 2D) = "white" { }
        [HDR][NoScaleOffset]_MoonTexture ("MoonTextureCUBE", Cube) = "white" { }
        // _MoonTexture2D ("MoonTexture2D", 2D) = "white" { }
        // _SkyColorTex ("SkyColorTex", 2D) = "white" { }
        _CloudSizeRatio ("CloudSizeRatio", float) = 1

        _DetailSize ("DetailSize", float) = 1
        _DetailStr_fewCloud ("DetailStr_fewCloud", float) = 3
        _DetailStr ("DetailStr", float) = 0.5
        _CloudFill ("CloudFill", float) = 0.5
        _CloudContrastSize ("CloudContrastSize", float) = 4
        _CloudFillMax ("CloudFillMax", float) = 1
        _CloudFillMin ("CloudFillMin", float) = -1
        _ContrastMax ("ContrastMax", float) = 0.1
        _ContrastMin ("ContrastMin", float) = 0.01
        _CloudContrastExp ("CloudContrastExp", float) = 4

        _CloudBaseMoveSpeed ("Cloud Base Move Speed", Range(0.01, 1)) = 0.1

        // _SunRadius ("SunRadius", float) = 0
        // _SunSizeConvergence ("SunSizeConvergence", float) = 1

        _LightUvOffset ("LightUvOffset", float) = 0.015
        _RimContrast ("RimContrast", float) = 0
        _CloudColor ("CloudColor", color) = (1, 1, 1, 1)
        [HDR]_RimColor ("RimColor", color) = (1, 1, 1, 1)

        [Space(50)]
        [Header(SunMoon)]

        // [HDR]_LightColorSun ("LightColor", color) = (1, 1, 1, 1)
        // [HDR]_LightColorSunNear ("LightColorSunNear", color) = (1, 1, 1, 1)
        // [HDR]_SunGlowColor ("SunGlowColor", color) = (1, 1, 1, 1)
        _SunGlowRadius ("SunGlowRadius", float) = 0.45
        _SunGlowEmissive ("SunGlowEmissive", float) = 1
        _LightRadius ("LightRadius", float) = 1.3
        _LightEmissive ("LightEmissives", float) = 1
        // [HDR] _SunMoonColor ("SunMoonColor", color) = (1, 1, 1, 1)
        _SunMoonSize ("SunMoonSize", float) = 1
        _SunMoonChange ("SunMoonChange", range(0, 1)) = 0
        _LightStrength ("LightStrength", float) = 1

        [Space(50)]
        [Header(Sky)]

        _SkyTopColor ("SkyTopColor", color) = (1, 1, 1, 1)
        [HDR]_SkyDownColor ("SkyDownColor", color) = (1, 1, 1, 1)

        // _MoonOrbitAngle ("Moon Orbit Start Angle (XYZ)", vector) = (0, 0, 45, 0)
        // _MoonOrbitSpeed ("Moon Orbit Speed", Range(-1, 1)) = .05
        // _MoonSemiMajAxis ("Moon Semi Major Axis", float) = 1
        // _MoonSemiMinAxis ("Moon Semi Minor Axis", float) = 1
        // _MoonMaxSize ("MoonMaxSize", float) = 1
        // _MoonMinSize ("MoonMinSize", float) = 0
        [Space(50)]
        [Header(Star)]
        [HDR][NoScaleOffset] _starTexture ("starTexture", Cube) = "white" { }
        [NoScaleOffset]_starTwinkle ("starTwinkle", Cube) = "white" { }
        // _TwinkleAngle ("TwinkleAngle", vector) = (0, 0, 0, 0)
        _TwinkleSpeed ("TwinkleSpeed", vector) = (0, 0, 0, 0)
        _StarMixWeight ("StarMixWeight", range(0, 1)) = 0
        _StarInt ("StarInt", float) = 1
        _StarMoveAngle ("StarMoveAngle", vector) = (0, 0, 0, 0)
        _StarMoveSpeed ("StarMoveSpeed", vector) = (0, 0, 0, 0)
        _StarScale ("StarScale", float) = 1

        [HDR][NoScaleOffset] _galaxyTexture ("galaxyTexture", Cube) = "white" { }
        _GalaxyAngle ("GalaxyAngle", vector) = (0, 0, 0, 0)
        _GalaxySpeed ("GalaxySpeed", vector) = (0, 0, 0, 0)
        _AllSpeedScale ("AllSpeedScale", float) = 1
        [Space(50)]
        [Header(Thunder)]
        [NoScaleOffset] _ThunderGlowPosition ("GlowPosition", 2D) = "white" { }
        _ThunderColor ("ThunderColor", color) = (1, 1, 1, 1)
        _FlashSpeed ("FlashSpeed", float) = 0
        _GlowSpeed ("GlowSpeed", float) = 0
        _Dir ("Dir", float) = 0
        [Space(50)]
        [Header(DarkStar)]
        [NoScaleOffset] _DarkStarTex ("DarkStarTex", 2D) = "white" { }
        [HDR]_DarkStarColor ("DarkStarColor", color) = (1, 1, 1, 1)
        _DarkStarTheta ("DarkStarTheta", vector) = (0, 0, 0, 0)
        _DarkStarSize ("DarkStarSize", vector) = (1, 1, 1, 1)


        [Space(50)]
        [Header(Fog)]
        _FogHeight ("FogHeight", float) = 1
        _FogOffset ("FogOffset", float) = 1


        _StarOffset ("_StarOffset", float) = 0
        // _TotalTime ("TotalTime", float) = 0

    }




    SubShader
    {
        Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" "IgnoreProjector" = "True" }
        Cull back

        ZWrite on
        ZTest LEqual       // Don't draw to bepth buffer
        LOD 100

        Pass
        {


            // Blend one OneMinusSrcAlpha



            HLSLPROGRAM

            // #pragma multi_compile_fog
            #pragma shader_feature _FOG_ON
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../HLSLIncludes/Common/Fog.hlsl"
            #include "./../Scene/Hidden/Wind.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half _CloudSizeRatio, _DetailSize, _DetailStr_fewCloud, _DetailStr ;
            half _CloudFill, _CloudFillMax, _CloudFillMin;
            half _CloudContrastSize, _CloudContrastExp, _ContrastMax, _ContrastMin;
            half _SunGlowRadius, _LightUvOffset, _SunRadius, _SunSizeConvergence;
            half _RimContrast, _LightRadius, _LightEmissive, _SunGlowEmissive;
            half4 _SkyTopColor, _SkyDownColor;
            half4 _CloudColor, _RimColor;
            half _CloudBaseMoveSpeed;
            // half _FogHeight;
            half _FogOffset;
            // float4 _MoonOrbitAngle;
            float _SunMoonSize, _FlashSpeed, _GlowSpeed;
            // float _MoonOrbitSpeed, _MoonSemiMajAxis, _MoonSemiMinAxis;
            // float _MoonMaxSize, _MoonMinSize;
            float _StarMixWeight, _SunMoonChange;
            half4 _ThunderColor;
            // float3 _LightDir;//传入的光源方向
            half _Dir;
            half4 _DarkStarTheta;
            half4 _DarkStarColor;
            half4 _DarkStarSize;
            half4 _GalaxyAngle, _GalaxySpeed;
            half4 _TwinkleAngle, _TwinkleSpeed;
            half4 _StarMoveAngle, _StarMoveSpeed;
            half _StarInt, _StarScale;
            half _LightStrength, _AllSpeedScale;
            float _StarOffset;

            ////


            CBUFFER_END

            TEXTURE2D(_CloudDetailTex);SAMPLER(sampler_CloudDetailTex);
            // TEXTURE2D(_CloudShapeTex);SAMPLER(sampler_CloudShapeTex);
            TEXTURE2D(_CloudContrastTex);SAMPLER(sampler_CloudContrastTex);
            // TEXTURE2D(_SkyColorTex);SAMPLER(sampler_SkyColorTex);
            sampler2D _ThunderGlowPosition;
            sampler2D _DarkStarTex;
            samplerCUBE _MoonTexture;
            samplerCUBE _starTexture;
            samplerCUBE _galaxyTexture;
            samplerCUBE _starTwinkle;
            // sampler2D _MoonTexture2D;
            struct Attributes
            {
                float4 positionOS: POSITION;
                float4 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float3 positionWS: TEXCOORD1;
                float3 position: TEXCOORD2;
                half fogFactor: TEXCOORD3;
                float3 DarkStarPos: TEXCOORD4;
                float2 uv2: TEXCOORD5;
                float3 starCubeUv: TEXCOORD6;
                float3 twinkleCubeUv: TEXCOORD7;
                float3 galaxyCubeUv: TEXCOORD8;
            };


            float SphereIntersect(float3 rayOrigin, float3 rayDirection, float3 spherePos, float sphereRadius)
            {
                float3 originToCenter = rayOrigin - spherePos;
                float b = dot(originToCenter, rayDirection);
                float c = dot(originToCenter, originToCenter) - sphereRadius * sphereRadius;
                float h = b * b - c;
                if (h < 0.0)
                {
                    return -1.0;
                }
                h = sqrt(h);
                return -b - h;
            }


            //this is using the equation of an ellipse. The angle is time * speed, or what ever angle you want to sample at
            float3 ElipsePosition(float2 MajMinAxis, float angle)
            {
                float3 orbitPos;
                orbitPos.x = (MajMinAxis.x * cos(angle));
                orbitPos.y = 0;
                orbitPos.z = (MajMinAxis.y * sin(angle));
                return normalize(orbitPos);
            }
            float3 axisRotation(float3 angelxyz, float3 position)
            {
                float3x3 rotateX = float3x3(1, 0, 0, 0, cos(angelxyz.x), -sin(angelxyz.x), 0, sin(angelxyz.x), cos(angelxyz.x));
                float3x3 rotateY = float3x3(cos(angelxyz.y), 0, sin(angelxyz.y), 0, 1, 0, -sin(angelxyz.y), 0, cos(angelxyz.y));
                float3x3 rotateZ = float3x3(cos(angelxyz.z), -sin(angelxyz.z), 0, sin(angelxyz.z), cos(angelxyz.z), 0, 0, 0, 1);

                float3 positionRotate = mul(rotateX, position);
                positionRotate = mul(rotateY, positionRotate);
                positionRotate = mul(rotateZ, positionRotate);

                return positionRotate;
            }

            float GetMoonDistance(float Min, float Max, float2 MajMinAxis, float angle)
            {
                float3 pos = ElipsePosition(MajMinAxis, angle);
                float lerpFactor = abs(dot(pos, float3(0, 0, 1)));
                float dist = lerp(Min, Max, smoothstep(0, 1, lerpFactor));
                return dist;
            }
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = input.positionOS.xyz;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.position = input.uv.xyz;
                output.uv2 = input.uv * float2(-1, -1);
                float3 normalPos = output.positionWS.xyz;
                output.uv = normalPos.xz / (normalPos.y) ;

                // float3x3 DarkStarX = float3x3(1, 0, 0, 0, cos(_DarkStarTheta.x), -sin(_DarkStarTheta.x), 0, sin(_DarkStarTheta.x), cos(_DarkStarTheta.x));
                // float3x3 DarkStarY = float3x3(cos(_DarkStarTheta.y), 0, sin(_DarkStarTheta.y), 0, 1, 0, -sin(_DarkStarTheta.y), 0, cos(_DarkStarTheta.y));
                // float3x3 DarkStarZ = float3x3(cos(_DarkStarTheta.z), -sin(_DarkStarTheta.z), 0, sin(_DarkStarTheta.z), cos(_DarkStarTheta.z), 0, 0, 0, 1);
                float3 DarkStarPosition = axisRotation(_DarkStarTheta.rgb, input.positionOS.xyz);
                //Matrix.
                //--------------------------------
                // output.DarkStarPos = mul(DarkStarX, input.positionOS.xyz) ;
                // output.DarkStarPos = mul(DarkStarY, output.DarkStarPos);
                // output.DarkStarPos = mul(DarkStarZ, output.DarkStarPos) * _DarkStarSize.rgb;
                output.DarkStarPos = DarkStarPosition * _DarkStarSize.rgb;
                output.starCubeUv = axisRotation(_StarMoveAngle.xyz, input.positionOS.xyz) ;

                // output.starCubeUv = axisRotation(_StarMoveSpeed * _Time.y * _AllSpeedScale, output.starCubeUv.xyz) ;
                output.starCubeUv = axisRotation(_StarMoveSpeed * _StarOffset, output.starCubeUv.xyz) ;
                // output.twinkleCubeUv = axisRotation(_TwinkleSpeed * _Time.y, output.starCubeUv.xyz) ;

                output.galaxyCubeUv = axisRotation(_GalaxyAngle.xyz, input.positionOS.xyz) ;
                // output.galaxyCubeUv = axisRotation(_GalaxySpeed.xyz * _Time.y * _AllSpeedScale, output.galaxyCubeUv.xyz);
                output.galaxyCubeUv = axisRotation(_GalaxySpeed.xyz * _StarOffset, output.galaxyCubeUv.xyz) ;
                half fogFactor = ComputeFogFactor(output.positionCS.z);

                output.fogFactor = fogFactor;


                return output;
            }

            half calcSunAttenuation(half3 lightPos, half3 ray, float SunSize, float SunSizeConvergence)
            {

                half3 delta = lightPos - ray;
                half dist = length(delta);
                half spot = 1.0 - smoothstep(saturate(SunSize - 0.05), SunSize, dist);
                return spot * spot;
                // #else // SKYBOX_SUNDISK_HQ
                //     half focusedEyeCos = pow(saturate(dot(lightPos, ray)), SunSizeConvergence);
                //     return getMiePhase(-focusedEyeCos, focusedEyeCos * focusedEyeCos, SunSize);
                // #endif

            }
            float4 frag(Varyings input): SV_Target
            {

                Light mainLight = GetMainLight();
                mainLight.direction.xyz = normalize(_LightDir);
                mainLight.color = clamp(mainLight.color, 0.1, 1.2) * _LightStrength;
                // return float4(mainLight.direction.xyz, 1);

                half3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);

                // mainLight.direction.xyz = input.LightPos.xyz + _SunDir.w;
                float4 DarkStarMap = tex2D(_DarkStarTex, input.DarkStarPos + 0.5) * _DarkStarColor ;



                //Moon

                float orbitAngle = 0;// _Time.y * _MoonOrbitSpeed;

                //we also need to grab the half radius of the ellipse at the major and minor Axis
                //these are used in the ellipse equation.
                float2 MajMinAxis = 1;//float2(_MoonSemiMajAxis, _MoonSemiMinAxis);

                //this equation takes these values along with the _MoonOrbitAngle to figure out the position in the moons orbit
                float3 currentMoonPos = mainLight.direction.xyz; //GetOrbitPosition(_MoonOrbitAngle, MajMinAxis, orbitAngle);


                float3 MoonColor = 0;
                float MoonMask = 0;

                float radius = GetMoonDistance(_SunMoonSize, 1, MajMinAxis, orbitAngle);
                float sphere = SphereIntersect(float3(0, 0, 0), -worldViewDir, currentMoonPos, radius);

                //get the position on the sphere and use that to get the normal for the sphere
                float3 moonFragPos = -worldViewDir * sphere + float3(0, 0, 0);
                //the normal is how we eventually get uvs and lighting
                float3 moonFragNormal = normalize(moonFragPos - currentMoonPos);

                // //get uv from the normal
                // float u = atan2(moonFragNormal.z, moonFragNormal.x) / (PI * 2);
                // //to get around this we take the frac of this u value because these values are the same at the boundary but the frac value doesnt have the seam
                // float fracU = frac(u);

                // //so then we just pick which of the u values we want, the -0.001 just makes it favor the original one
                // //to get the y we use acos which returns the same as atan. using acos is better than asin because asin causes warping at the poles
                // float2 moonUV = float2(
                //     fwidth(u) < fwidth(fracU) - 0.001 ? u: fracU,
                //     acos(-moonFragNormal.y) / PI
                // );

                // // if our sphere tracing returned a positive value we have a moon fragment
                if (sphere >= 0.0)
                {
                    //so we grab the moon tex and multiple the color
                    MoonMask = 1;
                    if (_SunMoonChange < 0.5)
                    {
                        MoonMask = 0;
                    }

                    //then lerp to the final color masking out anything under the horizon

                }

                // float2 moonUV2D = acos(dot(moonFragNormal, -mainLight.direction)) / (PI);
                // moonUV2D = ComputeScreenPos(moonFragNormal.xyzx).xy;
                // float3 MoonCube = texCUBE(_starTexture, moonFragNormal);

                //SkyColor;
                float SkyColorMask = 1 - saturate(dot(worldViewDir, float3(0, -1, 0)));
                float SkyColorMaskExp = saturate(pow(SkyColorMask, 5) - 0.37);
                float SkyColorMaskExp2 = saturate(pow(SkyColorMask, _Dir));


                half radiusLerp = saturate(_CloudFill / 2 - 0.5);

                half3 LightColorMaskDir = (-mainLight.direction.xyz - worldViewDir) / lerp(0, _LightRadius, radiusLerp);

                half LightColorMask = dot(LightColorMaskDir, LightColorMaskDir);


                LightColorMask = (pow(saturate(LightColorMask), 0.1));
                LightColorMask = 1 - saturate(pow(LightColorMask, 2));

                LightColorMask = saturate(LightColorMask * _LightEmissive);

                _SkyDownColor = lerp(_SkyDownColor, float4(mainLight.color, 1), LightColorMask);

                half4 var_SkyColor = lerp(_SkyTopColor, _SkyDownColor, SkyColorMaskExp2);


                //...CLOUDyz
                half2 windDir = _CloudBaseMoveSpeed * WindMoveOffset;
                half4 var_CloudDetailTex = SAMPLE_TEXTURE2D(_CloudDetailTex, sampler_CloudDetailTex, input.uv * _CloudSizeRatio * _DetailSize - windDir);
                // return saturate(float4(input.uv, 0, 1)) ;

                half4 var_CloudShapeTex = var_CloudDetailTex ;//SAMPLE_TEXTURE2D(_CloudDetailTex, sampler_CloudDetailTex, input.uv * _CloudSizeRatio - windDir);


                half4 var_CloudContrastTex = var_CloudDetailTex;//SAMPLE_TEXTURE2D(_CloudContrastTex, sampler_CloudContrastTex, input.uv * _CloudSizeRatio * _CloudContrastSize - windDir);




                half CloudMix = lerp(_DetailStr_fewCloud * _DetailStr, _DetailStr, _CloudFill);
                half CloudBlend = saturate((1 - abs((var_CloudShapeTex.r - 0.5)) * 2) * CloudMix);
                half CloudMix2 = lerp(var_CloudShapeTex.r, var_CloudDetailTex.r, CloudBlend);
                half CloudFillValue = saturate(_CloudFillMax - (_CloudFillMax - _CloudFillMin) * (1 - _CloudFill) + CloudMix2);
                half CloudContrast = lerp(_ContrastMin, _ContrastMax, pow(var_CloudContrastTex.r, _CloudContrastExp));


                half CloudAlpha = saturate(smoothstep(saturate(0.5 - CloudContrast), saturate(0.5 + CloudContrast), CloudFillValue));
                half CloudMask = 1 - CloudAlpha;
                CloudMask *= pow(saturate(input.position.y + 0.2), 2);
                CloudAlpha *= pow(saturate(input.position.y - 0.1), 1);


                half Alpha = CloudAlpha;
                //....alpha

                //StarTex
                float starMixWeight = 0;

                half moonStarMask = (1 - MoonMask) * (1 - step(0.99, DarkStarMap.a));
                // half4 var_SkyColor = SAMPLE_TEXTURE2D(_SkyColorTex, sampler_SkyColorTex, float2(SkyColorMask, SkyColorMask));


                float3 starUv = input.starCubeUv;// axisRotation(_StarMoveAngle + (_Time.y * _StarMoveSpeed * _AllSpeedScale), input.normalWS);//(input.normalWS)  ;
                float3 twinkleUv = input.twinkleCubeUv;//axisRotation(_StarMoveAngle + (_Time.y * _TwinkleSpeed * _AllSpeedScale), input.normalWS);//(input.normalWS)  ;
                float3 starTex2 = 0;
                if ((_StarScale) != 1)
                {

                    float starUvY = atan2(starUv.y, starUv.z) / 6.283;
                    float twinkleUvY = atan2(twinkleUv.y, twinkleUv.z) / 6.283;

                    float2 starUvX = starUv.yz * starUv.yz;
                    float2 twinkleUvX = twinkleUv.yz * twinkleUv.yz;

                    float starUvCombine = sqrt(starUvX.x + starUvX.y);
                    float twinkleUvCombine = sqrt(twinkleUvX.x + twinkleUvX.y);


                    starUv = float3(starUv.x, starUvY, starUvCombine) * float3(1, _StarScale, 1) ;
                    twinkleUv = float3(twinkleUv.x, twinkleUvY, twinkleUvCombine) * float3(1, _StarScale, 1) ;
                    starTex2 = texCUBE(_galaxyTexture, starUv).rgb * moonStarMask * 2;
                }


                float3 galaxyTex = texCUBE(_galaxyTexture, input.galaxyCubeUv).rgb * moonStarMask * saturate(CloudMask);

                float3 starTex = texCUBE(_starTexture, starUv).rgb * moonStarMask ;

                _StarScale = saturate(_StarScale - 0.9) * 10;


                float starshining = 0;

                if (_StarMixWeight > 0.8)
                {
                    // float starTwinkle = texCUBE(_starTwinkle, twinkleUv).rgb * moonStarMask;
                    starshining = (starTex + galaxyTex.r) > 0.05?(starTex * 10): 0  ;

                    starshining = clamp(_StarInt * starshining, 0, 3);
                    starshining = pow(starshining, 2) * saturate(0.2 - Alpha);
                }
                starTex = lerp(starTex2, starshining, _StarScale);

                // float starTwinkle = step(pow(tex2D(_starTwinkle, input.uv2 * 0.05 + float2(_Time.y * 0.0005, 0)).r, 1), 0.3);





                // starTex *= saturate(0.5 - Alpha) * pow(saturate(input.position.y - 0.1), 0.8);




                float3 starColor = lerp(DarkStarMap.rgb, (starTex + galaxyTex), moonStarMask) * (CloudMask);

                var_SkyColor.rgb = lerp(var_SkyColor.rgb, starColor, _StarMixWeight) ;

                // half3 DarkStarTex = lerp(var_SkyColor.rgb, DarkStarMap.rgb * mainLight.color, saturate(DarkStarMap.a - 0) * saturate(0.5 - Alpha));//DarkStarBlendColor

                float3 DarkStarTex = DarkStarMap.rgb + var_SkyColor.rgb ;


                float3 moonTex = texCUBE(_MoonTexture, moonFragNormal).rgb * (1 - DarkStarMap.a) * saturate(0.5 - Alpha) ;
                // float3 moonTex2D = tex2D(_MoonTexture2D, moonUV2D).rgb * 2;

                MoonColor = lerp(moonTex, var_SkyColor.rgb, 0) * MoonMask;



                //star


                //SunDisk
                float SunDisk = calcSunAttenuation(mainLight.direction, -worldViewDir, _SunMoonSize, 1) * saturate(0.5 - Alpha);
                // return SunDisk;
                float3 SunMoonColor = lerp(SunDisk * 5 * mainLight.color.rgb, MoonColor * 1.5, _SunMoonChange)  ;

                half MaskBlend = max(max(MoonMask, DarkStarMap.a), SunDisk) - DarkStarMap.a;
                SunMoonColor = lerp(DarkStarTex, SunMoonColor, MaskBlend);


                //COLORstar
                half3 Sunvec = normalize(worldViewDir - mainLight.direction.xyz);
                half2 SunvecWS = mul(GetObjectToWorldMatrix(), float4(Sunvec, 0)).rg;

                // half SunLightUv = ( - (mainLight.direction.xyz) - worldViewDir) / 0.45;
                half3 SunLightUv2 = (-worldViewDir) / 0.45;
                half SunLightUv = (dot(SunLightUv2, SunLightUv2)) * _LightUvOffset;



                half2 SunUv = SunvecWS * SunLightUv;
                SunUv = SunLightUv;

                // half4 var_CloudShapeTex2 = SAMPLE_TEXTURE2D(_CloudDetailTex, sampler_CloudDetailTex, input.uv * _CloudSizeRatio + SunUv + float2(0, _Time.y * 0.01));

                // half CloudBlend2 = saturate((1 - abs((var_CloudShapeTex2.r - 0.5)) * 2) * CloudMix);
                // half CloudMix3 = lerp(var_CloudShapeTex2.r, var_CloudDetailTex.r, CloudBlend2);
                // half CloudFillValue2 = saturate(_CloudFillMax - (_CloudFillMax - _CloudFillMin) * (1 - _CloudFill) + CloudMix3);


                // half CloudAlpha2 = saturate(smoothstep(saturate(0.5 - CloudContrast), saturate(0.5 + CloudContrast), CloudFillValue2));




                // half CloudColorMask = saturate(CloudAlpha - CloudAlpha2);
                // CloudColorMask *= pow(saturate(input.position.y - 0.2), 0.5);
                // return CloudColorMask;
                half RimMask = saturate(smoothstep(saturate(0.5 - _RimContrast), saturate(0.5 + _RimContrast), saturate((1 - CloudFillValue))));

                half LightInt = mainLight.color.r * 0.299 + mainLight.color.g * 0.581 + mainLight.color.b * 0.114;
                half3 RimLight = lerp(_CloudColor.rgb, _RimColor.rgb, RimMask).rgb * LightInt * 0.8 ;


                half LightMask = CloudAlpha ;





                half3 DirLightColor = lerp(RimLight, RimLight * 1.2, LightMask) ;//Cloud   Color

                DirLightColor = lerp(DirLightColor, DirLightColor * mainLight.color * 2, LightColorMask);
                half3 SunGlowMaskDir = (-mainLight.direction.xyz - worldViewDir) / lerp(0, _SunGlowRadius, radiusLerp);

                half SunGlowMask = dot(SunGlowMaskDir, SunGlowMaskDir);
                SunGlowMask = (pow(saturate(SunGlowMask), 0.5));

                half SunGlowInt = 0.1;
                if (_SunMoonChange != 0)
                {

                    SunGlowInt = 0.2;
                }
                half3 SunGlowColor = (1 - SunGlowMask) * SunGlowInt * mainLight.color.rgb * (1 - DarkStarMap.a);




                half3 SkyColorMix = lerp(var_SkyColor.rgb * (1 - MaskBlend) + SunMoonColor, DirLightColor, smoothstep(0, 0.3, Alpha)) + SunGlowColor;
                // return smoothstep(0, 0.8, Alpha);

                half3 FinalColor = SkyColorMix;

                // return LightColorMask;
                // half3 FinalColor = lerp(SunGlowColor, SkyColorMix, Alpha);

                //Thunder

                half ThunderBias = ((sin(_Time.y * _FlashSpeed) - 1) * 0.5 + 1) * 0.5;
                half ThunderGlow = (1 - frac((_Time.y / _GlowSpeed * 1000))) * (ThunderBias);
                float TunderUV = floor(frac(_Time.y / _GlowSpeed) * 1000) / 1000;

                half ThunderGlow2 = (1 - frac((_Time.y / _GlowSpeed * 1000 + 0.5))) * (ThunderBias);
                float TunderUV2 = floor(frac(_Time.y / _GlowSpeed + 0.5) * 1000) / 1000;
                half3 ThunderGlowPosition = tex2D(_ThunderGlowPosition, float2(TunderUV, TunderUV));
                // half3 ThunderGlowPosition2 = tex2D(_ThunderGlowPosition, float2(TunderUV2, TunderUV2));


                float2 GlowUV = float2(acos(input.uv.x / 4) / PI, acos(input.uv.y / 4) / PI);
                float GlowSphere = length(ThunderGlowPosition.rg - (GlowUV));

                GlowSphere = 1.0 - smoothstep(0, 0.1, GlowSphere);
                GlowSphere = dot(GlowSphere, GlowSphere) * ThunderGlow;

                // float GlowSphere2 = length(ThunderGlowPosition2.rg - (GlowUV));

                // GlowSphere2 = 1.0 - smoothstep(0, 0.05, GlowSphere2);
                // GlowSphere2 = dot(GlowSphere2, GlowSphere2) * ThunderGlow2;

                half GlowSphereMask = (GlowSphere / 1.5 + GlowSphere) * RimMask ;
                FinalColor = FinalColor + GlowSphereMask * _ThunderColor.rgb * 3;
                half fogfactor = saturate(input.uv2.y + _FogGlobalDensity * 2);
                // fogfactor=smoothstep(0, 0.1, fogfactor);
                // fogfactor = pow(smoothstep(0, 0.1, fogfactor), 1 + _FogGlobalDensity);
                fogfactor = pow(fogfactor, 1 + _FogGlobalDensity);
                fogfactor = saturate(fogfactor);
                // return fogfactor;

                // return LightColorMask;

                // #if _FOG_ON
                //     FinalColor = ApplyFogSkyBox(FinalColor, input.positionWS, mainLight, fogfactor, LightColorMask);
                // #endif

                return half4(FinalColor, 1);
            }

            ENDHLSL

        }
    }
    SubShader
    {
        Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" "IgnoreProjector" = "True" }
        Cull back

        ZWrite on
        ZTest LEqual       // Don't draw to bepth buffer
        LOD 50

        Pass
        {


            // Blend one OneMinusSrcAlpha



            HLSLPROGRAM

            // #pragma multi_compile_fog
            #pragma shader_feature _FOG_ON
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../HLSLIncludes/Common/Fog.hlsl"
            #include "./../Scene/Hidden/Wind.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half _CloudSizeRatio, _DetailSize, _DetailStr_fewCloud, _DetailStr ;
            half _CloudFill, _CloudFillMax, _CloudFillMin;
            half _CloudContrastSize, _CloudContrastExp, _ContrastMax, _ContrastMin;
            half _SunGlowRadius, _LightUvOffset, _SunRadius, _SunSizeConvergence;
            half _RimContrast, _LightRadius, _LightEmissive, _SunGlowEmissive;
            half4 _SkyTopColor, _SkyDownColor;
            half4 _CloudColor, _RimColor;
            half _CloudBaseMoveSpeed;
            // half _FogHeight;
            half _FogOffset;
            // float4 _MoonOrbitAngle;
            float _SunMoonSize, _FlashSpeed, _GlowSpeed;
            // float _MoonOrbitSpeed, _MoonSemiMajAxis, _MoonSemiMinAxis;
            // float _MoonMaxSize, _MoonMinSize;
            float _StarMixWeight, _SunMoonChange;
            half4 _ThunderColor;
            // float3 _LightDir;//传入的光源方向
            half _Dir;
            half4 _DarkStarTheta;
            half4 _DarkStarColor;
            half4 _DarkStarSize;
            half4 _GalaxyAngle, _GalaxySpeed;
            half4 _TwinkleAngle, _TwinkleSpeed;
            half4 _StarMoveAngle, _StarMoveSpeed;
            half _StarInt, _StarScale;
            half _LightStrength, _AllSpeedScale;
            float _StarOffset;

            ////


            CBUFFER_END

            TEXTURE2D(_CloudDetailTex);SAMPLER(sampler_CloudDetailTex);
            // TEXTURE2D(_CloudShapeTex);SAMPLER(sampler_CloudShapeTex);
            TEXTURE2D(_CloudContrastTex);SAMPLER(sampler_CloudContrastTex);
            // TEXTURE2D(_SkyColorTex);SAMPLER(sampler_SkyColorTex);
            sampler2D _ThunderGlowPosition;
            sampler2D _DarkStarTex;
            samplerCUBE _MoonTexture;
            samplerCUBE _starTexture;
            samplerCUBE _galaxyTexture;
            samplerCUBE _starTwinkle;
            // sampler2D _MoonTexture2D;
            struct Attributes
            {
                float4 positionOS: POSITION;
                float4 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float3 positionWS: TEXCOORD1;
                float3 position: TEXCOORD2;
                half fogFactor: TEXCOORD3;
                float3 DarkStarPos: TEXCOORD4;
                float2 uv2: TEXCOORD5;
                float3 starCubeUv: TEXCOORD6;
                float3 twinkleCubeUv: TEXCOORD7;
                float3 galaxyCubeUv: TEXCOORD8;
            };





            //this is using the equation of an ellipse. The angle is time * speed, or what ever angle you want to sample at

            float3 axisRotation(float3 angelxyz, float3 position)
            {
                float3x3 rotateX = float3x3(1, 0, 0, 0, cos(angelxyz.x), -sin(angelxyz.x), 0, sin(angelxyz.x), cos(angelxyz.x));
                float3x3 rotateY = float3x3(cos(angelxyz.y), 0, sin(angelxyz.y), 0, 1, 0, -sin(angelxyz.y), 0, cos(angelxyz.y));
                float3x3 rotateZ = float3x3(cos(angelxyz.z), -sin(angelxyz.z), 0, sin(angelxyz.z), cos(angelxyz.z), 0, 0, 0, 1);

                float3 positionRotate = mul(rotateX, position);
                positionRotate = mul(rotateY, positionRotate);
                positionRotate = mul(rotateZ, positionRotate);

                return positionRotate;
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = input.positionOS.xyz;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.position = input.uv.xyz;
                output.uv2 = input.uv * float2(-1, -1);
                float3 normalPos = output.positionWS.xyz;
                output.uv = normalPos.xz / (normalPos.y) ;

                // float3x3 DarkStarX = float3x3(1, 0, 0, 0, cos(_DarkStarTheta.x), -sin(_DarkStarTheta.x), 0, sin(_DarkStarTheta.x), cos(_DarkStarTheta.x));
                // float3x3 DarkStarY = float3x3(cos(_DarkStarTheta.y), 0, sin(_DarkStarTheta.y), 0, 1, 0, -sin(_DarkStarTheta.y), 0, cos(_DarkStarTheta.y));
                // float3x3 DarkStarZ = float3x3(cos(_DarkStarTheta.z), -sin(_DarkStarTheta.z), 0, sin(_DarkStarTheta.z), cos(_DarkStarTheta.z), 0, 0, 0, 1);
                float3 DarkStarPosition = axisRotation(_DarkStarTheta.rgb, input.positionOS.xyz);
                //Matrix.
                //--------------------------------
                // output.DarkStarPos = mul(DarkStarX, input.positionOS.xyz) ;
                // output.DarkStarPos = mul(DarkStarY, output.DarkStarPos);
                // output.DarkStarPos = mul(DarkStarZ, output.DarkStarPos) * _DarkStarSize.rgb;
                output.DarkStarPos = DarkStarPosition * _DarkStarSize.rgb;
                output.starCubeUv = axisRotation(_StarMoveAngle.xyz, input.positionOS.xyz) ;

                // output.starCubeUv = axisRotation(_StarMoveSpeed * _Time.y * _AllSpeedScale, output.starCubeUv.xyz) ;
                output.starCubeUv = axisRotation(_StarMoveSpeed * _StarOffset, output.starCubeUv.xyz) ;
                // output.twinkleCubeUv = axisRotation(_TwinkleSpeed * _Time.y, output.starCubeUv.xyz) ;

                output.galaxyCubeUv = axisRotation(_GalaxyAngle.xyz, input.positionOS.xyz) ;
                // output.galaxyCubeUv = axisRotation(_GalaxySpeed.xyz * _Time.y * _AllSpeedScale, output.galaxyCubeUv.xyz);
                output.galaxyCubeUv = axisRotation(_GalaxySpeed.xyz * _StarOffset, output.galaxyCubeUv.xyz) ;
                half fogFactor = ComputeFogFactor(output.positionCS.z);

                output.fogFactor = fogFactor;


                return output;
            }

            half calcSunAttenuation(half3 lightPos, half3 ray, float SunSize, float SunSizeConvergence)
            {

                half3 delta = lightPos - ray;
                half dist = length(delta);
                half spot = 1.0 - smoothstep(saturate(SunSize - 0.05), SunSize, dist);
                return spot * spot;
                // #else // SKYBOX_SUNDISK_HQ
                //     half focusedEyeCos = pow(saturate(dot(lightPos, ray)), SunSizeConvergence);
                //     return getMiePhase(-focusedEyeCos, focusedEyeCos * focusedEyeCos, SunSize);
                // #endif

            }
            float4 frag(Varyings input): SV_Target
            {

                Light mainLight = GetMainLight();
                mainLight.direction.xyz = normalize(_LightDir);
                mainLight.color = clamp(mainLight.color, 0.1, 1.2) * _LightStrength;
                // return float4(mainLight.direction.xyz, 1);

                half3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);

                // mainLight.direction.xyz = input.LightPos.xyz + _SunDir.w;
                float4 DarkStarMap = tex2D(_DarkStarTex, input.DarkStarPos + 0.5) * _DarkStarColor ;







                float SkyColorMask = 1 - saturate(dot(worldViewDir, float3(0, -1, 0)));
                float SkyColorMaskExp = saturate(pow(SkyColorMask, 5) - 0.37);
                float SkyColorMaskExp2 = saturate(pow(SkyColorMask, _Dir));


                half radiusLerp = saturate(_CloudFill / 2 - 0.5);

                half3 LightColorMaskDir = (-mainLight.direction.xyz - worldViewDir) / lerp(0, _LightRadius, radiusLerp);

                half LightColorMask = dot(LightColorMaskDir, LightColorMaskDir);


                LightColorMask = (pow(saturate(LightColorMask), 0.1));
                LightColorMask = 1 - saturate(pow(LightColorMask, 2));

                LightColorMask = saturate(LightColorMask * _LightEmissive);

                _SkyDownColor = lerp(_SkyDownColor, float4(mainLight.color, 1), LightColorMask);

                half4 var_SkyColor = lerp(_SkyTopColor, _SkyDownColor, SkyColorMaskExp2);


                //...CLOUDyz
                half2 windDir = _CloudBaseMoveSpeed * WindMoveOffset;
                half4 var_CloudDetailTex = SAMPLE_TEXTURE2D(_CloudDetailTex, sampler_CloudDetailTex, input.uv * _CloudSizeRatio * _DetailSize - windDir);
                // return saturate(float4(input.uv, 0, 1)) ;

                half4 var_CloudShapeTex = var_CloudDetailTex ;//SAMPLE_TEXTURE2D(_CloudDetailTex, sampler_CloudDetailTex, input.uv * _CloudSizeRatio - windDir);


                half4 var_CloudContrastTex = var_CloudDetailTex;//SAMPLE_TEXTURE2D(_CloudContrastTex, sampler_CloudContrastTex, input.uv * _CloudSizeRatio * _CloudContrastSize - windDir);




                half CloudMix = lerp(_DetailStr_fewCloud * _DetailStr, _DetailStr, _CloudFill);
                half CloudBlend = saturate((1 - abs((var_CloudShapeTex.r - 0.5)) * 2) * CloudMix);
                half CloudMix2 = lerp(var_CloudShapeTex.r, var_CloudDetailTex.r, CloudBlend);
                half CloudFillValue = saturate(_CloudFillMax - (_CloudFillMax - _CloudFillMin) * (1 - _CloudFill) + CloudMix2);
                half CloudContrast = lerp(_ContrastMin, _ContrastMax, pow(var_CloudContrastTex.r, _CloudContrastExp));


                half CloudAlpha = saturate(smoothstep(saturate(0.5 - CloudContrast), saturate(0.5 + CloudContrast), CloudFillValue));
                half CloudMask = 1 - CloudAlpha;
                CloudMask *= pow(saturate(input.position.y + 0.2), 2);
                CloudAlpha *= pow(saturate(input.position.y - 0.1), 1);


                half Alpha = CloudAlpha;
                //....alpha

                //StarTex

                half moonStarMask = (1 - step(0.99, DarkStarMap.a));
                // half4 var_SkyColor = SAMPLE_TEXTURE2D(_SkyColorTex, sampler_SkyColorTex, float2(SkyColorMask, SkyColorMask));


                float3 starUv = input.starCubeUv;// axisRotation(_StarMoveAngle + (_Time.y * _StarMoveSpeed * _AllSpeedScale), input.normalWS);//(input.normalWS)  ;


                if ((_StarScale) != 1)
                {

                    float starUvY = atan2(starUv.y, starUv.z) / 6.283;


                    float2 starUvX = starUv.yz * starUv.yz;


                    float starUvCombine = sqrt(starUvX.x + starUvX.y);



                    starUv = float3(starUv.x, starUvY, starUvCombine) * float3(1, _StarScale, 1) ;


                    input.galaxyCubeUv = starUv ;
                };



                float3 galaxyTex = texCUBE(_galaxyTexture, input.galaxyCubeUv).rgb * moonStarMask * saturate(CloudMask);










                float3 starColor = lerp(DarkStarMap.rgb, (galaxyTex), moonStarMask) * (CloudMask);

                var_SkyColor.rgb = lerp(var_SkyColor.rgb, starColor, _StarMixWeight) ;

                // half3 DarkStarTex = lerp(var_SkyColor.rgb, DarkStarMap.rgb * mainLight.color, saturate(DarkStarMap.a - 0) * saturate(0.5 - Alpha));//DarkStarBlendColor

                float3 DarkStarTex = DarkStarMap.rgb + var_SkyColor.rgb ;



                //SunDisk

                // return SunDisk;
                float3 SunMoonColor = mainLight.color.rgb  ;
                half SunGlowInt = 0.1;
                if (_SunMoonChange != 0)
                {
                    _SunMoonSize *= 1.5;
                    SunGlowInt = 0.2;

                    SunMoonColor = float3(0.8, 0.8, 1) * 0.6;
                }
                float SunDisk = calcSunAttenuation(mainLight.direction, -worldViewDir, _SunMoonSize, 1) * saturate(0.5 - Alpha);

                SunMoonColor *= SunDisk * 5 + starColor  ;
                half MaskBlend = max((DarkStarMap.a), SunDisk) - DarkStarMap.a;
                SunMoonColor = lerp(DarkStarTex, SunMoonColor, MaskBlend);


                //COLORstar
                half3 Sunvec = normalize(worldViewDir - mainLight.direction.xyz);
                half2 SunvecWS = mul(GetObjectToWorldMatrix(), float4(Sunvec, 0)).rg;

                // half SunLightUv = ( - (mainLight.direction.xyz) - worldViewDir) / 0.45;
                half3 SunLightUv2 = (-worldViewDir) / 0.45;
                half SunLightUv = (dot(SunLightUv2, SunLightUv2)) * _LightUvOffset;



                half2 SunUv = SunvecWS * SunLightUv;
                SunUv = SunLightUv;


                half RimMask = saturate(smoothstep(saturate(0.5 - _RimContrast), saturate(0.5 + _RimContrast), saturate((1 - CloudFillValue))));

                half LightInt = mainLight.color.r * 0.299 + mainLight.color.g * 0.581 + mainLight.color.b * 0.114;
                half3 RimLight = lerp(_CloudColor.rgb, _RimColor.rgb, RimMask).rgb * LightInt * 0.8 ;


                half LightMask = CloudAlpha ;



                half3 DirLightColor = lerp(RimLight, RimLight * 1.2, LightMask) ;//Cloud   Color

                DirLightColor = lerp(DirLightColor, DirLightColor * mainLight.color * 2, LightColorMask);
                half3 SunGlowMaskDir = (-mainLight.direction.xyz - worldViewDir) / lerp(0, _SunGlowRadius, radiusLerp);

                half SunGlowMask = dot(SunGlowMaskDir, SunGlowMaskDir);
                SunGlowMask = (pow(saturate(SunGlowMask), 0.5));


                half3 SunGlowColor = (1 - SunGlowMask) * SunGlowInt * mainLight.color.rgb * (1 - DarkStarMap.a);




                half3 SkyColorMix = lerp(var_SkyColor.rgb * (1 - MaskBlend) + SunMoonColor, DirLightColor, smoothstep(0, 0.3, Alpha)) + SunGlowColor;

                half3 FinalColor = SkyColorMix;


                half fogfactor = saturate(input.uv2.y + _FogGlobalDensity * 2);
                fogfactor = smoothstep(0, 0.1, fogfactor);
                fogfactor = pow(smoothstep(0, 0.1, fogfactor), 1 + _FogGlobalDensity);
                fogfactor = pow(fogfactor, 1 + _FogGlobalDensity);
                fogfactor = saturate(fogfactor);
                // return fogfactor;

                // return LightColorMask;

                // #if _FOG_ON
                //     FinalColor = ApplyFogSkyBox(FinalColor, input.positionWS, mainLight, fogfactor, LightColorMask);
                // #endif

                return half4(FinalColor, 1);
            }

            ENDHLSL

        }
    }
    FallBack "Diffuse"
}