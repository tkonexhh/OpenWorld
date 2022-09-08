using System.Collections;
using System.Collections.Generic;
using UnityEngine;



public static class ListExtension
{
    static public TValue Pop<TValue>(this IList<TValue> list)
    {
        int index = list.Count - 1;

        TValue r = list[index];
        list.RemoveAt(index);
        return r;
    }

    static public TValue Random<TValue>(this IList<TValue> list)
    {
        int index = UnityEngine.Random.Range(0, list.Count);
        return list[index];
    }

    public static TValue First<TValue>(this List<TValue> @this)
    {
        var result = @this[0];
        return result;
    }
    public static TValue Last<TValue>(this List<TValue> @this)
    {
        var result = @this[@this.Count - 1];
        return result;
    }


    /// <summary>
    /// 获得数据方法
    /// </summary>
    public static TValue Get<TValue>(this IList<TValue> dataList, int index, TValue defaultData = default(TValue))
    {
        if (index < 0 || dataList == null || index >= dataList.Count)
        {
            return defaultData;
        }

        return dataList[index];
    }
}

