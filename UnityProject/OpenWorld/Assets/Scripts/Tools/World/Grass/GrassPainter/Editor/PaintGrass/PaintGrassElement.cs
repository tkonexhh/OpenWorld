using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEditor;
using UnityEditor.UIElements;
using System.Text;

namespace GrassPainter
{
    public class PaintGrassElement : FuncElement
    {
        private Slider m_BrushSizeSlider;
        private SliderInt m_BrushDensitySlider;
        private LayerMaskField m_PaintLayerMaskField;
        private LayerField m_TargetLayerMaskField;
        private Toggle m_RandomRatateToggle;
        private Toggle m_RandomScaleToggle;
        private TextField m_MinScaleLabel;
        private TextField m_MaxScaleLabel;
        private MinMaxSlider m_ScaleMinMaxSlider;
        private ScrollView m_PrefabScrollView;
        private SceneViewHandle m_SceneViewHandle;
        private Label m_NumLabel;
        private StringBuilder m_StringBuilder = new StringBuilder();

        private PaintGrassSelecter m_Selecter;
        public PaintGrassSelecter selecter => m_Selecter;

        public BrushSetting brushSetting
        {
            get
            {
                BrushSetting setting = new BrushSetting();
                setting.brushSize = m_BrushSizeSlider.value;
                setting.brushDensity = m_BrushDensitySlider.value;
                setting.paintMask = m_PaintLayerMaskField.value;
                setting.targetLayer = m_TargetLayerMaskField.value;
                setting.randomRotate = m_RandomRatateToggle.value;
                setting.randomScale = m_RandomScaleToggle.value;
                setting.scaleRange = m_ScaleMinMaxSlider.value;
                setting.mouseModeDelta = 1;
                return setting;
            }
        }


        public override void Init()
        {
            var visualTree = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(GrassPainterDefine.toolPath + "GrassPainter/Res/UXML/PaintGrassElement.uxml");
            VisualElement labelFromUXML = visualTree.Instantiate();
            this.Add(labelFromUXML);

            m_BrushSizeSlider = labelFromUXML.Q<Slider>("BrushSizeSlider");
            m_BrushDensitySlider = labelFromUXML.Q<SliderInt>("BrushDesintySlider");
            m_PaintLayerMaskField = labelFromUXML.Q<LayerMaskField>("PaintLayerMaskField");
            m_PaintLayerMaskField.RegisterValueChangedCallback(OnPaintLayerMaskChange);
            m_PaintLayerMaskField.value = GrassPaintSetting.S.grassPainterSettingSO.paintLayerMask;
            m_TargetLayerMaskField = labelFromUXML.Q<LayerField>("TargetLayerField");
            m_TargetLayerMaskField.value = 1;

            m_RandomRatateToggle = labelFromUXML.Q<Toggle>("RandomRotateToggle");
            m_RandomRatateToggle.value = true;
            m_RandomScaleToggle = labelFromUXML.Q<Toggle>("RandomScaleToggle");
            m_RandomScaleToggle.value = true;
            m_MinScaleLabel = labelFromUXML.Q<TextField>("MinScaleLabel");
            m_MaxScaleLabel = labelFromUXML.Q<TextField>("MaxScaleLabel");
            m_ScaleMinMaxSlider = labelFromUXML.Q<MinMaxSlider>("ScaleMinMaxSlider");
            m_ScaleMinMaxSlider.RegisterValueChangedCallback(OnScaleRangeChange);
            RefeshRamdomScale(m_ScaleMinMaxSlider.value);
            m_MinScaleLabel.RegisterValueChangedCallback(OnScaleRangeInputChange);
            m_MaxScaleLabel.RegisterValueChangedCallback(OnScaleRangeInputChange);

            m_PrefabScrollView = labelFromUXML.Q<ScrollView>("PrefabScrollView");
            m_PrefabScrollView.style.flexDirection = FlexDirection.Row;
            m_PrefabScrollView.horizontalScrollerVisibility = ScrollerVisibility.Auto;// = true;

            m_NumLabel = labelFromUXML.Q<Label>("NumLabel");

            m_Selecter = new PaintGrassSelecter(m_PrefabScrollView);
            m_Selecter.onSelectChaned += OnSelectChaned;

            m_SceneViewHandle = new SceneViewHandle();
            m_SceneViewHandle.Init(this);
            SceneView.duringSceneGui += m_SceneViewHandle.SceneGUI;
            SceneView.duringSceneGui += SceneGUI;
            Selection.activeGameObject = null;

            m_SceneViewHandle.onEarse += OnPaint;
        }

        public override void OnDestroy()
        {
            if (m_SceneViewHandle != null)
            {
                m_SceneViewHandle.Destroy();
                SceneView.duringSceneGui -= m_SceneViewHandle.SceneGUI;
                m_SceneViewHandle.onEarse -= OnPaint;
            }

            SceneView.duringSceneGui -= SceneGUI;
            if (m_Selecter != null)
            {
                m_Selecter.onSelectChaned -= OnSelectChaned;
            }

        }

        private void SceneGUI(SceneView sceneView)
        {
            HandleBrushSizeHoyKey();
            UpdateNumLabel();
        }

        private void OnPaint()
        {
            GrassQuadTreeSpaceMgr.S.Refesh();
        }

        private void HandleBrushSizeHoyKey()
        {
            float SizeInterval = 0.1f;
            if (GrassPainterHelper.PreventCustomUserHotkey(EventType.ScrollWheel, EventModifiers.Control, KeyCode.None))
            {
                Event currentEvent = Event.current;
                if (currentEvent.delta.y < 0)
                {
                    m_BrushSizeSlider.value = m_BrushSizeSlider.value + SizeInterval;
                }
                else
                {
                    m_BrushSizeSlider.value = m_BrushSizeSlider.value - SizeInterval;
                    m_BrushSizeSlider.value = Mathf.Max(SizeInterval, m_BrushSizeSlider.value);
                }
            }
        }

        private void OnSelectChaned()
        {
            m_SceneViewHandle.OnSelectChaned();
        }

        private void UpdateNumLabel()
        {
            m_StringBuilder.Clear();
            m_StringBuilder.Append("数量\n");
            foreach (var item in SceneGrassContainerMgr.S.containerMap)
            {
                m_StringBuilder.Append(item.Key + ":" + item.Value.GetCount() + "\n");
            }
            m_NumLabel.text = m_StringBuilder.ToString();
        }

        private void OnPaintLayerMaskChange(ChangeEvent<int> layermask)
        {
            GrassPaintSetting.S.grassPainterSettingSO.paintLayerMask = (LayerMask)layermask.newValue;
            GrassPaintSetting.S.SaveSetting();
        }

        private void OnScaleRangeChange(ChangeEvent<Vector2> scaleRange)
        {
            RefeshRamdomScale(scaleRange.newValue);
        }

        private void RefeshRamdomScale(Vector2 range)
        {
            float minScale = (float)System.Math.Round(range.x, 2);
            float maxScale = (float)System.Math.Round(range.y, 2);
            m_MinScaleLabel.SetValueWithoutNotify(minScale.ToString());
            m_MaxScaleLabel.SetValueWithoutNotify(maxScale.ToString());
            m_ScaleMinMaxSlider.SetValueWithoutNotify(new Vector2(minScale, maxScale));
        }

        private void OnScaleRangeInputChange(ChangeEvent<string> scaleInput)
        {
            float minScale = 1;
            float maxScale = 1;
            float.TryParse(m_MinScaleLabel.text, out minScale);
            float.TryParse(m_MaxScaleLabel.text, out maxScale);
            minScale = (float)System.Math.Round(minScale, 2);
            maxScale = (float)System.Math.Round(maxScale, 2);
            m_ScaleMinMaxSlider.SetValueWithoutNotify(new Vector2(minScale, maxScale));

        }


    }
}
