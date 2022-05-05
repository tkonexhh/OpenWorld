// using System.Collections;
// using System.Collections.Generic;
// using UnityEngine;


// namespace XHH
// {
//     public class GrassComponent
//     {
//         private GrassTileSO m_GrassTileSO;

//         private IndirectRenderer m_IndirectRenderer;

//         private IndirectRenderer[] m_IndirectRenderers;

//         public void Init()
//         {
//             StreamingGrassTileSO.LoadAsset(Vector2Int.zero, (so) =>
//             {
//                 m_GrassTileSO = so;
//             });

//             var groups = m_GrassTileSO.tileData.groupDatas;
//             GrassIndirectInstanceData[] indirectInstanceDatas = new GrassIndirectInstanceData[groups.Length];
//             m_IndirectRenderers = new IndirectRenderer[groups.Length];

//             for (int i = 0; i < groups.Length; i++)
//             {
//                 byte type = groups[i].type;
//                 var instanceDatas = groups[i].instanceDatas;

//                 var grassPrefabInfo = GrassPrefabInfoSO.S.GetGrassPrefabInfo(type);

//                 GrassIndirectInstanceData indirectInstanceData = new GrassIndirectInstanceData();
//                 indirectInstanceData.lod0Mesh = grassPrefabInfo.indirectDrawSO.meshLOD0;
//                 indirectInstanceData.lod1Mesh = grassPrefabInfo.indirectDrawSO.meshLOD1;
//                 indirectInstanceData.lod2Mesh = grassPrefabInfo.indirectDrawSO.meshLOD2;
//                 indirectInstanceData.itemsTRS = instanceDatas;
//                 indirectInstanceData.indirectMaterial = grassPrefabInfo.indirectDrawSO.instanceMaterial;
//                 indirectInstanceData.originBounds = grassPrefabInfo.bounds;
//                 indirectInstanceData.positionOffset = m_GrassTileSO.tileData.center;
//                 indirectInstanceDatas[i] = indirectInstanceData;
//                 // m_IndirectRenderers[i] = new IndirectRenderer(indirectInstanceData);
//             }

//             m_IndirectRenderer = new IndirectRenderer(indirectInstanceDatas);

//         }


//         public void Update()
//         {
//             for (int i = 0; i < m_IndirectRenderers.Length; i++)
//             {
//                 m_IndirectRenderers[i]?.Render();
//             }
//             m_IndirectRenderer?.Render();
//         }

//         public void LateUpdate()
//         {
//             for (int i = 0; i < m_IndirectRenderers.Length; i++)
//             {
//                 m_IndirectRenderers[i]?.CalcCullAndLOD();
//             }
//             m_IndirectRenderer?.CalcCullAndLOD();
//         }

//         public void DrawGizmos()
//         {
//             for (int i = 0; i < m_IndirectRenderers.Length; i++)
//             {
//                 m_IndirectRenderers[i]?.DrawGizmos();
//             }
//             m_IndirectRenderer?.DrawGizmos();
//         }

//         public void Destroy()
//         {
//             for (int i = 0; i < m_IndirectRenderers.Length; i++)
//             {
//                 m_IndirectRenderers[i]?.Destroy();
//             }
//             m_IndirectRenderer?.Destroy();
//         }


//     }

// }