using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Creates a small runtime grid of instances using AniInstancing's own factory.
/// Attach this to a spawn origin and assign an AniInstancing prototype as its template.
/// </summary>
[AddComponentMenu("Animation Instancing/Clone Spawner")]
[DisallowMultipleComponent]
public sealed class AnimationInstancingCloneSpawner : MonoBehaviour
{
    [SerializeField, Min(0)] private int cloneCount = 10;
    [SerializeField] private Transform footmanTemplate;
    [SerializeField, Min(0.01f)] private float spawnSpacing = 3.0f;

    // This is assigned from Awake while AnimationInstancingManager.CreateInstance is
    // cloning the prototype.  Keeping the copied component disabled prevents a clone
    // from becoming another spawner on its first Start call.
    [SerializeField, HideInInspector] private bool isRuntimeClone;

    private static bool isCreatingRuntimeClone;
    private readonly List<GameObject> generatedClones = new List<GameObject>();
    private bool hasSpawned;

    private void Awake()
    {
        if (!isCreatingRuntimeClone)
            return;

        isRuntimeClone = true;
        enabled = false;
    }

    private void Start()
    {
        if (!isRuntimeClone)
            SpawnClones();
    }

    /// <summary>Creates the configured number of runtime-only Footman instances.</summary>
    public void SpawnClones()
    {
        if (isRuntimeClone || hasSpawned)
            return;

        AnimationInstancingManager manager = AnimationInstancingManager.Instance;
        if (manager == null)
        {
            Debug.LogError("AnimationInstancingCloneSpawner requires an active AnimationInstancingManager.", this);
            return;
        }

        if (footmanTemplate == null)
        {
            Debug.LogError("AnimationInstancingCloneSpawner requires a Footman Template.", this);
            return;
        }

        URPAnimationInstancing sourceInstance = footmanTemplate.GetComponent<URPAnimationInstancing>();
        if (sourceInstance == null)
        {
            Debug.LogError("The Footman Template requires URPAnimationInstancing.", footmanTemplate);
            return;
        }

        ClearGeneratedClones();
        hasSpawned = true;

        int count = Mathf.Max(0, cloneCount);
        for (int i = 0; i < count; ++i)
        {
            GameObject clone = CreateInstancedClone(manager);
            if (clone == null)
                continue;

            clone.name = "FootmanClone_" + i;
            clone.transform.SetParent(transform, false);
            clone.transform.localPosition = GetGridPosition(i, count);
            clone.transform.localRotation = footmanTemplate.localRotation;
            clone.transform.localScale = footmanTemplate.localScale;
            generatedClones.Add(clone);
        }
    }

    /// <summary>Removes current generated children, then creates a fresh grid.</summary>
    public void RespawnClones()
    {
        if (isRuntimeClone)
            return;

        ClearGeneratedClones();
        hasSpawned = false;
        SpawnClones();
    }

    private GameObject CreateInstancedClone(AnimationInstancingManager manager)
    {
        isCreatingRuntimeClone = true;
        try
        {
            // CreateInstance preserves the prototype reference used by AnimationManager
            // to load the baked .bytes animation data. The clone's URPAnimationInstancing
            // Start method then performs the normal AddBoundingSphere/AddInstance flow.
            return manager.CreateInstance(footmanTemplate.gameObject);
        }
        finally
        {
            isCreatingRuntimeClone = false;
        }
    }

    private Vector3 GetGridPosition(int cloneIndex, int count)
    {
        int width = Mathf.CeilToInt(Mathf.Sqrt(count + 1));
        if ((width & 1) == 0)
            ++width;

        int center = width / 2;
        int sourceCell = center + center * width;
        int cell = cloneIndex >= sourceCell ? cloneIndex + 1 : cloneIndex;
        return new Vector3((cell % width - center) * spawnSpacing, 0.0f,
            (cell / width - center) * spawnSpacing);
    }

    private void ClearGeneratedClones()
    {
        // The template is separate from this component, so the list is the authoritative
        // record of clones owned by this particular spawn origin.
        for (int i = generatedClones.Count - 1; i >= 0; --i)
        {
            GameObject clone = generatedClones[i];
            if (clone == null)
                continue;

            clone.SetActive(false);
            clone.transform.SetParent(null, false);
            Destroy(clone);
        }
        generatedClones.Clear();

        // Support cleanup of clones made by the earlier, template-attached version of
        // this component without touching any unrelated direct children.
        for (int i = transform.childCount - 1; i >= 0; --i)
        {
            Transform child = transform.GetChild(i);
            AnimationInstancingCloneSpawner childSpawner = child.GetComponent<AnimationInstancingCloneSpawner>();
            if (childSpawner != null && childSpawner.isRuntimeClone)
            {
                child.gameObject.SetActive(false);
                child.SetParent(null, false);
                Destroy(child.gameObject);
            }
        }
    }
}
