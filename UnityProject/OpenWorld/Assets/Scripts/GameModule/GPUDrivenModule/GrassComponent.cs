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
            string bakePath = "Assets/Res/InstanceConfig/World/Grass/GrassTileSO_0_0.asset";
            m_GrassTileSO = UnityEditor.AssetDatabase.LoadAssetAtPath<GrassTileSO>(bakePath);
            Debug.LogError(m_GrassTileSO);

            var groups = m_GrassTileSO.tileData.groupDatas;
            byte type = groups[0].type;

            GrassPrefabInfoSO grassPrefabInfoSO = Resources.Load<GrassPrefabInfoSO>("ScriptableObject/Grass/GrassPrefabInfoSO");
            var grassPrefabInfo = grassPrefabInfoSO.GetGrassPrefabInfo(type);

            IndirectInstanceData indirectInstanceData = new IndirectInstanceData();
            indirectInstanceData.lod0Mesh = grassPrefabInfo.indirectDrawSO.meshLOD0;
            indirectInstanceData.lod1Mesh = grassPrefabInfo.indirectDrawSO.meshLOD1;
            indirectInstanceData.lod2Mesh = grassPrefabInfo.indirectDrawSO.meshLOD2;

            m_IndirectRenderer = new IndirectRenderer(grassPrefabInfo.resPath, indirectInstanceData);
        }


        public void Update()
        {
            m_IndirectRenderer?.CalcCullAndLOD();
            m_IndirectRenderer?.Render();
        }
    }

}