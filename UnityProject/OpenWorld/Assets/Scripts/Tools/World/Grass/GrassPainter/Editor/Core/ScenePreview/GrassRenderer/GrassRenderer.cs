using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassRenderer
{

    private GrassRendererStrategy m_RenderStrategy = new GrassRendererStrategy_Instance();

    public GrassRenderer(GrassRendererArgs args)
    {
        m_RenderStrategy.mesh = args.mesh;
        m_RenderStrategy.material = args.material;
    }

    public void AddDate(Matrix4x4 data)
    {
        m_RenderStrategy.AddData(data);
    }

    public void Render()
    {
        m_RenderStrategy.Render();
    }

    public void Clear()
    {
        m_RenderStrategy.Clear();
    }

}

public struct GrassRendererArgs
{
    public Material material;
    public Mesh mesh;
}
