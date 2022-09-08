using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEditor.Rendering.Universal;
using UnityEditor.Rendering.Universal.ShaderGUI;

internal class HMKLitShaderGUI : HMKBaseShaderGUI
{
    //======
    private MaterialProperty baseColorProp { get; set; }//基础颜色
    private MaterialProperty baseMapProp { get; set; }//基础贴图
    private MaterialProperty normalMapProp { get; set; }
    private MaterialProperty pbrMap { get; set; }
    private MaterialProperty bumpScaleProp { get; set; }
    private MaterialProperty metallicScaleProp { get; set; }
    private MaterialProperty roughnessScaleProp { get; set; }
    private MaterialProperty occlusionScaleProp { get; set; }
    private MaterialProperty emissionScaleProp { get; set; }
    private MaterialProperty emissionColorProp { get; set; }
    private MaterialProperty emissionBreathOnProp { get; set; }
    private MaterialProperty breathSpeedProp { get; set; }


    // private MaterialProperty m_MPUseGIMap;
    //------

    private bool m_BasicFoldout = true;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        BasicGUI();
        GUILayout.Space(10);
        DrawQueueOffsetField();

        EnableBakeEmission();
    }

    protected override void UpdateMaterialProperty(MaterialProperty[] props)
    {
        base.UpdateMaterialProperty(props);
        baseMapProp = FindProperty("_BaseMap", props);
        baseColorProp = FindProperty("_BaseColor", props, false);
        normalMapProp = FindProperty("_NormalMap", props);
        pbrMap = FindProperty("_PBRMap", props);
        bumpScaleProp = FindProperty("_BumpScale", props);
        metallicScaleProp = FindProperty("_MetallicScale", props);
        roughnessScaleProp = FindProperty("_RoughnessScale", props);
        occlusionScaleProp = FindProperty("_OcclusionScale", props);

        emissionScaleProp = FindProperty("_EmissionScale", props);
        emissionColorProp = FindProperty("_EmissionColor", props);
        emissionBreathOnProp = FindProperty("_Emission_Breath_On", props);
        breathSpeedProp = FindProperty("_BreathSpeed", props);

        // m_MPUseGIMap = FindProperty("_GIMap", props);
    }

    protected override void OnOptionGUI()
    {
        EditorGUI.BeginChangeCheck();
        // EditorGUI.showMixedValue = m_MPUseGIMap.hasMixedValue;
        // var enabled = EditorGUILayout.Toggle(TStyles.useGIMap, m_MPUseGIMap.floatValue == 1);
        // if (EditorGUI.EndChangeCheck())
        // {
        //     m_MPUseGIMap.floatValue = enabled ? 1 : 0;
        //     if (m_MPUseGIMap.floatValue == 1)
        //     {
        //         m_Material.EnableKeyword("_GIMAP_ON");
        //     }
        //     else
        //     {
        //         m_Material.DisableKeyword("_GIMAP_ON");
        //     }
        // }
        // EditorGUI.showMixedValue = false;


    }

    private void BasicGUI()
    {
        if (pbrMap.textureValue != null) m_Material.EnableKeyword(TShaderKeywords._PBRMAP_ON);

        m_MaterialEditor.TexturePropertyWithHDRColor(Styles.baseMap, baseMapProp, baseColorProp, false);
        m_MaterialEditor.TexturePropertySingleLine(Styles.normalMap, normalMapProp);

        EditorGUI.BeginChangeCheck();
        m_MaterialEditor.TexturePropertySingleLine(TStyles.pbrMap, pbrMap);
        if (EditorGUI.EndChangeCheck())
        {
            if (pbrMap.textureValue != null)
            {
                m_Material.EnableKeyword(TShaderKeywords._PBRMAP_ON);
            }
            else
            {
                m_Material.DisableKeyword(TShaderKeywords._PBRMAP_ON);
            }
        }

        DrawTileOffset(m_MaterialEditor, baseMapProp);

        m_BasicFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_BasicFoldout, "PBR Setting");
        if (m_BasicFoldout)
        {
            if (GUILayout.Button("Reset"))
            {
                metallicScaleProp.floatValue = roughnessScaleProp.floatValue = occlusionScaleProp.floatValue = 1.0f;
                bumpScaleProp.floatValue = 1.0f;
            }
            EditorGUI.indentLevel++;
            m_MaterialEditor.RangeProperty(bumpScaleProp, "Bump Scale");
            m_MaterialEditor.RangeProperty(metallicScaleProp, "Metallic Scale");
            m_MaterialEditor.RangeProperty(roughnessScaleProp, "Roughness Scale");
            m_MaterialEditor.RangeProperty(occlusionScaleProp, "Occlusion Scale");

            m_MaterialEditor.ColorProperty(emissionColorProp, "Emission Color");
            EditorGUI.BeginChangeCheck();
            var emissionScale = m_MaterialEditor.RangeProperty(emissionScaleProp, "Emission Scale");
            if (EditorGUI.EndChangeCheck())
            {
                if (emissionScale > 0)
                {
                    EnableBakeEmission();
                }
                else
                {
                    DisableBakeEmission();
                }
            }

            DrawEmissionBreath();


            EditorGUI.indentLevel--;

        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    private void DrawEmissionBreath()
    {
        // m_MaterialEditor.ShaderProperty(emissionBreathOnProp, "Emission Breath");

        EditorGUI.BeginChangeCheck();
        EditorGUI.showMixedValue = emissionBreathOnProp.hasMixedValue;
        var enabled = EditorGUILayout.Toggle(TStyles.emissionBreath, emissionBreathOnProp.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            emissionBreathOnProp.floatValue = enabled ? 1 : 0;
            if (emissionBreathOnProp.floatValue == 1)
            {
                DisableBakeEmission();
                m_Material.EnableKeyword(TShaderKeywords.EMISSION_BREATH_ON);
            }
            else
            {
                EnableBakeEmission();
                m_Material.DisableKeyword(TShaderKeywords.EMISSION_BREATH_ON);
            }
        }

        EditorGUI.showMixedValue = false;

        if (emissionBreathOnProp.floatValue == 1)
        {
            m_MaterialEditor.FloatProperty(breathSpeedProp, "Breath Speed");
        }
    }

    void EnableBakeEmission()
    {
        if (emissionScaleProp.floatValue > 0 && emissionBreathOnProp.floatValue == 0)
            m_Material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.BakedEmissive;
    }

    void DisableBakeEmission()
    {
        m_Material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.None;
    }



    static class TStyles
    {
        public static readonly GUIContent pbrMap = new GUIContent("MRAE Map", "R:金属度 G:粗糙度 B:AO A:Emission");
        public static readonly GUIContent emissionBreath = new GUIContent("Emission Breath", "是否开启自发光呼吸");
    }

    static class TShaderKeywords
    {
        public static readonly string _PBRMAP_ON = "_PBRMAP_ON";
        public static readonly string EMISSION_BREATH_ON = "_EMISSION_BREATH_ON";
    }

}
