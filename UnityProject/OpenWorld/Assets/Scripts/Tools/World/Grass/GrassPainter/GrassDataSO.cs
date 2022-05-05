using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;


#if UNITY_EDITOR
using UnityEditor;
#endif

namespace GrassPainter
{
    public class GrassDataSO : SerializedScriptableObject
    {

        //手工摆放
        public GrassClusterData[] PaintClusterDatas;

#if UNITY_EDITOR
        [Button("Save")]
        public void Save()
        {
            EditorUtility.SetDirty(this);
            AssetDatabase.SaveAssets();
        }
#endif
    }
}
