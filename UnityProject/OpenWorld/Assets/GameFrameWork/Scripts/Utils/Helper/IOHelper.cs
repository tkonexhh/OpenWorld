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

    // public static void DeleteAssetPath(string assetPath)
    // {
    //     DeletePath(PathHelper.AssetsPath2ABSPath(assetPath));
    // }

    public static void CreatePath(string path)
    {
        if (!Directory.Exists(path))
            Directory.CreateDirectory(path);
    }

    // public static void CreateAssetPath(string assetPath)
    // {
    //     CreatePath(PathHelper.AssetsPath2ABSPath(assetPath));
    // }

}
