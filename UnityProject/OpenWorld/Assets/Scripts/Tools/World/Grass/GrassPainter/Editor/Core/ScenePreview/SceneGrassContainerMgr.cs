using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace GrassPainter
{
    public class SceneGrassContainerMgr : TSingleton<SceneGrassContainerMgr>
    {

        public Dictionary<string, SceneGrassContainer> containerMap = new Dictionary<string, SceneGrassContainer>();


        public void CreateContainer(string key)
        {
            if (containerMap.ContainsKey(key))
            {
                // Debug.LogError("Already Contains key:" + key);
                return;
            }

            SceneGrassContainer container = new SceneGrassContainer(key);
            containerMap.Add(key, container);
        }

        public void AddInstanceData(string key, GrassTRS data)
        {
            if (data.position.x < 0 || data.position.z < 0)
                return;


            CreateContainer(key);
            containerMap[key].AddInstanceData(data);
        }

        public void Erasing(string key, Vector3 hitpoint, float brushSize)
        {
            if (!containerMap.ContainsKey(key))
            {
                // Debug.LogError("Already Contains key:" + key);
                return;
            }

            containerMap[key].Erasing(hitpoint, brushSize);
        }


        public void Clear()
        {
            SceneGrassContainerMgr.S.containerMap.Clear();
            GrassQuadTreeSpaceMgr.S.Refesh();
            GrassRendererGroupMgr.S.Clear();
        }

        public void Destroy()
        {
            Clear();
        }

        public void Save()
        {
            //手工
            List<GrassClusterData> paintDatas = new List<GrassClusterData>();

            foreach (var container in SceneGrassContainerMgr.S.containerMap)
            {
                GrassClusterData data = new GrassClusterData();
                data.key = container.Key;
                //TODO
                //找到PrefabInfo
                var grassPainterPrefab = GrassPainterDB.S.GetGrassPainterPrefab(container.Key);
                if (grassPainterPrefab == null)
                {
                    continue;
                }
                data.indirectMatName = grassPainterPrefab.indirectMaterial.name;
                data.matName = grassPainterPrefab.material.name;
                data.meshName = grassPainterPrefab.mesh.name;

                List<GrassTRS> datas = new List<GrassTRS>();
                for (int x = 0; x < container.Value.instanceDataArray.GetLength(0); x++)
                {
                    for (int y = 0; y < container.Value.instanceDataArray.GetLength(1); y++)
                    {
                        if (container.Value.instanceDataArray[x, y] == null)
                            continue;

                        if (container.Value.instanceDataArray[x, y].instanceDatas.Count <= 0)
                            continue;

                        datas.AddRange(container.Value.instanceDataArray[x, y].instanceDatas);
                    }
                }

                data.instanceDatas = datas.ToArray();
                paintDatas.Add(data);

            }

            GrassDataMgr.S.grassDataSO.PaintClusterDatas = paintDatas.ToArray();
            GrassDataMgr.S.SaveData();
        }

        public void Load()
        {
            Clear();
            var paintDatas = GrassDataMgr.S.grassDataSO.PaintClusterDatas;


            //手工摆放节点
            for (int i = 0; i < paintDatas.Length; i++)
            {
                var key = paintDatas[i].key;

                SceneGrassContainerMgr.S.CreateContainer(key);
                for (int j = 0; j < paintDatas[i].instanceDatas.Length; j++)
                {
                    SceneGrassContainerMgr.S.AddInstanceData(key, paintDatas[i].instanceDatas[j]);
                }

            }

            GrassQuadTreeSpaceMgr.S.Update(true);
        }

        public void LoadBake()
        {
            Clear();
            // GrassDataMgr.S.grassDataSO

            //读取全部GrassChunkSOX0Y0
            // Dictionary<string, List<GrassTRS>> grassMap = new Dictionary<string, List<GrassTRS>>();
            // int width = 35;
            // for (int x = 0; x < width; x++)
            // {
            //     for (int y = 0; y < width; y++)
            //     {
            //         var grassChunkSO = HMK.EditorHelper.LoadAssetAtPath<HMK.GrassChunkSO>(string.Format("Assets/Res/InstanceConfig/World/Grass/GrassChunkSOX{0}Y{1}.asset", x, y));
            //         if (grassChunkSO == null)
            //             continue;
            //         for (int i = 0; i < grassChunkSO.grassConfigs.Count; i++)
            //         {
            //             if (!grassMap.ContainsKey(grassChunkSO.grassConfigs[i].key))
            //             {
            //                 grassMap.Add(grassChunkSO.grassConfigs[i].key, new List<GrassTRS>());
            //             }

            //             grassMap[grassChunkSO.grassConfigs[i].key].AddRange(grassChunkSO.grassConfigs[i].items);
            //         }
            //     }
            // }


            // GrassDataMgr.S.grassDataSO.PaintClusterDatas = new GrassClusterData[grassMap.Count];
            // int index = 0;
            // foreach (var item in grassMap)
            // {
            //     var grassPrefab = GrassPainterDB.S.GetGrassPainterPrefab(item.Key);
            //     if (grassPrefab == null)
            //     {
            //         continue;
            //     }
            //     GrassDataMgr.S.grassDataSO.PaintClusterDatas[index] = new GrassClusterData();
            //     GrassDataMgr.S.grassDataSO.PaintClusterDatas[index].key = item.Key;
            //     GrassDataMgr.S.grassDataSO.PaintClusterDatas[index].meshName = grassPrefab.mesh.name;
            //     GrassDataMgr.S.grassDataSO.PaintClusterDatas[index].matName = grassPrefab.material.name;
            //     GrassDataMgr.S.grassDataSO.PaintClusterDatas[index].indirectMatName = grassPrefab.indirectMaterial.name;
            //     GrassDataMgr.S.grassDataSO.PaintClusterDatas[index].instanceDatas = item.Value.ToArray();
            //     index++;
            // }
            // GrassDataMgr.S.SaveData();
            // Load();
            // Debug.LogError(grassMap.Count);
        }
    }
}
