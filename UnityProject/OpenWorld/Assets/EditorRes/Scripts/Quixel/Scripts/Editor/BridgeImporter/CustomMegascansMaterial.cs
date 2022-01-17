// using UnityEngine;
// using UnityEditor;
// using System;


// namespace Quixel
// {
//     public class CustomMegascansMaterial
//     {
//         public static Material CreateMaterial(int shaderType, string matPath, bool isAlembic, int dispType, int texPack)
//         {
//             if ((shaderType == 0 || shaderType == 1) && isAlembic)
//             {
//                 Debug.Log("Alembic files are not supported in LWRP/HDRP. Please change your export file format in Bridge or change your SRP in Unity.");
//                 return null;
//             }

//             try
//             {
//                 string rp = matPath + ".mat";
//                 Material mat = (Material)AssetDatabase.LoadAssetAtPath(rp, typeof(Material));
//                 if (!mat)
//                 {
//                     mat = new Material(Shader.Find(ShaderGlobalConstants.LitShaderName));
//                     AssetDatabase.CreateAsset(mat, rp);
//                     AssetDatabase.Refresh();



//                 }
//                 return mat;
//             }
//             catch (Exception ex)
//             {
//                 Debug.Log("MegascansMaterialUtils::CreateMaterial::Exception: " + ex.ToString());
//                 MegascansUtilities.HideProgressBar();
//                 return null;
//             }

//         }
//     }

// }