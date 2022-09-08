using System;
using System.Collections.Generic;

namespace OpenWorld
{
    public interface ICacheAble
    {
        bool cacheFlag { get; set; }
        void Reset2Cache();
    }

    public class ObjectPool<T> where T : class, ICacheAble, new()
    {
        Stack<T> m_Stack = new Stack<T>();
        int m_MaxCacheCount;

        public int cachedCount { get { return m_Stack.Count; } }
        public int maxCacheCount { get { return m_MaxCacheCount; } }

        public ObjectPool(int maxCacheCount = 1024)
        {
            m_MaxCacheCount = maxCacheCount;
        }

        public T Get()
        {
#if ROBOT_CLIENT
            // 机器人模式下，关闭缓存使用，节省内存
            return new T();
#endif

#if NOCACHE_MODE
            // 无缓冲模式下，关闭缓存使用，节省内存
            return new T();
#endif

            T element;
            if (m_Stack.Count == 0)
            {
                element = new T();
            }
            else
            {
                element = m_Stack.Pop();
            }

            element.cacheFlag = false;

            return element;
        }

        // 释放进入缓存
        public void Release(T t)
        {
#if ROBOT_CLIENT
            // 机器人模式下，关闭缓存使用，节省内存
            return;
#endif

#if NOCACHE_MODE
            // 无缓冲模式下，关闭缓存使用，节省内存
            return;
#endif

            if (t == null || t.cacheFlag)
            {
                return;
            }

            if (m_Stack.Count >= m_MaxCacheCount)
            {
                t.cacheFlag = true;
                return;
            }

            t.cacheFlag = true;
            t.Reset2Cache();
            m_Stack.Push(t);
        }
    }

    // 多态对象池
    public class PolyObjectPool<T> where T : class
    {
        Dictionary<Type, Stack<T>> m_Cache = new Dictionary<Type, Stack<T>>();
        int m_MaxCacheCount;

        public int cachedCount { get; private set; }
        public int maxCacheCount { get { return m_MaxCacheCount; } }

        public PolyObjectPool(int maxCacheCount = 1024)
        {
            m_MaxCacheCount = maxCacheCount;
        }

        public TP Get<TP>() where TP : class, T, new()
        {
#if ROBOT_CLIENT
            // 机器人模式下，关闭缓存使用，节省内存
            new TP();
#endif

#if NOCACHE_MODE
            // 无缓冲模式下，关闭缓存使用，节省内存
            new TP();
#endif

            Type type = typeof(TP);
            Stack<T> stack = null;

            if (m_Cache.TryGetValue(type, out stack))
            {
                if (stack.Count > 0)
                {
                    --cachedCount;

                    T element = stack.Pop();
                    (element as ICacheAble).cacheFlag = false;
                    return (element as TP);
                }
            }

            return new TP();
        }

        public T Get(Type type)
        {
#if ROBOT_CLIENT
            // 机器人模式下，关闭缓存使用，节省内存
            return (type.Assembly.CreateInstance(type.Name) as T);
#endif

#if NOCACHE_MODE
            // 无缓冲模式下，关闭缓存使用，节省内存
            return (type.Assembly.CreateInstance(type.Name) as T);
#endif

            Stack<T> stack = null;

            if (m_Cache.TryGetValue(type, out stack))
            {
                if (stack.Count > 0)
                {
                    --cachedCount;

                    T element = stack.Pop();
                    (element as ICacheAble).cacheFlag = false;
                    return (element);
                }
            }

            T t = (type.Assembly.CreateInstance(type.Name) as T);

            return t;
        }

        public void Release<TP>(TP tp) where TP : T
        {
#if ROBOT_CLIENT
            // 机器人模式下，关闭缓存使用，节省内存
            return;
#endif

#if NOCACHE_MODE
            // 无缓冲模式下，关闭缓存使用，节省内存
            return;
#endif

            if (tp == null)
            {
                return;
            }

            // 只缓存继承了ICacheAble接口的元素
            ICacheAble t = (tp as ICacheAble);
            if (t == null || t.cacheFlag)
            {
                return;
            }

            Type type = t.GetType();
            Stack<T> stack = null;

            if (!m_Cache.TryGetValue(type, out stack))
            {
                stack = new Stack<T>();
                m_Cache.Add(type, stack);
            }

            if (cachedCount >= m_MaxCacheCount)
            {
                t.cacheFlag = true;
                return;
            }

            ++cachedCount;

            t.cacheFlag = true;
            t.Reset2Cache();
            stack.Push(tp);
        }
    }
}
