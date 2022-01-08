using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GPUDrivenModule : MonoBehaviour
{
    public DrawIndirectSO drawIndirectSO;

    private DrawIndirect m_DrawIndirect;

    void Start()
    {
        m_DrawIndirect = new DrawIndirect(drawIndirectSO.mesh, drawIndirectSO.material);
        for (int i = 0; i < 1000; i++)
        {
            InstanceData instanceData;
            instanceData.rotation = Random.rotation.eulerAngles;
            instanceData.position = Random.insideUnitSphere * 10;
            instanceData.scale = Vector3.one * Random.Range(0, 5);
            m_DrawIndirect.AddInstanceData(instanceData);
        }
    }

    // Update is called once per frame
    void Update()
    {
        m_DrawIndirect.Render();
    }
}
