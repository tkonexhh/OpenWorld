using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class LitNoMetallicShaderGUI : HMKBaseShaderGUI
{
    private MaterialProperty baseColorProp { get; set; }//基础颜色
    private MaterialProperty baseMapProp { get; set; }//基础贴图
    private MaterialProperty nraMapProp { get; set; }//NRA贴图
    private MaterialProperty bumpScaleProp { get; set; }
    private MaterialProperty roughnessScaleProp { get; set; }
    private MaterialProperty occlusionScaleProp { get; set; }



    private bool m_BasicFoldout = true;


    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        BasicGUI();
    }

    protected override void UpdateMaterialProperty(MaterialProperty[] props)
    {
        base.UpdateMaterialProperty(props);
        baseColorProp = FindProperty("_BaseColor", props);
        baseMapProp = FindProperty("_BaseMap", props);
        nraMapProp = FindProperty("_NormalPBRMap", props);
        bumpScaleProp = FindProperty("_BumpScale", props);
        roughnessScaleProp = FindProperty("_RoughnessScale", props);
        occlusionScaleProp = FindProperty("_OcclusionScale", props);
    }

    protected override void OnOptionGUI()
    {

    }

    protected void BasicGUI()
    {
        m_MaterialEditor.TexturePropertyWithHDRColor(Styles.baseMap, baseMapProp, baseColorProp, false);
        m_MaterialEditor.TexturePropertySingleLine(TStyles.nraMap, nraMapProp);


        m_BasicFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_BasicFoldout, "PBR Setting");
        if (m_BasicFoldout)
        {
            if (GUILayout.Button("Reset"))
            {
                roughnessScaleProp.floatValue = occlusionScaleProp.floatValue = 1.0f;
                bumpScaleProp.floatValue = 1.0f;
            }
            EditorGUI.indentLevel++;
            m_MaterialEditor.RangeProperty(bumpScaleProp, "Bump Scale");
            m_MaterialEditor.RangeProperty(roughnessScaleProp, "Roughness Scale");
            m_MaterialEditor.RangeProperty(occlusionScaleProp, "Occlusion Scale");
            EditorGUI.indentLevel--;

        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }



    static class TStyles
    {
        public static readonly GUIContent nraMap = new GUIContent("NRA Map", "RG:法线XY B:粗糙度 A:AO");
    }
}
