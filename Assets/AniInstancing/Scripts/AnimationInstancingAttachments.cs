using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Creates GPU AniInstancing attachment instances for this character and binds
/// them through URPAnimationInstancing.Attach.
/// </summary>
[DisallowMultipleComponent]
public sealed class AnimationInstancingAttachments : MonoBehaviour
{
    [Serializable]
    public sealed class AttachmentEntry
    {
        [SerializeField] private string attachPointName = "Hand_R";
        [SerializeField] private GameObject attachObject;

        public string AttachPointName => attachPointName;
        public GameObject AttachObject => attachObject;
    }

    [SerializeField] private List<AttachmentEntry> attachments = new List<AttachmentEntry>();

    private readonly List<GameObject> spawnedAttachments = new List<GameObject>();
    private readonly List<Mesh> spawnedAttachmentMeshes = new List<Mesh>();

    private void Awake()
    {
        // Scene objects are templates. Their manager-created clones are the
        // only instances that should render during Play Mode.
        for (int i = 0; i < attachments.Count; ++i)
        {
            AttachmentEntry entry = attachments[i];
            if (entry != null && entry.AttachObject != null && entry.AttachObject.scene.IsValid())
                entry.AttachObject.SetActive(false);
        }
    }

    private IEnumerator Start()
    {
        URPAnimationInstancing characterInstance = GetComponent<URPAnimationInstancing>();
        if (characterInstance == null || AnimationInstancingManager.Instance == null)
        {
            Debug.LogError("AnimationInstancingAttachments requires URPAnimationInstancing and AnimationInstancingManager.", this);
            yield break;
        }

        while (!characterInstance.IsReady())
            yield return null;

        List<PendingAttachment> pendingAttachments = new List<PendingAttachment>();
        for (int i = 0; i < attachments.Count; ++i)
        {
            AttachmentEntry entry = attachments[i];
            if (entry == null || entry.AttachObject == null || string.IsNullOrEmpty(entry.AttachPointName))
                continue;

            URPAnimationInstancing templateInstance = entry.AttachObject.GetComponent<URPAnimationInstancing>();
            MeshRenderer renderer = entry.AttachObject.GetComponentInChildren<MeshRenderer>();
            if (templateInstance == null || templateInstance.prototype == null || renderer == null ||
                renderer.sharedMaterial == null || renderer.sharedMaterial.shader == null ||
                !renderer.sharedMaterial.shader.name.StartsWith("AnimationInstancing/"))
            {
                Debug.LogError("AnimationInstancingAttachments requires each Attach Object to be a configured MeshRenderer AniInstancing template.", entry.AttachObject);
                continue;
            }

            Vector3 authoredScale = entry.AttachObject.transform.localScale;
            GameObject attachmentObject = AnimationInstancingManager.Instance.CreateInstance(entry.AttachObject);
            URPAnimationInstancing attachmentInstance = attachmentObject.GetComponent<URPAnimationInstancing>();
            if (attachmentInstance == null)
            {
                Debug.LogError("AnimationInstancingAttachments could not create an AniInstancing attachment instance.", entry.AttachObject);
                Destroy(attachmentObject);
                continue;
            }

            CreateScaledRuntimeMeshes(attachmentObject, authoredScale);
            attachmentObject.transform.SetPositionAndRotation(transform.position, transform.rotation);
            attachmentObject.transform.localScale = Vector3.one;
            attachmentObject.SetActive(true);
            spawnedAttachments.Add(attachmentObject);
            pendingAttachments.Add(new PendingAttachment(entry.AttachPointName, attachmentInstance));
        }

        for (int i = 0; i < pendingAttachments.Count; ++i)
        {
            PendingAttachment pending = pendingAttachments[i];
            while (pending.instance.lodInfo == null)
                yield return null;

            characterInstance.Attach(pending.attachPointName, pending.instance);
        }
    }

    private void OnDestroy()
    {
        for (int i = 0; i < spawnedAttachments.Count; ++i)
        {
            if (spawnedAttachments[i] != null)
                Destroy(spawnedAttachments[i]);
        }

        for (int i = 0; i < spawnedAttachmentMeshes.Count; ++i)
        {
            if (spawnedAttachmentMeshes[i] != null)
                Destroy(spawnedAttachmentMeshes[i]);
        }
    }

    private void CreateScaledRuntimeMeshes(GameObject attachmentObject, Vector3 authoredScale)
    {
        MeshFilter[] meshFilters = attachmentObject.GetComponentsInChildren<MeshFilter>(true);
        for (int i = 0; i < meshFilters.Length; ++i)
        {
            Mesh sourceMesh = meshFilters[i].sharedMesh;
            if (sourceMesh == null)
                continue;

            Mesh runtimeMesh = Instantiate(sourceMesh);
            Vector3[] vertices = runtimeMesh.vertices;
            for (int j = 0; j < vertices.Length; ++j)
                vertices[j] = Vector3.Scale(vertices[j], authoredScale);

            runtimeMesh.vertices = vertices;
            runtimeMesh.RecalculateBounds();
            meshFilters[i].sharedMesh = runtimeMesh;
            spawnedAttachmentMeshes.Add(runtimeMesh);
        }
    }

    private readonly struct PendingAttachment
    {
        public readonly string attachPointName;
        public readonly URPAnimationInstancing instance;

        public PendingAttachment(string attachPointName, URPAnimationInstancing instance)
        {
            this.attachPointName = attachPointName;
            this.instance = instance;
        }
    }
}
