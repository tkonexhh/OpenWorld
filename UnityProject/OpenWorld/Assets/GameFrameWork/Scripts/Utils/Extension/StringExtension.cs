using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Text.RegularExpressions;


public static class StringExtension
{
    /// <summary>
    /// 返回首字母大写
    /// </summary>
    /// <param name="str"></param>
    /// <returns></returns>
    public static string FirstLetterToUpper(this string str)
    {
        if (str == null)
            return null;
        if (str.Length > 1)
            return char.ToUpper(str[0]) + str.Substring(1);
        return str.ToUpper();
    }


    public static bool EndWith(this string str, string end)
    {
        if (str == null || end == null)
        {
            return false;
        }

        int strLen = str.Length;
        int endLen = end.Length;

        if (strLen < endLen)
        {
            return false;
        }

        for (int i = 0; i < endLen; ++i)
        {
            if (str[strLen - 1 - i] != end[endLen - 1 - i])
            {
                return false;
            }
        }

        return true;
    }


    public static bool StartWith(this string str, string value)
    {
        if (null == str || null == value)
        {
            return false;
        }

        if (str.Length < value.Length)
        {
            return false;
        }

        for (int i = 0; i < value.Length; ++i)
        {
            if (str[i] != value[i])
            {
                return false;
            }
        }

        return true;
    }

    /// <summary>
    /// 是否为空字符串
    /// </summary>
    public static bool IsNullOrEmpty(this string @this)
    {
        return string.IsNullOrEmpty(@this);
    }

    /// <summary>
    /// 判断是否int型
    /// </summary>
    /// <param name="value"></param>
    /// <returns></returns>
    public static bool IsInt(this string value)
    {
        return Regex.IsMatch(value, @"^[+-]?\d*$");
    }

    /// <summary>
    /// 是否含有中文
    /// </summary>
    public static bool IsContainChinese(this string @this)
    {
        bool flag = false;
        foreach (var a in @this)
        {
            if (a >= 0x4e00 && a <= 0x9fbb)
            {
                flag = true;
                break;
            }
        }
        return flag;
    }
}

