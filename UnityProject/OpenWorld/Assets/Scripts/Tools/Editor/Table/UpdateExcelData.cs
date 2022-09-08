using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using UnityEngine;
using UnityEditor;
using Debug = UnityEngine.Debug;
using MonKey;

namespace OpenWorld
{
    public class UpdateExcelData
    {
        [Command("Editor_UpdateExcel", "更新数据表(Update Excel Data)", QuickName = "Excel", Category = ToolsPathDefine.root)]
        [MenuItem(ToolsPathDefine.DataPath + "更新数据表(Update Excel Data)")]
        static void Run()
        {
            RunMyBat("gen_code_json.bat", Application.dataPath + "/../../../Excel/");
        }

        private static void RunMyBat(string batFile, string workingDir)
        {
            var path = FormatPath(workingDir);
            if (!System.IO.File.Exists(path + batFile))
            {
                Debug.LogError("[UpdateExcelData][RunMyBat]:" + path + batFile + " not exist");
            }
            else
            {
                RunBat(batFile, "", path);
                EditorHelper.DisplayDialog("Update Success");
                AssetDatabase.Refresh();
            }
        }

        public static System.Diagnostics.Process CreateShellExProcess(string cmd, string args, string workingDir = "")
        {
            var pStartInfo = new System.Diagnostics.ProcessStartInfo(cmd);
            pStartInfo.Arguments = args;
            pStartInfo.CreateNoWindow = false;
            pStartInfo.WindowStyle = ProcessWindowStyle.Hidden;
            pStartInfo.UseShellExecute = true;
            pStartInfo.RedirectStandardError = false;
            pStartInfo.RedirectStandardInput = false;
            pStartInfo.RedirectStandardOutput = false;
            if (!string.IsNullOrEmpty(workingDir))
                pStartInfo.WorkingDirectory = workingDir;
            return System.Diagnostics.Process.Start(pStartInfo);
        }

        public static void RunBat(string batfile, string args, string workingDir = "")
        {
            var p = CreateShellExProcess(batfile, args, workingDir);
            p.Close();
        }

        public static string FormatPath(string path)
        {
            path = path.Replace("/", "\\");
            if (Application.platform == RuntimePlatform.OSXEditor)
                path = path.Replace("\\", "/");
            return path;
        }
    }
}
