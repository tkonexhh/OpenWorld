using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public static class GameObjectExtensions
{
    /// <summary>
    /// 重置某个物体的三围等 c
    /// </summary>
    /// <param name="go"></param>
    static public void Reset(this GameObject go)
    {
        go.transform.localPosition = Vector3.zero;
        go.transform.localScale = Vector3.one;
        go.transform.localRotation = Quaternion.Euler(0, 0, 0);
    }

    static public void SetParent(this GameObject go, Transform parent)
    {
        go.transform.SetParent(parent);
    }

    static public void SetParent(this GameObject go, GameObject target)
    {
        go.transform.SetParent(target.transform);
    }

    static public Component AddMissingComponent(this GameObject gameObject, Type component)
    {
        Component com = gameObject.GetComponent(component);
        if (com == null)
        {
            return gameObject.AddComponent(component);
        }
        else
        {
            return com;
        }
    }

    static public Component AddMissingComponent<T>(this GameObject gameObject) where T : MonoBehaviour
    {
        Component com = gameObject.GetComponent<T>();
        if (com == null)
        {
            return gameObject.AddComponent<T>();
        }
        else
        {
            return com;
        }
    }
}
