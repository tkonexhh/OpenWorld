using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;


namespace XHH
{
    public class WorldPlantBakeConfig : SerializedScriptableObject
    {
        public Transform root;

#if UNITY_EDITOR
        [Button("Bake")]
        private void Bake()
        {
            if (root == null)
                return;

            string bakePath = "Assets/Res/InstanceConfig/World/Grass/GrassTileSO_0_0.asset";

            if (EditorHelper.LoadAssetAtPath(bakePath, typeof(GrassTileSO)) == null)
            {
                var so = SerializedScriptableObject.CreateInstance<GrassTileSO>();
                EditorHelper.CreateAsset(so, bakePath);
            }

            GrassTileSO grassTileSO = EditorHelper.LoadAssetAtPath(bakePath, typeof(GrassTileSO)) as GrassTileSO;
            grassTileSO.Clear();




            Dictionary<byte, List<GrassInstanceData>> bakedData = new Dictionary<byte, List<GrassInstanceData>>();

            for (int i = 0; i < root.childCount; i++)
            {
                var grass = root.GetChild(i);
                if (UnityEditor.PrefabUtility.IsAnyPrefabInstanceRoot(grass.gameObject))
                {
                    //去GrassPrefabInfo去找相关信息
                    string prefabPath = UnityEditor.PrefabUtility.GetPrefabAssetPathOfNearestInstanceRoot(grass.gameObject);
                    prefabPath = prefabPath.Replace("Assets/Resources/Prefab/", "");
                    prefabPath = prefabPath.Replace(".prefab", "");
                    var id = GrassPrefabInfoSO.S.GetIdByPath(prefabPath);
                    var data = GrassInstanceData.CreateGrassInstanceData(grass, root);

                    if (!bakedData.ContainsKey(id))
                    {
                        List<GrassInstanceData> datas = new List<GrassInstanceData>();
                        bakedData.Add(id, datas);
                    }
                    bakedData[id].Add(data);
                }
                else
                {
                    Debug.LogError("非预制体:" + grass.name);
                }
            }


            //最后把bakedData归入到
            GrassGroupData[] groupDatas = new GrassGroupData[bakedData.Count];
            int index = 0;
            var enumerator = bakedData.GetEnumerator();
            while (enumerator.MoveNext())
            {
                byte type = enumerator.Current.Key;
                List<GrassInstanceData> value = enumerator.Current.Value;
                GrassInstanceData[] instanceDatas = new GrassInstanceData[value.Count];
                for (int i = 0; i < value.Count; i++)
                {
                    instanceDatas[i] = value[i];
                }

                GrassGroupData groupData = new GrassGroupData();
                groupData.type = type;
                groupData.instanceDatas = instanceDatas;
                groupDatas[index] = groupData;
                index++;
            }

            grassTileSO.tileData.groupDatas = groupDatas;
            UnityEditor.EditorUtility.SetDirty(grassTileSO);
            UnityEditor.AssetDatabase.SaveAssets();
            UnityEditor.AssetDatabase.Refresh();

            Debug.LogError("Bake Grass Finish");
        }

#endif


    }

}