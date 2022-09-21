using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace OpenWorld.RenderPipelines.ShaderGUI
{
    public class LitShader : ShaderGUIBase
    {
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            EditorGUI.BeginChangeCheck();
            base.OnGUI(materialEditor, properties);

            if (EditorGUI.EndChangeCheck())
            {
                SetShadowCasterPass();
            }
        }
    }
}
