using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace UnityEditor
{
    class SceneDefaultShaderGUI : ShaderGUI
    {
        static class Styles
        {
            public static GUIContent colorText = new GUIContent("_Color", "Main Color");
            public static GUIContent mainTexText = new GUIContent("_MainTex", "Main Texture (RGB)");
            public static GUIContent mainTexAText = new GUIContent("_MainTexA", "Main Alpha Texture (A)");

            public static GUIContent cutoutText = new GUIContent("_Cutout", "Cutout");

            public static GUIContent normalMapTexText = new GUIContent("_NormalMapTex", "Normal Map Texture");

            public static GUIContent specularColorText = new GUIContent("_SpecularColor", "Specular Color");
            public static GUIContent specularTexText = new GUIContent("_SpecularTex", "Specular Texture");

            public static GUIContent glowMaskTexAText = new GUIContent("_GlowMaskTexA", "Glow Mask Texture (A)");
            public static GUIContent glowNoiseTexText = new GUIContent("_GlowNoiseTex", "Glow Noise Texture (RGB)");
            public static GUIContent glowColorText = new GUIContent("_GlowColor", "Glow Color");
            public static GUIContent glowSpeedText = new GUIContent("_GlowSpeed", "Glow Speed");
            public static GUIContent glowScaleText = new GUIContent("_GlowScale", "Glow Scale");

            public static GUIContent waveTexText = new GUIContent("_WaveTex", "Wave Texture");
            public static GUIContent waveColorText = new GUIContent("_WaveColor", "Wave Color");
            public static GUIContent waveNoiseTexText = new GUIContent("_WaveNoiseTex", "Wave Noise Texture");
            public static GUIContent waveStrength = new GUIContent("_WaveStrength", "Wave Strength");

            public static GUIContent fogInfluenceText = new GUIContent("_FogInfluence", "Fog Influence");
            public static GUIContent cullText = new GUIContent("_Cull", "Cull");
            public static GUIContent srcBlendText = new GUIContent("_SrcBlend", "SrcBlend");
            public static GUIContent dstBlendText = new GUIContent("_DstBlend", "DstBlend");
            public static GUIContent zWriteText = new GUIContent("_ZWrite", "ZWrite");

            public static GUIContent titleFeatureText = new GUIContent("Feature", "Feature");
            public static GUIContent titleBasicText = new GUIContent("Basic", "Basic");
            public static GUIContent titleAlphaCutText = new GUIContent("AlphaCut", "AlphaCut");
            public static GUIContent titleNormapMapText = new GUIContent("NormapMap", "NormapMap");
            public static GUIContent titleSpecularText = new GUIContent("Specular", "Specular");
            public static GUIContent titleGlowScrollText = new GUIContent("GlowScroll", "GlowScroll");
            public static GUIContent titleGlowBreathText = new GUIContent("GlowBreath", "GlowBreath");
        }

        MaterialProperty m_MPColor;
        MaterialProperty m_MPMainTex;
        MaterialProperty m_MPMainTexA;

        MaterialProperty m_MPCutout;

        MaterialProperty m_MPNormalMapTex;

        MaterialProperty m_MPSpecularColor;
        MaterialProperty m_MPSpecularTex;

        MaterialProperty m_MPGlowMaskTexA;
        MaterialProperty m_MPGlowNoiseTex;
        MaterialProperty m_MPGlowColor;
        MaterialProperty m_MPGlowSpeed;
        MaterialProperty m_MPGlowScale;

        MaterialProperty m_MPWaveTex;
        MaterialProperty m_MPWaveColor;
        MaterialProperty m_MPWaveStrength;

        MaterialProperty m_MPFogInfluence;
        MaterialProperty m_MPCull;
        MaterialProperty m_MPSrcBlend;
        MaterialProperty m_MPDstBlend;
        MaterialProperty m_MPZWrite;

        MaterialEditor m_MatEditor;
        Material m_Mat;

        bool m_IsShowDebugInfo;
        bool m_PropHasFeatureAlphaCut;
        bool m_PropHasFeatureSpecular;
        bool m_PropHasFeatureGlowScroll;
        bool m_PropHasFeatureGlowBreath;
        bool m_PropHasFeatureWave;
        bool m_PropHasFeatureDoubleSide;

        public void UpdateMP(MaterialProperty[] props)
        {
            m_MPColor = FindProperty("_Color", props);
            m_MPMainTex = FindProperty("_MainTex", props);
            m_MPMainTexA = FindProperty("_MainTexA", props);

            m_MPCutout = FindProperty("_Cutout", props);

            m_MPNormalMapTex = FindProperty("_NormalMapTex", props);

            m_MPSpecularColor = FindProperty("_SpecularColor", props);
            m_MPSpecularTex = FindProperty("_SpecularTex", props);

            m_MPGlowMaskTexA = FindProperty("_GlowMaskTexA", props);
            m_MPGlowNoiseTex = FindProperty("_GlowNoiseTex", props);
            m_MPGlowColor = FindProperty("_GlowColor", props);
            m_MPGlowSpeed = FindProperty("_GlowSpeed", props);
            m_MPGlowScale = FindProperty("_GlowScale", props);

            m_MPWaveTex = FindProperty("_WaveTex", props);
            m_MPWaveColor = FindProperty("_WaveColor", props);
            m_MPWaveStrength = FindProperty("_WaveStrength", props);

            m_MPFogInfluence = FindProperty("_FogInfluence", props);
            m_MPCull = FindProperty("_Cull", props);
            m_MPSrcBlend = FindProperty("_SrcBlend", props);
            m_MPDstBlend = FindProperty("_DstBlend", props);
            m_MPZWrite = FindProperty("_ZWrite", props);
        }

        void UpdateFeature()
        {
            m_PropHasFeatureAlphaCut = IsHaveFeature("ALPHA_CUT");
            m_PropHasFeatureSpecular = IsHaveFeature("SPECULAR");
            m_PropHasFeatureGlowScroll = IsHaveFeature("GLOW_SCROLL");
            m_PropHasFeatureGlowBreath = IsHaveFeature("GLOW_BREATH");
            m_PropHasFeatureWave = IsHaveFeature("WAVE");

            m_PropHasFeatureDoubleSide = (m_Mat.GetFloat("_Cull") == 0);
        }

        void SaveFeature()
        {
            SetFeature("ALPHA_CUT", m_PropHasFeatureAlphaCut);
            SetFeature("SPECULAR", m_PropHasFeatureSpecular);
            SetFeature("GLOW_SCROLL", m_PropHasFeatureGlowScroll);
            SetFeature("GLOW_BREATH", m_PropHasFeatureGlowBreath);
            SetFeature("WAVE", m_PropHasFeatureWave);

            m_Mat.SetFloat("_Cull", m_PropHasFeatureDoubleSide ? 0 : 2);

            if (m_PropHasFeatureAlphaCut)
            {
                m_Mat.renderQueue = (int)RenderQueue.AlphaTest;
            }
            else
            {
                m_Mat.renderQueue = (int)RenderQueue.Geometry;
            }
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            m_MatEditor = materialEditor;
            m_Mat = materialEditor.target as Material;

            UpdateMP(props);
            UpdateFeature();

            EditorGUI.BeginChangeCheck();

            FeatureGUI();
            BasicGUI();
            AlphaCutGUI();
            SpecularGUI();
            GlowEffectGUI();
            WaveGUI();
            DebugGUI();

            if (EditorGUI.EndChangeCheck())
            {
                SaveFeature();
            }
        }

        void FeatureGUI()
        {
            TitleGUI("Feature");

            m_PropHasFeatureAlphaCut = EditorGUILayout.Toggle("ALPHA_CUT", m_PropHasFeatureAlphaCut);
            m_PropHasFeatureSpecular = EditorGUILayout.Toggle("SPECULAR", m_PropHasFeatureSpecular);

            bool glowEffectEnable = EditorGUILayout.Toggle("GLOW_EFFECT", m_PropHasFeatureGlowScroll || m_PropHasFeatureGlowBreath);

            if (glowEffectEnable)
            {
                if (!(m_PropHasFeatureGlowScroll || m_PropHasFeatureGlowBreath))
                {
                    m_PropHasFeatureGlowScroll = true;
                }

                m_PropHasFeatureGlowScroll = EditorGUILayout.Toggle("    Scroll", m_PropHasFeatureGlowScroll);
                if (m_PropHasFeatureGlowScroll)
                {
                    m_PropHasFeatureGlowBreath = false;
                }

                m_PropHasFeatureGlowBreath = EditorGUILayout.Toggle("    Breath", m_PropHasFeatureGlowBreath);
                if (m_PropHasFeatureGlowBreath)
                {
                    m_PropHasFeatureGlowScroll = false;
                }
            }
            else
            {
                m_PropHasFeatureGlowScroll = false;
                m_PropHasFeatureGlowBreath = false;
            }

            m_PropHasFeatureWave = EditorGUILayout.Toggle("WAVE", m_PropHasFeatureWave);

            m_PropHasFeatureDoubleSide = EditorGUILayout.Toggle("DOUBLE_SIDE", m_PropHasFeatureDoubleSide);
        }

        void BasicGUI()
        {
            TitleGUI("Basic");
            m_MatEditor.ShaderProperty(m_MPColor, Styles.colorText);
            m_MatEditor.TexturePropertySingleLine(Styles.mainTexText, m_MPMainTex);
            m_MatEditor.TexturePropertySingleLine(Styles.mainTexAText, m_MPMainTexA);
        }

        void AlphaCutGUI()
        {
            if (!m_PropHasFeatureAlphaCut)
            {
                return;
            }

            TitleGUI("AlphaCut");
            m_MatEditor.ShaderProperty(m_MPCutout, Styles.cutoutText);
        }

        void SpecularGUI()
        {
            if (!m_PropHasFeatureSpecular)
            {
                return;
            }

            TitleGUI("Specular");
            m_MatEditor.ShaderProperty(m_MPSpecularColor, Styles.specularColorText);
            m_MatEditor.TexturePropertySingleLine(Styles.specularTexText, m_MPSpecularTex);
            m_MatEditor.TexturePropertySingleLine(Styles.normalMapTexText, m_MPNormalMapTex);
        }

        void GlowEffectGUI()
        {
            if (!m_PropHasFeatureGlowBreath && !m_PropHasFeatureGlowScroll)
            {
                return;
            }

            TitleGUI("GlowEffect");
            m_MatEditor.TexturePropertySingleLine(Styles.glowMaskTexAText, m_MPGlowMaskTexA);
            m_MatEditor.TexturePropertySingleLine(Styles.glowNoiseTexText, m_MPGlowNoiseTex);

            m_MatEditor.ShaderProperty(m_MPGlowColor, Styles.glowColorText);
            m_MatEditor.ShaderProperty(m_MPGlowSpeed, Styles.glowSpeedText);
            m_MatEditor.ShaderProperty(m_MPGlowScale, Styles.glowScaleText);
        }

        void WaveGUI()
        {
            if (!m_PropHasFeatureWave)
            {
                return;
            }

            TitleGUI("Wave");

            m_MatEditor.TexturePropertySingleLine(Styles.waveTexText, m_MPWaveTex);
            m_MatEditor.TextureScaleOffsetProperty(m_MPWaveTex);

            Vector4 v = m_MPWaveTex.textureScaleAndOffset;
            m_Mat.SetTextureScale("_WaveTex", new Vector2(v.x, v.y));
            m_Mat.SetTextureOffset("_WaveTex", new Vector2(v.z, v.w));

            m_MatEditor.ShaderProperty(m_MPWaveColor, Styles.waveColorText);
            m_MatEditor.ShaderProperty(m_MPWaveStrength, Styles.waveStrength);

            //Debug.LogError(string.Format("_WaveTex scale:{0} offset:{1}", m_Mat.GetTextureScale("_WaveTex"), m_Mat.GetTextureOffset("_WaveTex")));
        }

        void DebugGUI()
        {
            TitleGUI("Debug");
            m_IsShowDebugInfo = EditorGUILayout.Toggle("DEBUG_INFO", m_IsShowDebugInfo);

            if (!m_IsShowDebugInfo)
            {
                return;
            }

            m_MatEditor.ShaderProperty(m_MPFogInfluence, Styles.fogInfluenceText);
            m_MatEditor.ShaderProperty(m_MPCull, Styles.cullText);
            m_MatEditor.ShaderProperty(m_MPSrcBlend, Styles.srcBlendText);
            m_MatEditor.ShaderProperty(m_MPDstBlend, Styles.dstBlendText);
            m_MatEditor.ShaderProperty(m_MPZWrite, Styles.zWriteText);
            m_MatEditor.RenderQueueField();
        }

        bool IsHaveFeature(string name)
        {
            return (m_Mat.IsKeywordEnabled(name));
        }

        void SetFeature(string name, bool enable)
        {
            if (enable)
            {
                m_Mat.EnableKeyword(name);
            }
            else
            {
                m_Mat.DisableKeyword(name);
            }
        }

        void TitleGUI(string title)
        {
            GUIStyle style = new GUIStyle();
            style.fontSize = 18;
            style.normal.textColor = Color.black;

            EditorGUILayout.Space();
            EditorGUILayout.LabelField(title, style);
            EditorGUILayout.Space();
        }
    }
}
