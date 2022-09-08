using UnityEngine;

namespace UnityEditor.Rendering.Universal
{
    static partial class UniversalRenderPipelineCameraUI
    {
        public partial class Output
        {
            public class Styles
            {

                // Using the pipeline Settings
                public static GUIContent[] displayedCameraOptions =
                {
                    EditorGUIUtility.TrTextContent("Off"),
                    EditorGUIUtility.TrTextContent("Use settings from Render Pipeline Asset"),
                };

                public static int[] cameraOptions = { 0, 1 };

                public static readonly GUIContent targetTextureLabel = EditorGUIUtility.TrTextContent("Output Texture", "The texture to render this camera into, if none then this camera renders to screen.");

                public static string inspectorOverlayCameraText = L10n.Tr("Inspector Overlay Camera");
                public static GUIContent allowMSAA = EditorGUIUtility.TrTextContent("MSAA", "Enables Multi-Sample Anti-Aliasing, a technique that smooths jagged edges.");
                public static GUIContent allowHDR = EditorGUIUtility.TrTextContent("HDR", "High Dynamic Range gives you a wider range of light intensities, so your lighting looks more realistic. With it, you can still see details and experience less saturation even with bright light.", (Texture)null);

                public static string cameraTargetTextureMSAA = L10n.Tr("Camera target texture requires {0}x MSAA. Universal pipeline {1}.");
                public static string pipelineMSAACapsSupportSamples = L10n.Tr("is set to support {0}x");
                public static string pipelineMSAACapsDisabled = L10n.Tr("has MSAA disabled");
            }
        }
    }
}