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

    public static void DeleteAssetPath(string assetPath)
    {
        string path = PathHelper.AssetsPath2ABSPath(assetPath);
        DeletePath(path);
    }

}
