using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class HMKTerrainShaderGUI : ShaderGUI
{
    private Material m_Material;
    private MaterialEditor m_MaterialEditor;

    //======
    // private MaterialProperty normalMap;
    private MaterialProperty m_MPControl0, m_MPControl1;//权重图
    private MaterialProperty m_MPSplat0, m_MPSplat1, m_MPSplat2, m_MPSplat3, m_MPSplat4, m_MPSplat5, m_MPSplat6, m_MPSplat7;
    private MaterialProperty nra0 { get; set; }
    private MaterialProperty nra1 { get; set; }
    private MaterialProperty nra2 { get; set; }
    private MaterialProperty nra3 { get; set; }
    private MaterialProperty nra4 { get; set; }
    private MaterialProperty nra5 { get; set; }
    private MaterialProperty nra6 { get; set; }
    private MaterialProperty nra7 { get; set; }

    private MaterialProperty roughnessScaleProp { get; set; }
    private MaterialProperty OcclusionScaleProp { get; set; }

    private MaterialProperty m_MPUVScale;


    private MaterialProperty enableHeightBlend { get; set; }
    private MaterialProperty heightBias { get; set; }

    private MaterialProperty enableCliffRenderProp { get; set; }
    private MaterialProperty cliffBlendProp { get; set; }


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
        // normalMap = FindProperty("_NormalMap", props);
        m_MPControl0 = FindProperty("_Control0", props);
        m_MPControl1 = FindProperty("_Control1", props);
        m_MPSplat0 = FindProperty("_Splat0", props);
        m_MPSplat1 = FindProperty("_Splat1", props);
        m_MPSplat2 = FindProperty("_Splat2", props);
        m_MPSplat3 = FindProperty("_Splat3", props);
        m_MPSplat4 = FindProperty("_Splat4", props);
        m_MPSplat5 = FindProperty("_Splat5", props);
        m_MPSplat6 = FindProperty("_Splat6", props);
        m_MPSplat7 = FindProperty("_Splat7", props);
        nra0 = FindProperty("_NRA0", props);
        nra1 = FindProperty("_NRA1", props);
        nra2 = FindProperty("_NRA2", props);
        nra3 = FindProperty("_NRA3", props);
        nra4 = FindProperty("_NRA4", props);
        nra5 = FindProperty("_NRA5", props);
        nra6 = FindProperty("_NRA6", props);
        nra7 = FindProperty("_NRA7", props);

        roughnessScaleProp = FindProperty("_RoughnessScale", props);
        OcclusionScaleProp = FindProperty("_OcclusionScale", props);
        m_MPUVScale = FindProperty("_UVScale", props);

        enableHeightBlend = FindProperty("_EnableHeightBlend", props);
        heightBias = FindProperty("_HeightBias", props);


        enableCliffRenderProp = FindProperty("_EnableCliffRender", props);
        cliffBlendProp = FindProperty("_CliffBlend", props);

    }

    private void BasicGUI()
    {
        // m_MaterialEditor.TexturePropertySingleLine(Styles.normalMap, normalMap);
        EditorGUILayout.Space(10);

        m_MaterialEditor.TexturePropertySingleLine(Styles.controlMap0, m_MPControl0);

        EditorGUI.indentLevel++;
        DrawSplat("Control 0:Albedp", m_MPSplat0, m_MPSplat1, m_MPSplat2, m_MPSplat3);
        DrawSplat("Control 0:NRA", nra0, nra1, nra2, nra3);
        EditorGUI.indentLevel--;

        EditorGUILayout.Space(10);
        m_MaterialEditor.TexturePropertySingleLine(Styles.controlMap1, m_MPControl1);

        EditorGUI.indentLevel++;
        DrawSplat("Control 1:Albedp", m_MPSplat4, m_MPSplat5, m_MPSplat6, m_MPSplat7);
        DrawSplat("Control 1:NRA", nra4, nra5, nra6, nra7);
        EditorGUI.indentLevel--;


        m_MaterialEditor.RangeProperty(roughnessScaleProp, "Roughness Scale");
        m_MaterialEditor.RangeProperty(OcclusionScaleProp, "Occlusion Scale");

        EditorGUILayout.Space(10);
        m_MaterialEditor.RangeProperty(m_MPUVScale, "UV Scale");

        EditorGUILayout.Space(10);
        EditorGUILayout.LabelField("Keywords", EditorStyles.boldLabel);
        DrawHeightBlend();
        DrawCliffRender();
    }

    private void DrawSplat(string title, MaterialProperty albedo0, MaterialProperty albedo1, MaterialProperty albedo2, MaterialProperty albedo3)
    {
        EditorGUILayout.LabelField(title, EditorStyles.boldLabel);

        EditorGUILayout.BeginHorizontal();
        var rect = EditorGUILayout.GetControlRect();

        float singleWidth = rect.width / 4;
        var rect1 = new Rect(rect.x, rect.y, singleWidth, rect.height);
        var rect2 = new Rect(rect.x + singleWidth, rect.y, singleWidth, rect.height);
        var rect3 = new Rect(rect.x + singleWidth * 2, rect.y, singleWidth, rect.height);
        var rect4 = new Rect(rect.x + singleWidth * 3, rect.y, singleWidth, rect.height);
        m_MaterialEditor.TexturePropertyMiniThumbnail(rect1, albedo0, "R", "R");
        m_MaterialEditor.TexturePropertyMiniThumbnail(rect2, albedo1, "G", "R");
        m_MaterialEditor.TexturePropertyMiniThumbnail(rect3, albedo2, "B", "R");
        m_MaterialEditor.TexturePropertyMiniThumbnail(rect4, albedo3, "A", "R");




        EditorGUILayout.EndHorizontal();
    }

    private void DrawHeightBlend()
    {
        EditorGUI.BeginChangeCheck();
        var enableHeightBlend = EditorGUILayout.Toggle(Styles.enableHeightBlend, this.enableHeightBlend.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            this.enableHeightBlend.floatValue = enableHeightBlend ? 1 : 0;
        }

        if (this.enableHeightBlend.floatValue == 1)
        {
            m_Material.EnableKeyword("_TERRAIN_BLEND_HEIGHT");
            EditorGUI.indentLevel++;
            m_MaterialEditor.RangeProperty(heightBias, "Height bias");
            EditorGUI.indentLevel--;
        }
        else
        {
            m_Material.DisableKeyword("_TERRAIN_BLEND_HEIGHT");
        }
    }

    private void DrawCliffRender()
    {
        EditorGUI.BeginChangeCheck();
        var enableCliffRender = EditorGUILayout.Toggle(Styles.enableCliffRender, enableCliffRenderProp.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
        {
            enableCliffRenderProp.floatValue = enableCliffRender ? 1 : 0;
        }

        if (enableCliffRenderProp.floatValue == 1)
        {
            m_Material.EnableKeyword("EnableCliffRender");
            EditorGUI.indentLevel++;
            m_MaterialEditor.RangeProperty(cliffBlendProp, "Cliff Blend");
            EditorGUI.indentLevel--;
        }
        else
        {
            m_Material.DisableKeyword("EnableCliffRender");
        }

    }


    static class Styles
    {
        public static GUIContent normalMap = new GUIContent("Normal Map");
        public static GUIContent controlMap0 = new GUIContent("Control Map0");
        public static GUIContent controlMap1 = new GUIContent("Control Map1");
        public static GUIContent enableHeightBlend = new GUIContent("Enable Height Blend");
        public static GUIContent enableCliffRender = new GUIContent("Enable Cliff Render");
    }
}
