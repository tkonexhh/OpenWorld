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

        [MenuItem(ToolsPathDefine.WorldPath + menuName, priority = 1)]
        private static void Open()
        {
            var window = GetWindow<WorldEditorWindow>();
            window.position = GUIHelper.GetEditorWindowRect().AlignCenter(800, 500);
        }

        public enum Page
        {
            Terrain,
            Plant,
            Setting,
        }

        public class MenuContants
        {
            public static string terrain = "Terrain";
            public static string plantName = "Plant";
            public static string setting = "Setting";

            public static string root = "Assets/EditorRes/Config/World/";
            public static string terrainPath = root + "WorldTerrainBakeSO.asset";
            public static string plantPath = root + "WorldPlantBakeConfog.asset";
            public static string settingPath = root + "WolldSettingConfig.asset";
        }



        [EnumToggleButtons]
        [ShowInInspector]
        [LabelText("选项"), LabelWidth(100)]
        [OnValueChanged("OnPageChange")]
        private Page m_Page;
        private int m_EnumIndex;
        private bool m_TreeRebuild;

        private WorldTerrainBakeSO m_Terrain;
        private WorldPlantBakeConfig m_PlantBakeConfig;
        private WorldSettingConfig m_Setting;

        private void OnPageChange()
        {
            m_TreeRebuild = true;
        }


        protected override void Initialize()
        {
            IOHelper.CreatePath(MenuContants.root);

            m_Terrain = InitSO(MenuContants.terrainPath, typeof(WorldTerrainBakeSO)) as WorldTerrainBakeSO;
            m_PlantBakeConfig = InitSO(MenuContants.plantPath, typeof(WorldPlantBakeConfig)) as WorldPlantBakeConfig;
            m_Setting = InitSO(MenuContants.settingPath, typeof(WorldSettingConfig)) as WorldSettingConfig;

        }

        private SerializedScriptableObject InitSO(string path, System.Type type)
        {
            if (EditorHelper.LoadAssetAtPath(path, type) == null)
                EditorHelper.CreateAsset(SerializedScriptableObject.CreateInstance(type), path);
            return EditorHelper.LoadAssetAtPath(path, type) as SerializedScriptableObject;
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
                case Page.Terrain:
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
                case Page.Terrain:
                    tree.Add(MenuContants.terrain, m_Terrain);
                    break;
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
                case Page.Terrain:
                case Page.Plant:
                case Page.Setting:
                    break;
            }
            DrawEditor((int)m_Page);
        }

        protected override IEnumerable<object> GetTargets()
        {
            List<object> targets = new List<object>();
            targets.Add(m_Terrain);
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
                case Page.Terrain:
                case Page.Plant:
                case Page.Setting:
                    break;
                default:
                    // base.DrawMenu();
                    break;
            }
        }



    }

}