/*
THIS FILE IS PART OF Animation Instancing PROJECT
AnimationInstancing.cs - The core part of the Animation Instancing library

©2017 Jin Xiaoyu. All Rights Reserved.
*/

using UnityEngine;

public class AnimationInstancingSingleton<T> : MonoBehaviour where T : AnimationInstancingSingleton<T>
{
    public static T Instance { get; protected set; }

    public static bool InstanceExists => Instance != null;

    public static bool TryGetInstance(out T result)
    {
        result = Instance;
        return result != null;
    }

    protected virtual void Awake()
    {
        if (Instance != null)
        {
            Debug.LogWarningFormat("Trying to create a second instance of {0}", typeof(T));
            Destroy(gameObject);
            return;
        }

        Instance = (T)this;
    }

    protected virtual void OnDestroy()
    {
        if (Instance == this)
        {
            Instance = null;
        }
    }

    public static bool IsDestroy()
    {
        return !InstanceExists;
    }
}

