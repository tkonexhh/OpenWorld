using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public static class MathHelper
{
    public static float Remap(this float value, float from1, float to1, float from2, float to2)
    {
        return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
    }

    public static long Clamp(long value, long min, long max)
    {
        if (value < min)
        {
            value = min;
            return value;
        }
        if (value > max)
        {
            value = max;
        }
        return value;
    }

    public static bool PointInCircle(Vector3 pos1, Vector3 center, float radius)
    {
        return Vector3.Distance(pos1, center) <= radius;
    }

    public static double Abs(this double d)
    {
        return d > 0 ? d : -d;
    }


    /// <summary>
    /// 判定点是否在四边型内
    /// </summary>
    public static bool IsPointInPolygon(Vector3 targetPos, Vector3 areaPos, float length, float width, float euler)
    {
        Quaternion rotation = Quaternion.Euler(0, euler, 0);
        Vector3 forwardFector = (rotation * Vector3.forward).normalized * (width / 2);
        Vector3 rightFector = (rotation * Vector3.right).normalized * (length / 2);

        Vector3 leftTopPos = areaPos + (forwardFector - rightFector);
        Vector3 rightTopPos = areaPos + (forwardFector + rightFector);
        Vector3 leftBottomPos = areaPos - (forwardFector + rightFector);
        Vector3 rightBottomPos = areaPos - (forwardFector - rightFector);

#if TEST
            Debug.DrawLine(rightTopPos, leftTopPos, Color.yellow);
            Debug.DrawLine(leftTopPos, leftBottomPos, Color.yellow);
            Debug.DrawLine(leftBottomPos, rightBottomPos, Color.yellow);
            Debug.DrawLine(rightBottomPos, rightTopPos, Color.yellow);
#endif

        return IsPointInPolygon(targetPos, leftTopPos, rightTopPos, leftBottomPos, rightBottomPos);
    }

    /// <summary>
    /// 判定某点是否在四边形内(面积计算法)
    /// </summary>
    public static bool IsPointInPolygon(Vector3 target, Vector3 a, Vector3 b, Vector3 c, Vector3 d)
    {
        double dTriangle = TriangleArea(a, b, target) + TriangleArea(b, c, target) + TriangleArea(c, d, target) + TriangleArea(d, a, target);
        double dQuadrangle = TriangleArea(a, b, c) + TriangleArea(c, d, a);
        return dTriangle <= dQuadrangle;
    }

    /// <summary>
    /// 计算三角型面积
    /// </summary>
    static float TriangleArea(Vector3 a, Vector3 b, Vector3 c)
    {
        float result = Mathf.Abs((a.x * b.z + b.x * c.z + c.x * a.z - b.x * a.z - c.x * b.z - a.x * c.z) / 2.0f);
        return result;
    }
}

