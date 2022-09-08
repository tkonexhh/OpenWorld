using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class ReadOnlyDrawer : MaterialPropertyDrawer
{
    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        //EditorGUI.BeginDisabledGroup(true);
        //{
        //    editor.DefaultShaderProperty(position, prop, label);
        //}
        //EditorGUI.EndDisabledGroup();

        //unity建议使用DisabledScope会更安全（然而我并不知道为什么更安全）
        using (new EditorGUI.DisabledScope(true))
        {
            editor.DefaultShaderProperty(position, prop, label);
        }

    }
    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        return MaterialEditor.GetDefaultPropertyHeight(prop);
    }
}
