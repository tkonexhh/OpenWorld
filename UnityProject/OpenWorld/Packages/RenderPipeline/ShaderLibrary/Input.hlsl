#ifndef RENDERPIPELINE_INPUT_INCLUDED
#define RENDERPIPELINE_INPUT_INCLUDED

#define MAX_VISIBLE_LIGHTS 16


#define UNITY_MATRIX_M     unity_ObjectToWorld
#define UNITY_MATRIX_I_M   unity_WorldToObject
#define UNITY_MATRIX_V     unity_MatrixV
#define UNITY_MATRIX_I_V   unity_MatrixInvV
#define UNITY_MATRIX_P     OptimizeProjectionMatrix(glstate_matrix_projection)
#define UNITY_MATRIX_I_P   unity_MatrixInvP
#define UNITY_MATRIX_VP    unity_MatrixVP
#define UNITY_MATRIX_I_VP  unity_MatrixInvVP
#define UNITY_MATRIX_MV    mul(UNITY_MATRIX_V, UNITY_MATRIX_M)
#define UNITY_MATRIX_T_MV  transpose(UNITY_MATRIX_MV)
#define UNITY_MATRIX_IT_MV transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V))
#define UNITY_MATRIX_MVP   mul(UNITY_MATRIX_VP, UNITY_MATRIX_M)
#define UNITY_PREV_MATRIX_M   unity_MatrixPreviousM
#define UNITY_PREV_MATRIX_I_M unity_MatrixPreviousM

//MainLight
float4 _MainLightPosition;
half4 _MainLightColor;
half4 _MainLightOcclusionProbes;
uint _MainLightLayerMask;
//Additional Light
half4 _AdditionalLightsCount;

float4 _AdditionalLightsPosition[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsColor[MAX_VISIBLE_LIGHTS];


#include "Packages/RenderPipeline/ShaderLibrary/UnityInput.hlsl"

#endif