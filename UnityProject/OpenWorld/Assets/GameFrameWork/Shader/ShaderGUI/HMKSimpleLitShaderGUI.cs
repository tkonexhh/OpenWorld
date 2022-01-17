using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEditor.Rendering.Universal;
using UnityEditor.Rendering.Universal.ShaderGUI;

internal class HMKSimpleLitShaderGUI : HMKBaseShaderGUI
{

    //======
    private MaterialProperty m_MPBaseColor;//基础颜色
    private MaterialProperty m_MPBaseMap;//基础贴图
    private MaterialProperty m_MPNormalMap;
    //------



    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        BasicGUI();
    }


    protected override void UpdateMaterialProperty(MaterialProperty[] props)
    {
        base.UpdateMaterialProperty(props);
        m_MPBaseMap = FindProperty("_BaseMap", props);
        m_MPBaseColor = FindProperty("_BaseColor", props, false);
        m_MPNormalMap = FindProperty("_NormalMap", props);

        //--

    }

    protected override void OnOptionGUI()
    {
    }

    private void BasicGUI()
    {
        m_MaterialEditor.TexturePropertyWithHDRColor(Styles.baseMap, m_MPBaseMap, m_MPBaseColor, false);
        m_MaterialEditor.TexturePropertySingleLine(Styles.normalMap, m_MPNormalMap);
    }




}
