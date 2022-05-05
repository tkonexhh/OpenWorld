using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEditor.UIElements;
using System;
using System.Collections;
using System.Collections.Generic;

namespace GrassPainter
{
    public class GrassPainterWindow : EditorWindow
    {
        [MenuItem(XHH.ToolsPathDefine.WorldPath + "植被工具(GrassPainterWindow)")]
        public static void ShowExample()
        {
            GrassPainterWindow window = GetWindow<GrassPainterWindow>();
            window.titleContent = new GUIContent("GrassPainterWindow");
            window.Show();
            window.position = new Rect(100, 100, 700, 700);
        }

        private VisualElement m_Root;
        private Button m_AutoBtn, m_PaintBtn, m_PrefabBtn, m_SettingBtn, m_LoadBakeBtn;
        private Button m_SaveBtn, m_LoadBtn, m_ClearBtn;
        private VisualElement m_MainContainer;
        private FuncElement m_FuncElement;
        private MenuType m_MenuType;

        enum MenuType
        {
            AutoPaint,
            Paint,
            Register,
            Setting,
        }




        public void CreateGUI()
        {
            m_Root = rootVisualElement;

            var visualTree = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(GrassPainterDefine.toolPath + "GrassPainter/Res/UXML/GrassPainterWindow.uxml");
            VisualElement labelFromUXML = visualTree.Instantiate();
            m_Root.Add(labelFromUXML);

            InitUI(labelFromUXML);
            OnClickPaint();
            GrassPainterMgr.S.Init();
            SceneView.duringSceneGui += GrassPainterMgr.S.OnSceneGUI;
        }

        private void InitUI(VisualElement labelFromUXML)
        {
            m_AutoBtn = labelFromUXML.Q<Button>("AutoBtn");
            m_PaintBtn = labelFromUXML.Q<Button>("PaintBtn");
            m_PrefabBtn = labelFromUXML.Q<Button>("PrefabBtn");
            m_SettingBtn = labelFromUXML.Q<Button>("SettingBtn");
            m_SaveBtn = labelFromUXML.Q<Button>("SaveButton");
            m_LoadBtn = labelFromUXML.Q<Button>("LoadButton");
            m_ClearBtn = labelFromUXML.Q<Button>("ClearButton");
            m_LoadBakeBtn = labelFromUXML.Q<Button>("LoadBakeButton");
            m_MainContainer = labelFromUXML.Q<VisualElement>("MainContainer");

            m_AutoBtn.clicked += OnClickAuto;
            m_PaintBtn.clicked += OnClickPaint;
            m_PrefabBtn.clicked += OnClickPrefab;
            m_SettingBtn.clicked += OnClickSetting;
            m_SaveBtn.clicked += OnClickSave;
            m_LoadBtn.clicked += OnClickLoad;
            m_ClearBtn.clicked += OnClickClear;
            m_LoadBakeBtn.clicked += OnClickLoadBake;
        }



        private void OnClickAuto()
        {
            if (m_MenuType == MenuType.AutoPaint)
                return;
            m_MenuType = MenuType.AutoPaint;
            RemoveFunc();
            // m_FuncElement = new AutoCreateGrassView();
            // m_FuncElement.Init();
            // m_Root.Add(m_FuncElement);
        }

        private void OnClickPaint()
        {
            if (m_MenuType == MenuType.Paint)
                return;
            m_MenuType = MenuType.Paint;

            RemoveFunc();
            m_FuncElement = new PaintGrassElement();
            m_FuncElement.Init();
            m_Root.Add(m_FuncElement);
        }

        private void OnClickPrefab()
        {
            if (m_MenuType == MenuType.Register)
                return;
            m_MenuType = MenuType.Register;

            RemoveFunc();
            m_FuncElement = new RegisterPrefabElement();
            m_FuncElement.Init();
            m_Root.Add(m_FuncElement);
        }

        private void OnClickSetting()
        {
            if (m_MenuType == MenuType.Setting)
                return;
            m_MenuType = MenuType.Setting;

            RemoveFunc();
            m_FuncElement = new SettingView();
            m_FuncElement.Init();
            m_Root.Add(m_FuncElement);
        }

        private void RemoveFunc()
        {
            if (m_FuncElement != null && m_Root != null)
            {
                m_FuncElement.OnDestroy();
                m_Root.Remove(m_FuncElement);
            }
            m_FuncElement = null;
        }

        private void OnClickSave()
        {
            SceneGrassContainerMgr.S.Save();
        }

        private void OnClickLoad()
        {
            SceneGrassContainerMgr.S.Load();
        }

        private void OnClickClear()
        {
            SceneGrassContainerMgr.S.Clear();
        }

        private void OnClickLoadBake()
        {
            SceneGrassContainerMgr.S.LoadBake();
        }

        private void Update()
        {
            GrassPainterMgr.S.Update();
        }

        private void OnDestroy()
        {
            SceneView.duringSceneGui -= GrassPainterMgr.S.OnSceneGUI;
            GrassPainterMgr.S.Destroy();
            RemoveFunc();
        }


    }
}