using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassInstancePage
{
    public int totalCount = 0;
    private const int MAX_COUNT = 1023;
    public Matrix4x4[] datas = new Matrix4x4[MAX_COUNT];


    public bool AddData(Matrix4x4 data)
    {
        if (!CheckAdd())
            return false;

        datas[totalCount] = data;
        totalCount += 1;
        return true;
    }

    private bool CheckAdd()
    {
        return totalCount < MAX_COUNT;
    }

    public void Clear()
    {
        totalCount = 0;
    }
}
