using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using Sirenix.Utilities;
using Sirenix.Utilities.Editor;
using UnityEditor;


namespace XHH
{
    public class WorldEditorWindow : OdinMenuEditorWindow
    {
        public const string menuName = "大世界烘焙器(WorldEditor)";

        public enum Page
        {
            Plant,
            Setting,
        }

        [MenuItem(ToolsPathDefine.worldPath + menuName, priority = 2)]
        private static void Open()
        {
            var window = GetWindow<WorldEditorWindow>();
            window.position = GUIHelper.GetEditorWindowRect().AlignCenter(800, 500);
        }

        [EnumToggleButtons]
        [ShowInInspector]
        [LabelText("选项"), LabelWidth(100)]
        [OnValueChanged("OnPageChange")]
        private Page m_Page;
        private int m_EnumIndex;
        private bool m_TreeRebuild;

        private WorldPlantBakeConfig m_PlantBakeConfig;
        private WolldSettingConfig m_Setting;

        private void OnPageChange()
        {
            m_TreeRebuild = true;
        }


        protected override void Initialize()
        {

            IOHelper.CreateAssetPath(PathHelper.FileNameToPath(MenuContants.plantPath));
            IOHelper.CreateAssetPath(PathHelper.FileNameToPath(MenuContants.settingPath));

            if (EditorHelper.LoadAssetAtPath(MenuContants.plantPath, typeof(WorldPlantBakeConfig)) == null)
                EditorHelper.CreateAsset(SerializedScriptableObject.CreateInstance<WorldPlantBakeConfig>(), MenuContants.plantPath);
            m_PlantBakeConfig = EditorHelper.LoadAssetAtPath(MenuContants.plantPath, typeof(WorldPlantBakeConfig)) as WorldPlantBakeConfig;

            if (EditorHelper.LoadAssetAtPath(MenuContants.settingPath, typeof(WolldSettingConfig)) == null)
                EditorHelper.CreateAsset(SerializedScriptableObject.CreateInstance<WolldSettingConfig>(), MenuContants.settingPath);
            m_Setting = EditorHelper.LoadAssetAtPath(MenuContants.settingPath, typeof(WolldSettingConfig)) as WolldSettingConfig;

        }




        protected override void OnGUI()
        {
            if (m_TreeRebuild && Event.current.type == EventType.Layout)
            {
                ForceMenuTreeRebuild();
                m_TreeRebuild = false;
            }

            SirenixEditorGUI.Title("The Wolrd Baker", "", TextAlignment.Center, true);
            EditorGUILayout.Space();

            switch (m_Page)
            {
                case Page.Plant:
                case Page.Setting:
                    DrawEditor(m_EnumIndex);
                    break;
            }

            EditorGUILayout.Space();
            base.OnGUI();
        }


        protected override void OnBeginDrawEditors()
        {
            var toolbarHeight = this.MenuTree.Config.SearchToolbarHeight;
            switch (m_Page)
            {
                default:
                    break;
            }
        }

        protected override OdinMenuTree BuildMenuTree()
        {
            var tree = new OdinMenuTree(true);
            switch (m_Page)
            {
                case Page.Plant:
                    tree.Add(MenuContants.plantName, m_PlantBakeConfig);
                    break;
                case Page.Setting:
                    tree.Add(MenuContants.setting, m_Setting);
                    break;
            }

            return tree;
        }

        protected override void DrawEditors()
        {
            switch (m_Page)
            {
                case Page.Plant:
                case Page.Setting:
                    break;
            }
            DrawEditor((int)m_Page);
        }

        protected override IEnumerable<object> GetTargets()
        {
            List<object> targets = new List<object>();
            targets.Add(m_PlantBakeConfig);
            targets.Add(m_Setting);
            // targets.Add(drawModule);
            // targets.Add(m_GameSetting);
            targets.Add(base.GetTarget());
            m_EnumIndex = targets.Count - 1;
            return targets;
        }

        protected override void DrawMenu()
        {
            switch (m_Page)
            {
                case Page.Plant:
                case Page.Setting:
                    break;
                default:
                    // base.DrawMenu();
                    break;
            }
        }


        public class MenuContants
        {
            public static string plantName = "Plant";
            public static string plantPath = "Assets/EditorRes/Config/World/WorldPlantBakeConfog.asset";

            public static string setting = "Setting";
            public static string settingPath = "Assets/EditorRes/Config/World/WolldSettingConfig.asset";
        }
    }

}