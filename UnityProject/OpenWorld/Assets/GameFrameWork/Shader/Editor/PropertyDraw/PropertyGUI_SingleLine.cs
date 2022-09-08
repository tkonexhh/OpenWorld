using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

/// <summary>
/// 会将图片单独一行显示 适合不需要tilloffset的
/// 
/// </summary>
public class SingleLineDrawer : MaterialPropertyDrawer
{
    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        //如果不是Vector类型，则把unity的默认警告框的高度40
        if (prop.type == MaterialProperty.PropType.Texture)
        {
            return 5f;
        }
        return base.GetPropertyHeight(prop, label, editor);
    }

    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        if (prop.type == MaterialProperty.PropType.Texture)
        {
            editor.TexturePropertySingleLine(new GUIContent(label), prop);
        }
        else
        {
            base.OnGUI(position, prop, label, editor);
        }
    }
}
