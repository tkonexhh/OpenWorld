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
    public class GrassPrefabInfoWindow : OdinEditorWindow
    {
        public const string menuName = "制作Grass预制体信息(GrassPrefabInfo Maker)";

        [MenuItem(ToolsPathDefine.worldPath + menuName, priority = 2)]
        private static void Open()
        {
            var window = GetWindow<GrassPrefabInfoWindow>();
            window.position = GUIHelper.GetEditorWindowRect().AlignCenter(400, 500);
        }


        [PreviewField]
        [LabelText("草的预制体")] public GameObject grassPrefab;

        [LabelText("强制覆盖")] public bool isOverride = false;



        [Button("保存预制体信息")]
        public void SavePrefabInfo(byte id)
        {
            if (grassPrefab == null)
                return;


            //必须是预制体
            if (!PrefabUtility.IsAnyPrefabInstanceRoot(grassPrefab))
            {
                return;
            }

            //计算包围体
            Bounds originBounds = CalculateBounds(grassPrefab);
            Debug.LogError(originBounds);

            string prefabPath = UnityEditor.PrefabUtility.GetPrefabAssetPathOfNearestInstanceRoot(grassPrefab);
            prefabPath = prefabPath.Replace("Assets/Resources/Prefab/", "");
            prefabPath = prefabPath.Replace(".prefab", "");


            GrassPrefabInfo prefabInfo;
            prefabInfo.bounds = originBounds;
            prefabInfo.resPath = prefabPath;
            prefabInfo.indirectDrawSO = null;

            if (GrassPrefabInfoSO.S.HasPrefabInfo(id))
            {
                if (isOverride)
                {

                    GrassPrefabInfoSO.S.AddGrassPrefabInfo(id, prefabInfo);
                }
            }
            else
            {
                GrassPrefabInfoSO.S.AddGrassPrefabInfo(id, prefabInfo);
            }
            Debug.LogError("Save Finish");

        }


        private Bounds CalculateBounds(GameObject prefab)
        {
            GameObject obj = Instantiate(prefab);
            obj.transform.position = Vector3.zero;
            obj.transform.rotation = Quaternion.Euler(Vector3.zero);
            obj.transform.localScale = Vector3.one;
            Renderer[] rends = obj.GetComponentsInChildren<Renderer>();
            Bounds b = new Bounds();
            if (rends.Length > 0)
            {
                b = new Bounds(rends[0].bounds.center, rends[0].bounds.size);
                for (int r = 1; r < rends.Length; r++)
                {
                    b.Encapsulate(rends[r].bounds);
                }
            }
            b.center = Vector3.zero;
            DestroyImmediate(obj);

            return b;
        }
    }
}
