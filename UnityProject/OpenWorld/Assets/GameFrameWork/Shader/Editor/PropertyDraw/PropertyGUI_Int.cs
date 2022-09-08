using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class IntDrawer : MaterialPropertyDrawer
{
    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        EditorGUI.BeginChangeCheck();

        int newValue = EditorGUI.IntField(position, label, (int)prop.floatValue);
        if (EditorGUI.EndChangeCheck())
        {
            prop.floatValue = newValue;
        }

    }
}
