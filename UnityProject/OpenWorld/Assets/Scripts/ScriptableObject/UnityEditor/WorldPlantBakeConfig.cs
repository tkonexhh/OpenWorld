using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;


namespace XHH
{
    public class WorldPlantBakeConfig : SerializedScriptableObject
    {
        public Transform grassRoot;
        public Transform treeRoot;

#if UNITY_EDITOR
        [Button("Bake")]
        private void Bake()
        {
            BakeGrass();
            BakeTree();
        }


        private void BakeGrass()
        {
            if (grassRoot == null)
                return;

            string bakePath = "Assets/Resources/InstanceConfig/World/Grass/GrassTileSO_0_0.asset";

            if (EditorHelper.LoadAssetAtPath(bakePath, typeof(GrassTileSO)) == null)
            {
                var so = SerializedScriptableObject.CreateInstance<GrassTileSO>();
                EditorHelper.CreateAsset(so, bakePath);
            }

            GrassTileSO grassTileSO = EditorHelper.LoadAssetAtPath(bakePath, typeof(GrassTileSO)) as GrassTileSO;
            grassTileSO.Clear();

            int totalCount = 0;
            int totalType = 0;
            Dictionary<byte, List<GrassInstanceData>> bakedData = new Dictionary<byte, List<GrassInstanceData>>();

            for (int i = 0; i < grassRoot.childCount; i++)
            {
                var grassTypeRoot = grassRoot.GetChild(i);
                totalType++;
                for (int j = 0; j < grassTypeRoot.childCount; j++)
                {
                    var grass = grassTypeRoot.GetChild(j);
                    if (UnityEditor.PrefabUtility.IsAnyPrefabInstanceRoot(grass.gameObject))
                    {
                        //去GrassPrefabInfo去找相关信息
                        string prefabPath = UnityEditor.PrefabUtility.GetPrefabAssetPathOfNearestInstanceRoot(grass.gameObject);
                        prefabPath = prefabPath.Replace("Assets/Resources/Prefab/", "");
                        prefabPath = prefabPath.Replace(".prefab", "");
                        var id = GrassPrefabInfoSO.S.GetIdByPath(prefabPath);
                        var data = GrassInstanceData.CreateGrassInstanceData(grass, grassRoot);

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

            }


            //最后把bakedData归入到
            GrassGroupData[] groupDatas = new GrassGroupData[bakedData.Count];
            int index = 0;
            var enumerator = bakedData.GetEnumerator();
            while (enumerator.MoveNext())
            {
                byte type = enumerator.Current.Key;
                List<GrassInstanceData> value = enumerator.Current.Value;
                totalCount += value.Count;
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

            Debug.LogError("Bake Grass Finish Type--Type:" + totalType + "Count:" + totalCount);
        }


        private void BakeTree()
        {
            if (treeRoot == null)
            {
                return;
            }

            string bakePath = "Assets/Resources/InstanceConfig/World/Tree/TreeTileSO_0_0.asset";

            if (EditorHelper.LoadAssetAtPath(bakePath, typeof(TreeTileSO)) == null)
            {
                var so = SerializedScriptableObject.CreateInstance<TreeTileSO>();
                EditorHelper.CreateAsset(so, bakePath);
            }

            TreeTileSO tileSO = EditorHelper.LoadAssetAtPath(bakePath, typeof(TreeTileSO)) as TreeTileSO;
            tileSO.Clear();

            Dictionary<byte, List<TreeInstanceData>> bakedData = new Dictionary<byte, List<TreeInstanceData>>();
            for (int i = 0; i < treeRoot.childCount; i++)
            {
                var tree = treeRoot.GetChild(i);
                if (UnityEditor.PrefabUtility.IsAnyPrefabInstanceRoot(tree.gameObject))//只有预制体才能保存位置信息
                {
                    //去GrassPrefabInfo去找相关信息
                    string prefabPath = UnityEditor.PrefabUtility.GetPrefabAssetPathOfNearestInstanceRoot(tree.gameObject);
                    prefabPath = prefabPath.Replace("Assets/Resources/Prefab/", "");
                    prefabPath = prefabPath.Replace(".prefab", "");
                    var id = GrassPrefabInfoSO.S.GetIdByPath(prefabPath);
                    var data = TreeInstanceData.CreateInstanceData(tree);

                    if (!bakedData.ContainsKey(id))
                    {
                        List<TreeInstanceData> datas = new List<TreeInstanceData>();
                        bakedData.Add(id, datas);
                    }
                    bakedData[id].Add(data);
                }
                else
                {
                    Debug.LogError("非预制体:" + tree.name);
                }
            }
        }
#endif


    }

}