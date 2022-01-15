using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace XHH
{
    public class GPUDrivenModule : MonoBehaviour
    {
        public DrawIndirectSO drawIndirectSO;

        private DrawIndirect m_DrawIndirect;
        public IndirectInstanceData indirectInstanceData;
        private IndirectRenderer m_IndirectRenderer;



        void Start()
        {
            m_DrawIndirect = new DrawIndirect(drawIndirectSO.mesh, drawIndirectSO.material);
            for (int i = 0; i < 100000; i++)
            {
                InstanceTRSData instanceData;
                instanceData.rotation = Random.rotation.eulerAngles;
                instanceData.position = Random.insideUnitSphere * 1000;
                instanceData.scale = Vector3.one * Random.Range(0, 5);
                m_DrawIndirect.AddInstanceData(instanceData);
            }

            m_IndirectRenderer = new IndirectRenderer("Demo", indirectInstanceData);

        }

        // Update is called once per frame
        void Update()
        {
            m_DrawIndirect.Render();
        }
    }
}
