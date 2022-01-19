using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class HMKTerrainShaderGUI : ShaderGUI
{
    private Material m_Material;
    private MaterialEditor m_MaterialEditor;

    //======
    private MaterialProperty m_MPControl;//权重图
    private MaterialProperty m_MPSplat0, m_MPSplat1, m_MPSplat2, m_MPSplat3;
    private MaterialProperty NRAMap0Prop { get; set; }
    private MaterialProperty NRAMap1Prop { get; set; }
    private MaterialProperty NRAMap2Prop { get; set; }
    private MaterialProperty NRAMap3Prop { get; set; }
    private MaterialProperty roughnessScaleProp { get; set; }
    private MaterialProperty occlusionScaleProp { get; set; }
    private MaterialProperty m_MPWeight;
    private MaterialProperty m_MPUVScale;

    private MaterialProperty m_MPEnableHeightBlend;
    private MaterialProperty m_MPEnableAntiTilling;
    private MaterialProperty m_MPFadeDistance;




    private bool m_SplatSettingFoldout = true;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // base.OnGUI(materialEditor, properties);
        m_MaterialEditor = materialEditor;
        m_Material = materialEditor.target as Material;

        UpdateMaterialProperty(properties);

        EditorGUILayout.LabelField("Material Properties", EditorStyles.boldLabel);
        BasicGUI();
    }

    private void UpdateMaterialProperty(MaterialProperty[] props)
    {
        m_MPControl = FindProperty("_Control", props);
        m_MPSplat0 = FindProperty("_Splat0", props);
        m_MPSplat1 = FindProperty("_Splat1", props);
        m_MPSplat2 = FindProperty("_Splat2", props);
        m_MPSplat3 = FindProperty("_Splat3", props);
        NRAMap0Prop = FindProperty("_NormalPBRMap0", props);
        NRAMap1Prop = FindProperty("_NormalPBRMap1", props);
        NRAMap2Prop = FindProperty("_NormalPBRMap2", props);
        NRAMap3Prop = FindProperty("_NormalPBRMap3", props);
        roughnessScaleProp = FindProperty("_RoughnessScale", props);
        occlusionScaleProp = FindProperty("_OcclusionScale", props);
        m_MPWeight = FindProperty("_Weight", props);
        m_MPUVScale = FindProperty("_UVScale", props);
        m_MPEnableHeightBlend = FindProperty("_EnalbeHeightBlend", props);

        m_MPEnableAntiTilling = FindProperty("_EnableAntiTilling", props);
        m_MPFadeDistance = FindProperty("_FadeDistance", props);

    }

    private void BasicGUI()
    {
        m_MaterialEditor.TexturePropertySingleLine(Styles.controlMap, m_MPControl);

        m_SplatSettingFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_SplatSettingFoldout, "Splat Setting");
        if (m_SplatSettingFoldout)
        {
            EditorGUI.indentLevel++;
            DrawSplat("Splat R:", m_MPSplat0, NRAMap0Prop);
            DrawSplat("Splat G:", m_MPSplat1, NRAMap1Prop);
            DrawSplat("Splat B:", m_MPSplat2, NRAMap2Prop);
            DrawSplat("Splat A:", m_MPSplat3, NRAMap3Prop);
            EditorGUI.indentLevel--;
            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        m_MaterialEditor.RangeProperty(roughnessScaleProp, "Roughness Scale");
        m_MaterialEditor.RangeProperty(occlusionScaleProp, "Occlusion Scale");

        EditorGUILayout.Space(10);
        m_MaterialEditor.RangeProperty(m_MPWeight, "Blend Weight");
        m_MaterialEditor.RangeProperty(m_MPUVScale, "Uv Scale");

        EditorGUILayout.Space(10);
        EditorGUILayout.LabelField("Keywords", EditorStyles.boldLabel);
        DrawEnableHeightBlend();
        DrawAntiTilling();
    }

    private void DrawSplat(string title, MaterialProperty albedo, MaterialProperty nra)
    {
        EditorGUILayout.LabelField(title, EditorStyles.boldLabel);

        EditorGUILayout.BeginHorizontal();
        var rect = EditorGUILayout.GetControlRect();

        float singleWidth = rect.width / 3;
        var rect1 = new Rect(rect.x, rect.y, singleWidth, rect.height);
        var rect2 = new Rect(rect.x + singleWidth, rect.y, singleWidth, rect.height);
        // var rect3 = new Rect(rect.x + singleWidth * 2, rect.y, singleWidth, rect.height);
        m_MaterialEditor.TexturePropertyMiniThumbnail(rect1, albedo, "Albedo", "R");
        m_MaterialEditor.TexturePropertyMiniThumbnail(rect2, nra, "NRA", "R");
        // m_MaterialEditor.TexturePropertyMiniThumbnail(rect3, pbrMap, "PBR", "R:金属度 G:粗糙度 B:AO");

        EditorGUILayout.EndHorizontal();
    }

    private void DrawEnableHeightBlend()
    {
        EditorGUI.BeginChangeCheck();
        var enableHeightBlend = EditorGUILayout.Toggle(Styles.enableHeightBlend, m_MPEnableHeightBlend.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            m_MPEnableHeightBlend.floatValue = enableHeightBlend ? 1 : 0;
        }

        if (m_MPEnableHeightBlend.floatValue == 1)
        {
            m_Material.EnableKeyword("EnableHeightBlend");
        }
        else
        {
            m_Material.DisableKeyword("EnableHeightBlend");
        }
    }

    private void DrawAntiTilling()
    {
        EditorGUI.BeginChangeCheck();
        var enableAntiTilling = EditorGUILayout.Toggle(Styles.enableAntiTilling, m_MPEnableAntiTilling.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            m_MPEnableAntiTilling.floatValue = enableAntiTilling ? 1 : 0;
        }

        if (m_MPEnableAntiTilling.floatValue == 1)
        {
            m_Material.EnableKeyword("EnableAntiTilling");
            EditorGUI.indentLevel++;
            m_MaterialEditor.VectorProperty(m_MPFadeDistance, "Fade Distance");
            EditorGUI.indentLevel--;
        }
        else
        {
            m_Material.DisableKeyword("EnableAntiTilling");
        }

    }


    static class Styles
    {
        public static GUIContent controlMap = new GUIContent("Control Map");
        public static GUIContent enableHeightBlend = new GUIContent("Enable Height Blend");
        public static GUIContent enableAntiTilling = new GUIContent("Enable Anti-Tilling");
        public static GUIContent enableCloudShadow = new GUIContent("Enable CloudShadow");
    }
}
