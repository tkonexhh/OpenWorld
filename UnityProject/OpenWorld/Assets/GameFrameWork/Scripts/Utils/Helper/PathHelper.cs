using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class PathHelper
{
    public static string ABSPath2AssetsPath(string absPath)
    {
        string assetRootPath = System.IO.Path.GetFullPath(Application.dataPath);
        return "Assets" + System.IO.Path.GetFullPath(absPath).Substring(assetRootPath.Length).Replace("\\", "/");
    }

    public static string AssetsPath2ABSPath(string assetsPath)
    {
        string assetRootPath = System.IO.Path.GetFullPath(Application.dataPath);
        return assetRootPath.Substring(0, assetRootPath.Length - 6) + assetsPath;
    }

    /// <summary>
    /// 将文件路径转成文件夹路径
    /// </summary>
    /// <param name="filepath"></param>
    /// <returns></returns>
    public static string FileNameToPath(string filepath)
    {
        int index = filepath.LastIndexOf("/");
        return filepath.Substring(0, index);
    }

    public static string GetParentForderName(string assetPath)
    {
        return Directory.GetParent(assetPath).Name;
    }
}
