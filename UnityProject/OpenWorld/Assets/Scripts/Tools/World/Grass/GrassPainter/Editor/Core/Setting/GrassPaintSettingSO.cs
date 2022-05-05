using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using Sirenix.OdinInspector;

namespace GrassPainter
{
    public class GrassPaintSettingSO : SerializedScriptableObject
    {
        public LayerMask paintLayerMask = 1;

        [Button("Save")]
        public void Save()
        {
            EditorUtility.SetDirty(this);
            AssetDatabase.SaveAssets();
        }
    }
}
