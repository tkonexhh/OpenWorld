using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;


public static class GameObjectExtensions
{
    public static void DestroySelf(this GameObject @this)
    {
        GameObject.Destroy(@this);
    }

    public static void DestroyAllChilds(this GameObject @this)
    {
        var childCount = @this.transform.childCount;
        for (int i = 0; i < childCount; i++)
        {
            GameObject.Destroy(@this.transform.GetChild(i).gameObject);
        }
    }

    public static GameObject DontDestroy(this GameObject @this)
    {
        GameObject.DontDestroyOnLoad(@this);
        return @this;
    }


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

    static public T AddMissingComponent<T>(this GameObject gameObject) where T : Component
    {

        T com = gameObject.GetComponent<T>();
        if (com == null)
        {
            return gameObject.AddComponent<T>();
        }
        else
        {
            return com;
        }
    }

    static public T AddMissingComponent<T>(this Component component) where T : Component
    {
        return AddMissingComponent<T>(component.gameObject);
    }

}

