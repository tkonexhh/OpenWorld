using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class RangeDrawer : MaterialPropertyDrawer
{
    public RangeDrawer()
    {
    }

    public RangeDrawer(params string[] showList)
    {
    }

    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        //如果不是Vector类型，则把unity的默认警告框的高度40
        if (!(prop.type == MaterialProperty.PropType.Range))
        {
            return 40f;
        }
        return EditorGUI.GetPropertyHeight(SerializedPropertyType.Float, new GUIContent(label));
    }

    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        if (!(prop.type == MaterialProperty.PropType.Range))
        {
            GUILayout.Label(prop.displayName + " :   Property must be of type range");
            // editor.DefaultShaderProperty( prop, label );
            return;
        }


        EditorGUI.BeginChangeCheck();

        float oldLabelWidth = EditorGUIUtility.labelWidth;
        EditorGUIUtility.labelWidth = 0f;

        float value = EditorGUILayout.Slider(prop.displayName, prop.floatValue, prop.rangeLimits.x, prop.rangeLimits.y);

        EditorGUIUtility.labelWidth = oldLabelWidth;
        if (EditorGUI.EndChangeCheck())
        {
            prop.floatValue = value;
        }
    }
}
