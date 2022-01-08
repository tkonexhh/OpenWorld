using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class ColorExtensions
{

    /// <summary>
    /// 获取颜色明度
    /// </summary>
    /// <param name="color"></param>
    /// <returns></returns>
    static public float Lumiance(this Color color)
    {
        Vector3 rgb = new Vector3(color.r, color.g, color.b);
        return Vector3.Dot(rgb, new Vector3(0.2126f, 0.7152f, 0.0722f));
    }

}
