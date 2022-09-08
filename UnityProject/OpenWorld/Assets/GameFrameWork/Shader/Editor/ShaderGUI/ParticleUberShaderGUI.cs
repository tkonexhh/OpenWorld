using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

public class ParticleUberShaderGUI : ShaderGUI
{


    public enum RenderFace
    {
        Front = 2,
        Back = 1,
        Both = 0
    }

    public enum ToggleOnOff
    {
        Off,
        On
    }

    public enum BlendMode
    {
        Alpha,   // Old school alpha-blending mode, fresnel does not affect amount of transparency
        Premultiply, // Physically plausible transparency mode, implemented as alpha pre-multiply
        Additive,
        Multiply
    }

    public enum ShaderMode
    {
        Normal,
        UI,
    }

    public enum DissolveMode
    {
        // Soft,
        // Hard
    }


    private Material m_Material;
    private MaterialEditor m_MaterialEditor;

    #region MaterialProperty
    //主纹理
    protected MaterialProperty MainTex { get; private set; }
    protected MaterialProperty MainColor { get; private set; }

    //Panner
    protected MaterialProperty PannerOn { get; private set; }
    protected MaterialProperty MainTex_PannerSpeedU { get; private set; }
    protected MaterialProperty MainTex_PannerSpeedV { get; private set; }
    protected MaterialProperty NoiseTex_PannerSpeedU { get; private set; }
    protected MaterialProperty NoiseTex_PannerSpeedV { get; private set; }

    //Mask
    protected MaterialProperty MaskOn { get; private set; }
    protected MaterialProperty MaskTex { get; private set; }

    //noise
    protected MaterialProperty NoiseOn { get; private set; }
    protected MaterialProperty NoiseTex { get; private set; }
    protected MaterialProperty NoiseIntensity { get; private set; }

    //Dissolve
    protected MaterialProperty DissolveOn { get; private set; }
    // protected MaterialProperty ReverseDissolve { get; private set; }
    protected MaterialProperty DissolveTex { get; private set; }
    protected MaterialProperty DissolveFactor { get; private set; }
    protected MaterialProperty HardnessFactor { get; private set; }
    protected MaterialProperty DissolveWidth { get; private set; }
    protected MaterialProperty DissolveWidthColor { get; private set; }


    //Fresnel
    protected MaterialProperty FresnelOn { get; private set; }
    protected MaterialProperty FresnelColor { get; private set; }
    protected MaterialProperty FresnelWidth { get; private set; }

    //Refract
    // protected MaterialProperty RefractOn { get; private set; }
    // protected MaterialProperty RefractTex { get; private set; }
    // protected MaterialProperty RefractStrength { get; private set; }

    //BlendDepth
    protected MaterialProperty BlendDepthOn { get; private set; }
    protected MaterialProperty BlendDepth { get; private set; }


    //setting
    protected MaterialProperty CullMode { get; private set; }
    protected MaterialProperty FogOn { get; private set; }
    protected MaterialProperty LightOn { get; private set; }
    protected MaterialProperty ZWrite { get; private set; }
    protected MaterialProperty ZTest { get; private set; }
    protected MaterialProperty BlendModeSrc { get; private set; }
    protected MaterialProperty BlendModeDst { get; private set; }
    protected MaterialProperty ClipOn { get; private set; }

    protected MaterialProperty RenderMode { get; private set; }


    //Stencil
    // protected MaterialProperty Stencil { get; private set; }
    // protected MaterialProperty StencilReadMask { get; private set; }
    // protected MaterialProperty StencilWriteMask { get; private set; }
    #endregion

    private MaterialProperty queueOffsetProp { get; set; }
    private const int queueOffsetRange = 100;

    private bool m_SettingFoldout = true;
    private bool m_MainFoldout = true;
    private bool m_PlannerFoldout = true;
    private bool m_MaskFoldout = true;
    private bool m_NoiseFoldout = true;
    private bool m_DissolveFoldout = true;
    private bool m_FresnelFoldout = true;
    private bool m_RefractFoldout = true;
    private bool m_BlendDepthFoldout = true;


    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // base.OnGUI(materialEditor, properties);
        m_MaterialEditor = materialEditor;
        m_Material = materialEditor.target as Material;

        UpdateMaterialProperty(properties);

        EditorGUILayout.LabelField("特效Uber Shader", EditorStyles.boldLabel);

        DrawSetting();
        DrawMain();
        DrawPlanner();
        DrawMask();
        DrawNoise();
        DrawDissolve();
        DrawFresnel();
        // DrawRefract();
        DrawBlendDepth();

        DrawQueueOffsetField();
    }

    private void UpdateMaterialProperty(MaterialProperty[] props)
    {
        //setting
        CullMode = FindProperty("_CullMode", props);
        FogOn = FindProperty("_Fog_On", props);
        LightOn = FindProperty("_Light_On", props);
        ZWrite = FindProperty("_ZWrite", props);
        BlendModeSrc = FindProperty("_BlendModeSrc", props);
        BlendModeDst = FindProperty("_BlendModeDst", props);
        ClipOn = FindProperty("_Clip_On", props);
        //queue
        queueOffsetProp = FindProperty("_QueueOffset", props, false);
        RenderMode = FindProperty("_RenderMode", props, false);
        //Stencil
        // Stencil = FindProperty("_Stencil", props);
        // StencilReadMask = FindProperty("_StencilReadMask", props);
        // StencilWriteMask = FindProperty("_StencilWriteMask", props);

        MainTex = FindProperty("_MainTex", props);
        MainColor = FindProperty("_MainColor", props);

        //Planner
        PannerOn = FindProperty("_Panner_On", props);
        MainTex_PannerSpeedU = FindProperty("_MainTex_PannerSpeedU", props);
        MainTex_PannerSpeedV = FindProperty("_MainTex_PannerSpeedV", props);
        NoiseTex_PannerSpeedU = FindProperty("_NoiseTex_PannerSpeedU", props);
        NoiseTex_PannerSpeedV = FindProperty("_NoiseTex_PannerSpeedV", props);

        //Mask
        MaskOn = FindProperty("_Mask_On", props);
        MaskTex = FindProperty("_MaskTex", props);

        //Noise
        NoiseOn = FindProperty("_Noise_On", props);
        NoiseTex = FindProperty("_NoiseTex", props);
        NoiseIntensity = FindProperty("_NoiseIntensity", props);

        //Dissolve
        DissolveOn = FindProperty("_Dissolve_On", props);
        // ReverseDissolve = FindProperty("_ReverseDissolve", props);
        DissolveTex = FindProperty("_DissolveTex", props);
        DissolveFactor = FindProperty("_DissolveFactor", props);
        HardnessFactor = FindProperty("_HardnessFactor", props);
        DissolveWidth = FindProperty("_DissolveWidth", props);
        DissolveWidthColor = FindProperty("_DissolveWidthColor", props);

        //Fresnel
        FresnelOn = FindProperty("_Fresnel_On", props);
        FresnelColor = FindProperty("_FresnelColor", props);
        FresnelWidth = FindProperty("_FresnelWidth", props);

        //Refract
        // RefractOn = FindProperty("_Refract_On", props);
        // RefractTex = FindProperty("_RefractTex", props);
        // RefractStrength = FindProperty("_RefractStrength", props);

        //BlendDepth
        BlendDepthOn = FindProperty("_BlendDepth_On", props);
        BlendDepth = FindProperty("_BlendDepth", props);
    }


    private void DrawSetting()
    {
        m_SettingFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_SettingFoldout, "设置 (Setting)");
        if (m_SettingFoldout)
        {
            EditorGUI.indentLevel++;

            //ClipOn
            DrawToggle(ClipOn, "ClipOn");
            // EditorGUI.BeginChangeCheck();
            // EditorGUI.showMixedValue = ClipOn.hasMixedValue;
            // var clipON = (ToggleOnOff)ClipOn.floatValue;
            // clipON = (ToggleOnOff)EditorGUILayout.EnumPopup(Styles.ClipOn, clipON);
            // if (EditorGUI.EndChangeCheck())
            // {
            //     m_MaterialEditor.RegisterPropertyChangeUndo(Styles.ClipOn.text);
            //     ClipOn.floatValue = (float)clipON;
            // }
            // EditorGUI.showMixedValue = false;

            //Cull
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = CullMode.hasMixedValue;
            var culling = (RenderFace)CullMode.floatValue;
            culling = (RenderFace)EditorGUILayout.EnumPopup(Styles.CullMode, culling);
            if (EditorGUI.EndChangeCheck())
            {
                m_MaterialEditor.RegisterPropertyChangeUndo(Styles.CullMode.text);
                CullMode.floatValue = (float)culling;
                m_Material.doubleSidedGI = (RenderFace)CullMode.floatValue != RenderFace.Front;
            }
            EditorGUI.showMixedValue = false;


            //ZWrite
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = ZWrite.hasMixedValue;
            var zwrite = (ToggleOnOff)ZWrite.floatValue;
            zwrite = (ToggleOnOff)EditorGUILayout.EnumPopup(Styles.ZWrite, zwrite);
            if (EditorGUI.EndChangeCheck())
            {
                m_MaterialEditor.RegisterPropertyChangeUndo(Styles.ZWrite.text);
                ZWrite.floatValue = (float)zwrite;
            }
            EditorGUI.showMixedValue = false;
            // m_MaterialEditor.ShaderProperty(ZWrite, "ZWrite");
            m_MaterialEditor.ShaderProperty(BlendModeSrc, "BlendModeSrc");
            m_MaterialEditor.ShaderProperty(BlendModeDst, "BlendModeDst");

            //Blend

            //Stencil
            // m_MaterialEditor.ShaderProperty(Stencil, "Stencil");
            // m_MaterialEditor.ShaderProperty(StencilReadMask, "StencilReadMask");
            // m_MaterialEditor.ShaderProperty(StencilWriteMask, "StencilWriteMask");

            //RenderMode
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = RenderMode.hasMixedValue;
            var shaderMode = (ShaderMode)RenderMode.floatValue;
            shaderMode = (ShaderMode)EditorGUILayout.EnumPopup(Styles.ShaderMode, shaderMode);
            if (EditorGUI.EndChangeCheck())
            {
                m_MaterialEditor.RegisterPropertyChangeUndo(Styles.ShaderMode.text);
                RenderMode.floatValue = (float)shaderMode;

                if (shaderMode == ShaderMode.Normal)
                {
                    m_Material.DisableKeyword("UNITY_UI_CLIP_RECT");
                    m_Material.DisableKeyword("UNITY_UI_ALPHACLIP");
                }
                else if (shaderMode == ShaderMode.UI)
                {
                    m_Material.EnableKeyword("UNITY_UI_CLIP_RECT");
                    m_Material.EnableKeyword("UNITY_UI_ALPHACLIP");
                }
                //
            }
            EditorGUI.showMixedValue = false;


            m_MaterialEditor.ShaderProperty(FogOn, "雾效开关");
            m_MaterialEditor.ShaderProperty(LightOn, "灯光开关");
            EditorGUI.indentLevel--;
        }

        EditorGUILayout.EndFoldoutHeaderGroup();

    }

    private void DrawMain()
    {
        m_MainFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_MainFoldout, "主贴图 (Main)");
        if (m_MainFoldout)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertyWithHDRColor(Styles.MainTex, MainTex, MainColor, false);
            DrawTileOffset(MainTex);
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    private void DrawPlanner()
    {
        m_PlannerFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_PlannerFoldout, "平移 (Planner)");
        if (m_PlannerFoldout)
        {
            EditorGUI.indentLevel++;
            DrawToggle(PannerOn, "平移开关");
            m_MaterialEditor.ShaderProperty(MainTex_PannerSpeedU, "主贴图平移速度U");
            m_MaterialEditor.ShaderProperty(MainTex_PannerSpeedV, "主贴图平移速度V");
            if (NoiseOn.floatValue == 1)
            {
                m_MaterialEditor.ShaderProperty(NoiseTex_PannerSpeedU, "噪声贴图平移速度U");
                m_MaterialEditor.ShaderProperty(NoiseTex_PannerSpeedV, "噪声贴图平移速度V");
            }
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    private void DrawMask()
    {
        m_MaskFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_MaskFoldout, "遮罩 (Mask)");
        if (m_MaskFoldout)
        {
            EditorGUI.indentLevel++;
            DrawToggle(MaskOn, "遮罩开关");
            m_MaterialEditor.TexturePropertySingleLine(Styles.MaskTex, MaskTex);
            DrawTileOffset(MaskTex);
            EditorGUI.indentLevel--;
        }

        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    private void DrawNoise()
    {
        m_NoiseFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_NoiseFoldout, "扰动 (Noise)");
        if (m_NoiseFoldout)
        {
            EditorGUI.indentLevel++;
            DrawToggle(NoiseOn, "扰动开关");
            m_MaterialEditor.TexturePropertySingleLine(Styles.NoiseTex, NoiseTex);
            DrawTileOffset(NoiseTex);
            m_MaterialEditor.ShaderProperty(NoiseIntensity, "扰动强度");
            EditorGUI.indentLevel--;
        }

        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    private void DrawDissolve()
    {
        m_DissolveFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_DissolveFoldout, "溶解 (Dissolve)");
        if (m_DissolveFoldout)
        {
            EditorGUI.indentLevel++;
            DrawToggle(DissolveOn, "溶解开关");
            // DrawToggle(ReverseDissolve, "反向溶解");
            m_MaterialEditor.TexturePropertySingleLine(Styles.DissolveTex, DissolveTex);
            DrawTileOffset(DissolveTex);
            m_MaterialEditor.ShaderProperty(DissolveFactor, "溶解因子");
            m_MaterialEditor.ShaderProperty(DissolveWidth, "溶解宽度");
            m_MaterialEditor.ShaderProperty(DissolveWidthColor, "溶解颜色");
            m_MaterialEditor.ShaderProperty(HardnessFactor, "溶解硬度");
            EditorGUI.indentLevel--;
        }

        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    private void DrawFresnel()
    {
        m_FresnelFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_FresnelFoldout, "边缘光 (Fresnel)");
        if (m_FresnelFoldout)
        {
            EditorGUI.indentLevel++;
            DrawToggle(FresnelOn, "边缘光开关");
            m_MaterialEditor.ColorProperty(FresnelColor, "边缘光颜色");
            m_MaterialEditor.FloatProperty(FresnelWidth, "边缘光宽度");
            EditorGUI.indentLevel--;
        }


        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    private void DrawBlendDepth()
    {
        m_BlendDepthFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_BlendDepthFoldout, "深度混合 (BlendDepth)");
        if (m_BlendDepthFoldout)
        {
            EditorGUI.indentLevel++;
            DrawToggle(BlendDepthOn, "深度混合开关");
            // m_MaterialEditor.TexturePropertySingleLine(Styles.RefractTex, RefractTex);
            // DrawTileOffset(RefractTex);
            m_MaterialEditor.FloatProperty(BlendDepth, "深度混合偏移");
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

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
                RefeshRenderQueue();
            }
            queueOffsetProp.floatValue = queue;
            EditorGUI.showMixedValue = false;
        }
    }

    private void RefeshRenderQueue()
    {
        GUILayout.Space(10);
        m_Material.renderQueue = (int)RenderQueue.Transparent;
        m_Material.renderQueue += m_Material.HasProperty("_QueueOffset") ? (int)m_Material.GetFloat("_QueueOffset") : 0;
    }


    protected void DrawTileOffset(MaterialProperty textureProp)
    {
        m_MaterialEditor.TextureScaleOffsetProperty(textureProp);
    }

    protected void DrawToggle(MaterialProperty prop, string label)
    {
        m_MaterialEditor.ShaderProperty(prop, label);
        // prop.floatValue = EditorGUILayout.Toggle(label, prop.floatValue == 1) ? 1 : 0;
    }

    protected static class Styles
    {
        public static readonly GUIContent CullMode = new GUIContent("Cull Mode");
        public static readonly GUIContent ShaderMode = new GUIContent("Shader Mode");
        public static readonly GUIContent ClipOn = new GUIContent("ClipOn");
        public static readonly GUIContent ZWrite = new GUIContent("Zwrite");
        public static readonly GUIContent MainTex = new GUIContent("Base Color");
        public static readonly GUIContent MaskTex = new GUIContent("Mask Tex");
        public static readonly GUIContent NoiseTex = new GUIContent("Noise Tex");
        public static readonly GUIContent DissolveTex = new GUIContent("Dissolve Tex");
        public static readonly GUIContent RefractTex = new GUIContent("Refract Tex");
        public static readonly GUIContent queueSlider = new GUIContent("Priority",
               "Determines the chronological rendering order for a Material. High values are rendered first.");
    }
}
