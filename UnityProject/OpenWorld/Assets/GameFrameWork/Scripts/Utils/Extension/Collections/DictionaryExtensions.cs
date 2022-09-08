using System.Collections;
using System.Collections.Generic;
using UnityEngine;



public static class DictionaryExtensions
{
    /// <summary>
    /// 安全的获取字典数据方法
    /// </summary>
    public static TValue Get<TKey, TValue>(this Dictionary<TKey, TValue> dictionary, TKey key)
    {
        if (dictionary == null || !dictionary.TryGetValue(key, out TValue value))
        {
            return default(TValue);
        }

        return value;
    }

    public static bool TryAdd<TKey, TValue>(this IDictionary<TKey, TValue> @this, TKey key, TValue value)
    {
        if (@this.ContainsKey(key))
            return false;
        else
        {
            @this.Add(key, value);
            return true;
        }
    }

    public static bool Remove<TKey, TValue>(this IDictionary<TKey, TValue> @this, TKey key, out TValue value)
    {
        value = default;
        if (@this.ContainsKey(key))
        {
            value = @this[key];
            @this.Remove(key);
            return true;
        }
        return false;
    }

    public static bool TryRemove<TKey, TValue>(this IDictionary<TKey, TValue> @this, TKey key, out TValue value)
    {
        if (@this.ContainsKey(key))
        {
            value = @this[key];
            @this.Remove(key);
            return true;
        }
        else
        {
            value = default;
            return false;
        }
    }
}
