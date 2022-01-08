using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class ListExtension
{
    static public T Pop<T>(this List<T> list)
    {
        int index = list.Count - 1;

        T r = list[index];
        list.RemoveAt(index);
        return r;
    }
}
