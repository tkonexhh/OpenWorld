using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;



public class IOHelper
{
    /// <summary>
    /// 删除指定目录下的文件以及文件夹
    /// </summary>
    /// <param name="path"></param>
    public static void DeletePath(string path)
    {
        if (Directory.Exists(path))
        {
            DirectoryInfo info = new DirectoryInfo(path);
            FileSystemInfo[] arrInfo = info.GetFileSystemInfos();
            for (int i = 0; i < arrInfo.Length; ++i)
            {
                if (arrInfo[i].Attributes == FileAttributes.Directory)
                {
                    Directory.Delete(arrInfo[i].ToString(), true);
                }
                else
                {
                    File.Delete(arrInfo[i].ToString());
                }
            }
        }
    }

    public static void CreatePath(string path)
    {
        if (!Directory.Exists(path))
            Directory.CreateDirectory(path);
    }

    public static void DeleteAssetPath(string assetPath)
    {
        string path = PathHelper.AssetsPath2ABSPath(assetPath);
        DeletePath(path);
    }

    public static void CreateDirectory(string path)
    {
        if (!Directory.Exists(path))
            Directory.CreateDirectory(path);
    }

    public static string GetParentDirectoryName(string assetPath)
    {
        var parentName = GetDirectory(assetPath).Parent.Name;
        return parentName;
    }

    public static string GetParentPath(string assetPath)
    {
        var parentPath = GetDirectory(assetPath).Parent.FullName;
        parentPath = parentPath.Replace("\\", "/");
        return "Assets" + parentPath.Replace(Application.dataPath, "");
    }

    public static DirectoryInfo GetDirectory(string assetPath)
    {
        var absPath = Application.dataPath + assetPath.Replace("Assets", "");
        var parentPath = new DirectoryInfo(absPath);//.FullName;
        return parentPath;
    }

}

