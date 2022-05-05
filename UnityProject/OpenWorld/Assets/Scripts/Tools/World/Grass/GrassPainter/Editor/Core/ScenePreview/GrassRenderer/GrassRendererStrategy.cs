using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class GrassRendererStrategy
{
    public Mesh mesh;
    public Material material;


    public abstract void Init();
    public abstract void AddData(Matrix4x4 data);
    public abstract void Render();
    public abstract void Clear();
}
