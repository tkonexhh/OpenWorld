using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassRendererStrategy_Instance : GrassRendererStrategy
{
    private List<GrassInstancePage> m_Pages = new List<GrassInstancePage>();

    public override void Init()
    {

    }

    public override void AddData(Matrix4x4 data)
    {
        bool addSuccess = false;
        for (int i = 0; i < m_Pages.Count; i++)
        {
            if (m_Pages[i].AddData(data))
            {
                addSuccess = true;
                break;
            }
        }

        if (!addSuccess)
        {
            GrassInstancePage page = new GrassInstancePage();
            page.AddData(data);
            m_Pages.Add(page);
        }
    }

    public override void Render()
    {
        if (mesh == null || material == null)
            return;
        for (int i = 0; i < m_Pages.Count; i++)
        {
            if (m_Pages[i].totalCount > 0)
                Graphics.DrawMeshInstanced(mesh, 0, material, m_Pages[i].datas, m_Pages[i].totalCount);
        }
    }

    public override void Clear()
    {
        for (int i = 0; i < m_Pages.Count; i++)
        {
            m_Pages[i].Clear();
        }
    }
}
