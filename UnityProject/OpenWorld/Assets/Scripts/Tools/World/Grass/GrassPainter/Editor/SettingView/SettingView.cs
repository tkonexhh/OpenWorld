using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEditor.UIElements;
using UnityEditor;

namespace GrassPainter
{
    public class SettingView : FuncElement
    {
        private EnumField m_ModeEnumField;
        public override void Init()
        {
            var visualTree = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(GrassPainterDefine.toolPath + "GrassPainter/Res/UXML/SettingView.uxml");
            VisualElement labelFromUXML = visualTree.Instantiate();
            this.Add(labelFromUXML);

            GrassPaintSetting.S.Init();

            // m_ModeEnumField = labelFromUXML.Q<EnumField>("ModeEnumField");
            // m_ModeEnumField.Init(PaintMode.Instance);
            // m_ModeEnumField.value = GrassPaintSetting.S.grassPainterSettingSO.paintMode;
            // m_ModeEnumField.RegisterValueChangedCallback(OnPaintModeChange);

        }

        public override void OnDestroy()
        {
            // m_ModeEnumField.RegisterValueChangedCallback(OnPaintModeChange);
        }

        // private void OnPaintModeChange(ChangeEvent<System.Enum> mode)
        // {
        //     GrassPaintSetting.S.grassPainterSettingSO.paintMode = (PaintMode)m_ModeEnumField.value;
        //     GrassPaintSetting.S.SaveSetting();
        // }
    }
}
