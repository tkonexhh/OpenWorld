// using System.Collections;
// using System.Collections.Generic;
// using UnityEngine;
// using Sirenix.OdinInspector;
// using HMK;
// using Chess.LODGroupIJob.JobSystem;
// using Unity.Mathematics;

// namespace GrassPainter
// {
//     public class AutoCreateGrassSO : SerializedScriptableObject
//     {
//         [LabelText("草的分布图")] public Texture2D controlMap;
//         [LabelText("边界渐变系数"), Range(0.1f, 0.7f)] public float border = 0.35f;
//         [LabelText("单位像素的种植密度"), Range(0.1f, 2f)] public float countPerMerter = 0.7f;
//         [LabelText("阴暗区密度"), Range(0.1f, 1f)] public float sunlessDensity = 0.3f;
//         [LabelText("过滤名称")] public List<string> filtersName;

//         public GrassPainterPrefab grassPainterPrefab { get; set; }

//         public List<GrassTRS> GrassDatas = new List<GrassTRS>();
//         List<string> m_FilterNameList = new List<string>();
//         int m_LayerMask =
//                       1 << Layer.TERRAIN |
//                       1 << Layer.Default |
//                       1 << Layer.ROCK |
//                       1 << Layer.BUILDING;

//         int m_SunlessMaskLayer = 1 << Layer.SHADOW_RECEIVER;
//         float m_SunlessHitDistance = 50f;



//         [Button("生成")]
//         public void Generate()
//         {
//             if (grassPainterPrefab == null)
//                 return;

//             if (controlMap == null) return;
//             if (grassPainterPrefab.material == null) return;
//             if (grassPainterPrefab.indirectMaterial == null) return;
//             if (grassPainterPrefab.mesh == null) return;

//             var mesh = grassPainterPrefab.mesh;

//             string filterTail = "_LOD0(Clone)";
//             int tailLegth = filterTail.Length;
//             m_FilterNameList.Clear();

//             for (int i = 0; i < filtersName.Count; i++)
//             {
//                 if (!m_FilterNameList.Contains(filtersName[i]))
//                 {
//                     m_FilterNameList.Add(filtersName[i]);
//                 }
//             }

//             GrassDatas.Clear();
//             Vector2Int texelSize = new Vector2Int(controlMap.width, controlMap.height);
//             Debug.LogError(texelSize);
//             LODGroupManager.Instance.SetAllLOD0();

//             //获取单位像素对应的世界范围
//             Vector3 worldSize = WorldConfig.S.worldSize;
//             // Debug.LogError(sizePrePixel);
//             float grassHeight = mesh.bounds.size.y;

//             int finalCount = 0;
//             int filterCount = 0;
//             int sunlessCount = 0;
//             int sunlessFilterCount = 0;
//             int width = (int)(worldSize.x * countPerMerter);
//             int height = (int)(worldSize.z * countPerMerter);
//             float space = 1 / countPerMerter;
//             Vector2 sizePerPexel = new Vector2(worldSize.x / texelSize.x, worldSize.z / texelSize.y);

//             for (int w = 0; w < width; w++)
//             {
//                 for (int h = 0; h < height; h++)
//                 {
//                     float4 color1 = 0;// = controlMap.GetPixel(ix, iy);

//                     float x = w * space;
//                     float y = h * space;

//                     int px = (int)(x / sizePerPexel.x);
//                     int py = (int)(y / sizePerPexel.y);

//                     //卷积核3*3
//                     for (int ix = -1; ix <= 1; ix++)
//                     {
//                         for (int iy = -1; iy <= 1; iy++)
//                         {
//                             // Debug.LogError(ix + "--" + iy);
//                             if ((px + ix) >= 0 && (px + ix) <= controlMap.width
//                             && (py + iy) >= 0 && (py + iy) <= controlMap.height)
//                             {
//                                 Color _color = controlMap.GetPixel(px + ix, py + iy);
//                                 color1.x += (_color.r > 0.05f ? 1f : 0f);
//                                 color1.y += _color.g;
//                                 color1.z += _color.b;
//                                 color1.w += _color.a;
//                             }

//                         }
//                     }

//                     color1.x /= 9f;

//                     //Color _color = controlMap.GetPixel(px, py);
//                     //color1.x = _color.r;
//                     float min = border;
//                     float max = 0.8f;

//                     // 最小值保护
//                     min = Mathf.Min(max - 0.1f, min);

//                     if (color1.x <= min)
//                     {
//                         continue;
//                     }

//                     // Debug.LogError(color1);

//                     //获取对应像素在世界的坐标
//                     Vector3 pixelCenter = new Vector3((x + 0.5f), 0, (y + 0.5f));
//                     // Debug.LogError(pixelCenter);

//                     // Debug.LogError(layerMask.value);
//                     //给随机偏移
//                     Vector3 randomSphere = UnityEngine.Random.insideUnitSphere * space * 0.08f;
//                     pixelCenter += new Vector3(randomSphere.x, 0, randomSphere.z);
//                     pixelCenter.y = WorldConfig.S.worldSize.y;

//                     //从天上打射线下来
//                     Ray rayDown = new Ray(pixelCenter, Vector3.down);
//                     RaycastHit hit;
//                     if (Physics.Raycast(rayDown, out hit, pixelCenter.y, m_LayerMask))
//                     {
//                         if (hit.normal.y > 0.85f)
//                         {
//                             if (CheckFilter(hit.transform))
//                             {
//                                 // Debug.LogError(name);
//                                 filterCount++;
//                                 continue;
//                             }

//                             rayDown = new Ray(hit.point + Vector3.up * m_SunlessHitDistance, Vector3.down);

//                             if (Physics.Raycast(rayDown, out RaycastHit sparseHit, m_SunlessHitDistance, m_SunlessMaskLayer))
//                             {
//                                 sunlessCount++;
//                                 // 密度过滤，密度太低不处理
//                                 if (UnityEngine.Random.value > sunlessDensity)
//                                 {
//                                     sunlessFilterCount++;
//                                     continue;
//                                 }
//                             }
//                             else if (hit.normal.y > 0.5f)
//                             {
//                                 // 有坡度时，使用大一点的随机范围，防止看起来像梯田，不自然
//                                 pixelCenter = new Vector3((x + 0.5f), 0, (y + 0.5f));
//                                 randomSphere = UnityEngine.Random.insideUnitSphere * space * 0.6f;
//                                 pixelCenter += new Vector3(randomSphere.x, 0, randomSphere.z);
//                                 pixelCenter.y = WorldConfig.S.worldSize.y;

//                                 rayDown = new Ray(pixelCenter, Vector3.down);
//                                 if (!Physics.Raycast(rayDown, out hit, pixelCenter.y, m_LayerMask))
//                                 {
//                                     continue;
//                                 }

//                                 if (CheckFilter(hit.transform))
//                                 {
//                                     // Debug.LogError(name);
//                                     filterCount++;
//                                     continue;
//                                 }
//                             }

//                             float rate = Mathf.Clamp01((max - color1.x) / (max - min));
//                             //float adjustY = Mathf.Sqrt(1 - hit.normal.y * hit.normal.y) * space * 0.5f;
//                             float adjustY = rate * grassHeight * 0.6f;


//                             GrassTRS grassData = new GrassTRS();
//                             grassData.position = hit.point + Vector3.down * (0.02f + adjustY);
//                             // grassData.rotateY = (byte)UnityEngine.Random.Range(0, byte.MaxValue);
//                             grassData.rotateY = UnityEngine.Random.Range(0, 360);
//                             grassData.scale = UnityEngine.Random.Range(1f, 1.5f);
//                             GrassDatas.Add(grassData);

//                             finalCount++;
//                         }
//                     }
//                 }
//             }

//             Debug.LogError("顶部剔除数量:" + filterCount);
//             Debug.LogError("阴暗处总数量:" + sunlessCount);
//             Debug.LogError("阴暗处剔除数量:" + sunlessFilterCount);
//             Debug.LogError("生成总数量:" + finalCount);
//             LODGroupManager.Instance.RecoverAllLOD();

//             UnityEditor.EditorUtility.SetDirty(this);
//             UnityEditor.AssetDatabase.SaveAssets();
//         }

//         bool CheckFilter(Transform trans)
//         {
//             if (trans.gameObject.layer != Layer.TERRAIN)
//             {
//                 string name = trans.gameObject.name;

//                 foreach (var filterName in m_FilterNameList)
//                 {
//                     if (name.StartsWith(filterName))
//                     {
//                         return true;
//                     }
//                 }
//             }

//             return false;
//         }


//         [Button("添加到场景")]
//         public void AddtoScene()
//         {
//             if (grassPainterPrefab == null)
//                 return;

//             SceneGrassContainerMgr.S.CreateContainer(grassPainterPrefab.GetName());
//             for (int i = 0; i < GrassDatas.Count; i++)
//             {
//                 SceneGrassContainerMgr.S.AddInstanceData(grassPainterPrefab.GetName(), GrassDatas[i]);
//             }

//             GrassQuadTreeSpaceMgr.S.Update(true);
//         }
//     }
// }
