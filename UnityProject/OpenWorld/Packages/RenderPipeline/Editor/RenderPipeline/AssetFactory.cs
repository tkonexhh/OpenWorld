using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using OpenWorld.RenderPipelines.Runtime;
using UnityEditor.Rendering;
using System.IO;

namespace UnityEditor.OpenWorld.RenderPipelines
{
    public class AssetFactory
    {

        class DoCreateNewAssetHDRenderPipeline : UnityEditor.ProjectWindowCallback.EndNameEditAction
        {
            public override void Action(int instanceId, string pathName, string resourceFile)
            {
                var newAsset = CreateInstance<OpenWorldRenderPipelineAsset>();
                newAsset.name = Path.GetFileName(pathName);

                AssetDatabase.CreateAsset(newAsset, pathName);
                ProjectWindowUtil.ShowCreatedAsset(newAsset);
            }
        }

        [MenuItem("Assets/Create/Rendering/OpenWorld Render Pipeline Asset")]
        static void CreateRenderPipeline()
        {
            var icon = EditorGUIUtility.FindTexture("ScriptableObject Icon");
            ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, ScriptableObject.CreateInstance<DoCreateNewAssetHDRenderPipeline>(), "New RenderPipelineAsset.asset", icon, null);
        }

        class DoCreateNewAssetHDRenderPipelineResources : ProjectWindowCallback.EndNameEditAction
        {
            public override void Action(int instanceId, string pathName, string resourceFile)
            {
                var newAsset = CreateInstance<OpenWorldRenderPipelineRuntimeResources>();
                newAsset.name = Path.GetFileName(pathName);

                // to prevent cases when the asset existed prior but then when upgrading the package, there is null field inside the resource asset
                ResourceReloader.ReloadAllNullIn(newAsset, PipelineUtils.GetRenderPipelinePath());

                AssetDatabase.CreateAsset(newAsset, pathName);
                ProjectWindowUtil.ShowCreatedAsset(newAsset);
            }
        }


        [MenuItem("Assets/Create/Rendering/OpenWorld Render Pipeline Resources")]
        static void CreateRenderPipelineResources()
        {
            var icon = EditorGUIUtility.FindTexture("ScriptableObject Icon");
            ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, ScriptableObject.CreateInstance<DoCreateNewAssetHDRenderPipelineResources>(), "New RenderPipelineResources.asset", icon, null);
        }


    }
}
