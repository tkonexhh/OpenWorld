using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace XHH
{
    public class GrassComponent
    {
        private GrassTileSO m_GrassTileSO;

        private IndirectRenderer m_IndirectRenderer;

        public void Init()
        {
            StreamingGrassTileSO.LoadAsset(Vector2Int.zero, (so) =>
            {
                m_GrassTileSO = so;
            });

            var groups = m_GrassTileSO.tileData.groupDatas;
            GrassIndirectInstanceData[] indirectInstanceDatas = new GrassIndirectInstanceData[1];
            for (int i = 0; i < 1; i++)
            // for (int i = 0; i < groups.Length; i++)
            {
                byte type = groups[i].type;
                var instanceDatas = groups[i].instanceDatas;

                var grassPrefabInfo = GrassPrefabInfoSO.S.GetGrassPrefabInfo(type);

                GrassIndirectInstanceData indirectInstanceData = new GrassIndirectInstanceData();
                indirectInstanceData.lod0Mesh = grassPrefabInfo.indirectDrawSO.meshLOD0;
                indirectInstanceData.lod1Mesh = grassPrefabInfo.indirectDrawSO.meshLOD1;
                indirectInstanceData.lod2Mesh = grassPrefabInfo.indirectDrawSO.meshLOD2;
                indirectInstanceData.itemsTRS = instanceDatas;
                indirectInstanceData.indirectMaterial = grassPrefabInfo.indirectDrawSO.instanceMaterial;
                indirectInstanceData.originBounds = grassPrefabInfo.bounds;
                indirectInstanceData.positionOffset = m_GrassTileSO.tileData.center;
                indirectInstanceData.resPath = grassPrefabInfo.resPath;
                indirectInstanceDatas[i] = indirectInstanceData;
            }

            m_IndirectRenderer = new IndirectRenderer(indirectInstanceDatas);

        }


        public void Update()
        {
            m_IndirectRenderer?.CalcCullAndLOD();
        }

        public void LateUpdate()
        {
            m_IndirectRenderer?.Render();
        }

        public void DrawGizmos()
        {
            m_IndirectRenderer?.DrawGizmos();
        }

        public void Destroy()
        {
            m_IndirectRenderer?.Destroy();
        }


    }

}