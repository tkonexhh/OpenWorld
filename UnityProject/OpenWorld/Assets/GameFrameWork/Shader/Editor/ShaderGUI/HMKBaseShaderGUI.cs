using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEditor.Rendering.Universal;
using UnityEditor.Rendering.Universal.ShaderGUI;
using UnityEngine.Rendering;

public abstract class HMKBaseShaderGUI : ShaderGUI
{
    public enum RenderFace
    {
        Front = 2,
        Back = 1,
        Both = 0
    }

    public enum SurfaceType
    {
        Opaque,
        Transparent
    }

    public enum BlendMode
    {
        Alpha,   // Old school alpha-blending mode, fresnel does not affect amount of transparency
        Premultiply, // Physically plausible transparency mode, implemented as alpha pre-multiply
        Additive,
        Multiply
    }

    protected Material m_Material;
    protected MaterialEditor m_MaterialEditor;

    protected MaterialProperty cullingProp { get; set; }
    private MaterialProperty alphaClipProp { get; set; }
    private MaterialProperty alphaCutoffProp { get; set; }
    protected MaterialProperty surfaceTypeProp { get; set; }
    protected MaterialProperty blendModeProp { get; set; }
    private MaterialProperty receiveShadowsProp { get; set; }
    private MaterialProperty queueOffsetProp { get; set; }
    private const int queueOffsetRange = 100;

    private bool m_OptionFoldout;

    private bool m_HasChaged = false;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // base.OnGUI(materialEditor, properties);
        m_MaterialEditor = materialEditor;
        m_Material = materialEditor.target as Material;
        // EditorGUILayout.LabelField("Material Properties", EditorStyles.boldLabel);
        UpdateMaterialProperty(properties);

        OptionGUI();
        InputGUI();

    }

    protected virtual void UpdateMaterialProperty(MaterialProperty[] props)
    {
        cullingProp = FindProperty("_Cull", props);
        alphaClipProp = FindProperty("_AlphaClip", props);
        alphaCutoffProp = FindProperty("_Cutoff", props);
        surfaceTypeProp = FindProperty("_Surface", props);
        blendModeProp = FindProperty("_Blend", props);
        receiveShadowsProp = FindProperty(ShaderProperty._ReceiveShadows, props, false);
        queueOffsetProp = FindProperty("_QueueOffset", props, false);
    }

    private void OptionGUI()
    {
        m_OptionFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_OptionFoldout, "Option Setting");
        if (m_OptionFoldout)
        {
            //===Cull
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = cullingProp.hasMixedValue;
            var culling = (RenderFace)cullingProp.floatValue;
            culling = (RenderFace)EditorGUILayout.EnumPopup(Styles.cullingText, culling);
            if (EditorGUI.EndChangeCheck())
            {
                m_MaterialEditor.RegisterPropertyChangeUndo(Styles.cullingText.text);
                cullingProp.floatValue = (float)culling;
                m_Material.doubleSidedGI = (RenderFace)cullingProp.floatValue != RenderFace.Front;
                m_HasChaged = true;
            }
            EditorGUI.showMixedValue = false;


            DoPopup(Styles.surfaceType, surfaceTypeProp, Enum.GetNames(typeof(SurfaceType)));
            // if ((SurfaceType)m_Material.GetFloat("_Surface") == SurfaceType.Transparent){ }
            // DoPopup(Styles.blendingMode, blendModeProp, Enum.GetNames(typeof(BlendMode)));


            //Alpha Cutout
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = alphaClipProp.hasMixedValue;
            var alphaClipEnabled = EditorGUILayout.Toggle(Styles.alphaClipText, alphaClipProp.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                m_HasChaged = true;
                alphaClipProp.floatValue = alphaClipEnabled ? 1 : 0;
            }
            EditorGUI.showMixedValue = false;

            if (alphaClipProp.floatValue == 1)
                m_MaterialEditor.ShaderProperty(alphaCutoffProp, Styles.alphaClipThresholdText, 1);

            if (receiveShadowsProp != null)
            {
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = receiveShadowsProp.hasMixedValue;
                var receiveShadows = EditorGUILayout.Toggle(Styles.receiveShadowText, receiveShadowsProp.floatValue == 1.0f);
                if (EditorGUI.EndChangeCheck())
                {
                    m_HasChaged = true;
                    receiveShadowsProp.floatValue = receiveShadows ? 1.0f : 0.0f;
                }
                EditorGUI.showMixedValue = false;
            }

            if (m_HasChaged)
            {
                SetupKeywords();
                m_HasChaged = false;
            }

            OnOptionGUI();
        }


        EditorGUILayout.EndFoldoutHeaderGroup();

        GUILayout.Space(10);
    }

    private void SetupKeywords()
    {
        bool alphaClip = false;
        if (m_Material.HasProperty("_AlphaClip"))
            alphaClip = m_Material.GetFloat("_AlphaClip") >= 0.5;


        if (alphaClip)
        {
            m_Material.EnableKeyword("_ALPHATEST_ON");
        }
        else
        {
            m_Material.DisableKeyword("_ALPHATEST_ON");
        }

        //Blend
        if (m_Material.HasProperty("_Surface"))
        {
            SurfaceType surfaceType = (SurfaceType)m_Material.GetFloat("_Surface");
            if (surfaceType == SurfaceType.Opaque)
            {
                m_Material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                m_Material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                m_Material.SetInt("_ZWrite", 1);
                if (alphaClip)
                {
                    m_Material.renderQueue = (int)RenderQueue.AlphaTest;
                    m_Material.SetOverrideTag("RenderType", "TransparentCutout");
                }
                else
                {
                    m_Material.renderQueue = (int)RenderQueue.Geometry;
                    m_Material.SetOverrideTag("RenderType", "Opaque");
                }

                m_Material.renderQueue += m_Material.HasProperty("_QueueOffset") ? (int)m_Material.GetFloat("_QueueOffset") : 0;
            }
            else
            {
                m_Material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                m_Material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                m_Material.SetInt("_ZWrite", 0);
                m_Material.renderQueue = (int)RenderQueue.Transparent;
                m_Material.renderQueue += m_Material.HasProperty("_QueueOffset") ? (int)m_Material.GetFloat("_QueueOffset") : 0;
            }

        }

        // Receive Shadows
        if (m_Material.HasProperty(ShaderProperty._ReceiveShadows))
        {
            CoreUtils.SetKeyword(m_Material, ShaderKeywords._RECEIVE_SHADOWS_OFF, m_Material.GetFloat(ShaderProperty._ReceiveShadows) == 0.0f);
        }

    }

    protected void DrawQueueOffsetField()
    {
        if (queueOffsetProp != null)
        {
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = queueOffsetProp.hasMixedValue;
            var queue = EditorGUILayout.IntSlider(Styles.queueSlider, (int)queueOffsetProp.floatValue, -queueOffsetRange, queueOffsetRange);
            if (EditorGUI.EndChangeCheck())
            {
                queueOffsetProp.floatValue = queue;
                SetupKeywords();
            }
            queueOffsetProp.floatValue = queue;
            EditorGUI.showMixedValue = false;
        }
    }

    private void InputGUI()
    {

    }



    protected abstract void OnOptionGUI();


    public void DoPopup(GUIContent label, MaterialProperty property, string[] options)
    {
        DoPopup(label, property, options, m_MaterialEditor);
    }

    public static void DoPopup(GUIContent label, MaterialProperty property, string[] options, MaterialEditor materialEditor)
    {
        if (property == null)
            throw new ArgumentNullException("property");

        EditorGUI.showMixedValue = property.hasMixedValue;

        var mode = property.floatValue;
        EditorGUI.BeginChangeCheck();
        mode = EditorGUILayout.Popup(label, (int)mode, options);
        if (EditorGUI.EndChangeCheck())
        {
            materialEditor.RegisterPropertyChangeUndo(label.text);
            property.floatValue = mode;
        }

        EditorGUI.showMixedValue = false;
    }

    protected static void DrawTileOffset(MaterialEditor materialEditor, MaterialProperty textureProp)
    {
        materialEditor.TextureScaleOffsetProperty(textureProp);
    }



    protected static class Styles
    {
        public static readonly GUIContent baseMap = new GUIContent("Base Color");
        public static readonly GUIContent normalMap = new GUIContent("Normal Map", "法线贴图:切线空间");

        public static readonly GUIContent cullingText = new GUIContent("Render Face",
                "Specifies which faces to cull from your geometry. Front culls front faces. Back culls backfaces. None means that both sides are rendered.");
        public static readonly GUIContent surfaceType = new GUIContent("Surface Type",
                "Select a surface type for your texture. Choose between Opaque or Transparent.");
        public static readonly GUIContent blendingMode = new GUIContent("Blending Mode",
                "Controls how the color of the Transparent surface blends with the Material color in the background.");
        public static readonly GUIContent alphaClipText = new GUIContent("Alpha Clipping",
                "Makes your Material act like a Cutout shader. Use this to create a transparent effect with hard edges between opaque and transparent areas.");

        public static readonly GUIContent alphaClipThresholdText = new GUIContent("Threshold",
                "Sets where the Alpha Clipping starts. The higher the value is, the brighter the  effect is when clipping starts.");
        public static readonly GUIContent receiveShadowText = new GUIContent("Receive Shadows",
                "When enabled, other GameObjects can cast shadows onto this GameObject.");

        public static readonly GUIContent queueSlider = new GUIContent("Priority",
                "Determines the chronological rendering order for a Material. High values are rendered first.");
    }


    protected static class ShaderKeywords
    {
        public static readonly string _RECEIVE_SHADOWS_OFF = "_RECEIVE_SHADOWS_OFF";
    }

    protected static class ShaderProperty
    {
        public static readonly string _ReceiveShadows = "_ReceiveShadows";
    }
}
