using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEditor;

namespace GrassPainter
{
    public class PrefabPreviewElement : VisualElement
    {
        private Label m_LabelBG;
        private Button m_BgButton;
        private VisualElement m_BG;
        private Label m_NameLabel;

        public Button bgButton => m_BgButton;

        private GrassPainterPrefab m_PainterPrefab;
        public GrassPainterPrefab painterPrefab
        {
            get => m_PainterPrefab;
            set
            {
                m_PainterPrefab = value;
                RefreshPreview();
            }
        }

        public int index { get; set; }

        public PrefabPreviewElement()
        {
            var visualTree = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(GrassPainterDefine.toolPath + "GrassPainter/Res/UXML/PrefabPreview.uxml");
            VisualElement labelFromUXML = visualTree.Instantiate();
            this.Add(labelFromUXML);
            m_LabelBG = labelFromUXML.Q<Label>("Label");
            m_BgButton = labelFromUXML.Q<Button>("BgButton");
            m_BG = labelFromUXML.Q<VisualElement>("bg");
            m_NameLabel = labelFromUXML.Q<Label>("NameLabel");
            RefreshPreview();
        }

        private void RefreshPreview()
        {
            if (m_PainterPrefab != null)
            {
                m_LabelBG.style.backgroundImage = AssetPreview.GetAssetPreview(m_PainterPrefab.prefab);
                m_NameLabel.text = m_PainterPrefab.GetName();
            }
        }

        public void Selected()
        {
            m_BG.style.backgroundColor = Color.green;
            m_NameLabel.style.color = Color.red;
        }

        public void UnSelected()
        {
            m_BG.style.backgroundColor = Color.red;
            m_NameLabel.style.color = Color.green;
        }
    }
}
