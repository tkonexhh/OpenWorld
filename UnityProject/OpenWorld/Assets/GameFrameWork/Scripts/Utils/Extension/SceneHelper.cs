using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
#endif

public static class EditorSceneHelper
{
#if UNITY_EDITOR
    public static SceneAsset GetCurrentSceneAsset()
    {
        var scene = EditorSceneManager.GetActiveScene();
        string scenePath = scene.path;
        string parentPath = "Assets/Scenes/" + PathHelper.GetParentForderName(scenePath);
        string sceneAssetPath = parentPath + "/" + scene.name + ".unity";
        return AssetDatabase.LoadAssetAtPath<SceneAsset>(sceneAssetPath);
    }
#endif
}

