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

    //------

    private bool m_BasicFoldout = true;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        BasicGUI();
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
    }

    protected override void OnOptionGUI()
    {

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
            EditorGUI.indentLevel--;

        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }


    static class TStyles
    {
        public static readonly GUIContent pbrMap = new GUIContent("PBR Map", "R:金属度 G:粗糙度 B:AO");
    }

    static class TShaderKeywords
    {
        public static readonly string _PBRMAP_ON = "_PBRMAP_ON";
    }

}
