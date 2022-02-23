using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace XHH
{
    public class ComputeShaderHelper
    {
        public static bool TryGetKernel(string kernelName, ref ComputeShader computeShader, ref int kernelID)
        {
            if (!computeShader.HasKernel(kernelName))
            {
                Debug.LogError(kernelName + " kernel not found in " + computeShader.name + "!");
                return false;
            }

            kernelID = computeShader.FindKernel(kernelName);
            return true;
        }
    }

}