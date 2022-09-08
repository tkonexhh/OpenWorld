using UnityEngine;
using UnityEditor;

namespace HMK.Tool
{
    public class MaterialMenuEditor
    {
        [MenuItem("CONTEXT/Material/开启自发光Bake (Set Baked Emission)")]
        public static void SetBakedEmission(MenuCommand command)
        {
            var material = command.context as Material;
            if (material != null)
                material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.BakedEmissive;
        }

        [MenuItem("CONTEXT/Material/关闭自发光Bake (Reset Baked Emission)")]
        public static void ResetBakedEmission(MenuCommand command)
        {
            var material = command.context as Material;
            if (material != null)
                material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.None;
        }

        // [MenuItem("CONTEXT/Material/清理失效属性 (Clean)", priority = 1)]
        // public static void Clean(MenuCommand command)
        // {
        //     var material = command.context as Material;
        //     if (material != null)
        //     {
        //         MaterialCleaner.MaterialCleanerMenu();
        //     }
        // }
    }
}
