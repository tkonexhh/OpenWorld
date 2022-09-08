using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public static class CollectionExtensions
{
    public static void AddRange<T>(this ICollection<T> @this, IEnumerable<T> items)
    {
        foreach (T item in items)
            @this.Add(item);
    }
    public static void RemoveRange<T>(this ICollection<T> @this, IEnumerable<T> items)
    {
        foreach (T item in items)
            @this.Remove(item);
    }
    public static void Replace<T>(this ICollection<T> @this, IEnumerable<T> items)
    {
        @this.Clear();
        @this.AddRange(items);
    }
}

