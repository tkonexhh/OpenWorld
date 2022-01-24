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
            byte type = groups[0].type;
            var instanceDatas = groups[0].instanceDatas;


            var grassPrefabInfo = GrassPrefabInfoSO.S.GetGrassPrefabInfo(type);

            GrassIndirectInstanceData indirectInstanceData = new GrassIndirectInstanceData();
            indirectInstanceData.lod0Mesh = grassPrefabInfo.indirectDrawSO.meshLOD0;
            indirectInstanceData.lod1Mesh = grassPrefabInfo.indirectDrawSO.meshLOD1;
            indirectInstanceData.lod2Mesh = grassPrefabInfo.indirectDrawSO.meshLOD2;
            indirectInstanceData.itemsTRS = instanceDatas;
            indirectInstanceData.indirectMaterial = grassPrefabInfo.indirectDrawSO.instanceMaterial;
            indirectInstanceData.bounds = grassPrefabInfo.bounds;

            m_IndirectRenderer = new IndirectRenderer(grassPrefabInfo.resPath, indirectInstanceData);
        }


        public void Update()
        {
            m_IndirectRenderer?.CalcCullAndLOD();
            m_IndirectRenderer?.Render();
        }

        public void DrawGizmos()
        {
            m_IndirectRenderer?.DrawGizmos();
        }
    }

}