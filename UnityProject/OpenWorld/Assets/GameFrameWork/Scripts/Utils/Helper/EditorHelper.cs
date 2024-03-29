using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

#if UNITY_EDITOR
using UnityEditor;
#endif

public class EditorHelper
{
    public static void CreateAsset(UnityEngine.Object asset, string path)
    {
#if UNITY_EDITOR
        AssetDatabase.CreateAsset(asset, path);
#endif
    }


    public static UnityEngine.Object LoadAssetAtPath(string assetPath, Type type)
    {
#if UNITY_EDITOR
        return AssetDatabase.LoadAssetAtPath(assetPath, type);
#else
            return null;
           
#endif
    }

    public static T LoadAssetAtPath<T>(string assetPath) where T : UnityEngine.Object
    {
#if UNITY_EDITOR
        return AssetDatabase.LoadAssetAtPath(assetPath, typeof(T)) as T;
#else
            return null;
           
#endif
    }


    public static void SetDirty(UnityEngine.Object target)
    {
#if UNITY_EDITOR
        EditorUtility.SetDirty(target);
        AssetDatabase.Refresh();
#endif
    }


    public static void DrawWireCube(Vector3 center, Vector3 size)
    {
#if UNITY_EDITOR
        Gizmos.DrawWireCube(center, size);
#endif
    }

    public static void DisplayDialog(string title, string message, string ok, string cancel)
    {
#if UNITY_EDITOR
        EditorUtility.DisplayDialog(title, message, ok, cancel);
#endif
    }

    public static void DisplayDialog(string message)
    {
#if UNITY_EDITOR
        EditorUtility.DisplayDialog("Tips", message, "ok");
#endif
    }
}
