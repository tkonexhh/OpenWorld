using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

namespace UnityEditor
{
    public abstract class ShaderGUIBase : ShaderGUI
    {
        MaterialEditor editor;
        Object[] materials;
        protected MaterialProperty[] properties;
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            base.OnGUI(materialEditor, properties);
            editor = materialEditor;
            materials = materialEditor.targets;
            this.properties = properties;
        }

        bool HasProperty(string name) => FindProperty(name, properties, false) != null;

        //set value
        bool SetProperties(string name, float value)
        {
            MaterialProperty materialProperty = FindProperty(name, properties, false);
            if (materialProperty != null)
            {
                materialProperty.floatValue = value;
                return true;
            }
            return false;
        }

        //set toggle
        void SetProperties(string name, string keyword, bool value)
        {
            if (SetProperties(name, value ? 1f : 0f))
            {
                SetKeyword(keyword, value);
            }
        }

        //set keyword
        void SetKeyword(string keyword, bool enable)
        {
            if (enable)
            {
                foreach (Material m in materials)
                {
                    m.EnableKeyword(keyword);
                }

            }
            else
            {
                foreach (Material m in materials)
                {
                    m.DisableKeyword(keyword);
                }
            }
        }

        BlendMode SrcBlend
        {
            set => SetProperties("_SrcBlend", (float)value);
        }

        BlendMode DstBlend
        {
            set => SetProperties("_DstBlend", (float)value);
        }

        bool ZWrite
        {
            set => SetProperties("_ZWrite", value ? 1f : 0f);
        }

        RenderQueue RenderQueue
        {
            set
            {
                foreach (Material m in materials)
                {
                    m.renderQueue = (int)value;
                }
            }
        }

        enum ShadowMode
        {
            On, Off
        }

        protected void SetShadowCasterPass()
        {
            MaterialProperty shadows = FindProperty("_Shadows", properties, false);
            if (shadows == null || shadows.hasMixedValue)
            {
                return;
            }
            bool enabled = shadows.floatValue < (float)ShadowMode.Off;
            foreach (Material m in materials)
            {
                m.SetShaderPassEnabled("ShadowCaster", enabled);
            }
        }
    }


}
