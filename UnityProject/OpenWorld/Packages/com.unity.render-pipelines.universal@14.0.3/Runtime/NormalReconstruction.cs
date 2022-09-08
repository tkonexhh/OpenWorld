namespace UnityEngine.Rendering.Universal.Internal
{
    /// <summary>
    /// Util class for normal reconstruction.
    /// </summary>
    public static class NormalReconstruction
    {
        private static readonly int s_NormalReconstructionMatrixID = Shader.PropertyToID("_NormalReconstructionMatrix");
        private static Matrix4x4[] s_NormalReconstructionMatrix = new Matrix4x4[2];

        /// <summary>
        /// Setup properties needed for normal reconstruction from depth using shader functions in NormalReconstruction.hlsl
        /// </summary>
        /// <param name="cmd">Command Buffer used for properties setup.</param>
        /// <param name="cameraData">CameraData containing camera matrices information.</param>
        public static void SetupProperties(CommandBuffer cmd, in CameraData cameraData)
        {
            Matrix4x4 view = cameraData.GetViewMatrix();
            Matrix4x4 proj = cameraData.GetProjectionMatrix();
            s_NormalReconstructionMatrix[0] = proj * view;

            // camera view space without translation, used by SSAO.hlsl ReconstructViewPos() to calculate view vector.
            Matrix4x4 cview = view;
            cview.SetColumn(3, new Vector4(0.0f, 0.0f, 0.0f, 1.0f));
            Matrix4x4 cviewProj = proj * cview;
            Matrix4x4 cviewProjInv = cviewProj.inverse;

            s_NormalReconstructionMatrix[0] = cviewProjInv;


            cmd.SetGlobalMatrixArray(s_NormalReconstructionMatrixID, s_NormalReconstructionMatrix);
        }
    }
}
